Controller = require './base/controller'
Promise = require 'bluebird'
_ = require 'lodash'
AuthError = require '../classes/auth-error'
ServerError = require './base/server-error'
log = require 'node-logging'
{mongoose, User, Invitation, Session} = require '../schemas'
Mail = require '../classes/mail'
PersistentLogin = require '../classes/persistent-login'
config = require '../config'

# Promisification.
Promise.promisifyAll User
Promise.promisifyAll User.prototype
Promise.promisifyAll Invitation
Promise.promisifyAll Invitation.prototype
Promise.promisifyAll Session
Promise.promisifyAll Session.prototype

module.exports = class SessionController extends Controller

  authFactory: null

  ###*
   * An array of user id's that belong to users that have just been notified about the
   * migration when making a log-in attempt. Used to throttle the amount of emails sent.
   *
   * @type {Array}
  ###
  migrationNoticeTimeouts: null

  ###*
   * A mapping of user id's to Auth objects which keep track of password reset tokens.
   *
   * @type {Object}
  ###
  passwordTokenAuth: null

  ###*
   * Construct a session controller.
   *
   * @param {AuthFactory} @authFactory The AuthFactory instance to use for authentication.
  ###
  constructor: (@authFactory) ->
    @migrationNoticeTimeouts = []
    @passwordTokenAuth = {}

  ###*
   * Promise a user document based on the session.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A promise of a user mongo document.
  ###
  getUser: (req) ->
    throw new ServerError 404, "Not logged in." unless req.session?.userId?
    User.findByIdAsync req.session.userId
    .then (user) ->
      throw new ServerError 404, "User not found." unless user?
      return user

  ###*
   * Return true if a user is logged in, false otherwise.
   *
   * If the user does not have a session but did send a persistent-login-cookie, this
   * method will authenticate the user based on the cookie and rotate the cookie value.
   *
   * @return {Promise} A promise of a boolean.
  ###
  isLoggedIn: (req, res) ->

    # Start by trying to log the user in using their persistent login cookie.
    Promise.try =>

      # Unless they're already logged in.
      return if req.session?.userId?

      # Create the PersistentLogin instance.
      persistentLogin = new PersistentLogin req, res

      # Authenticate the cookie.
      persistentLogin.authenticate()

      # In case of a MISSMATCH, we are going to kill all sessions associated with the user.
      .catch AuthError.Predicate(AuthError.MISSMATCH), (err) =>

        # Remove sessions, log the event of an error.
        Session.removeAsync(userId:req.session.userId).catch (err) =>
          log.err "Failed to clear sessions: #{err}"

        # Then unset the session and warn the user.
        .then =>
          @_destroyUserSession req, res
          .throw new ServerError 401, "Account compromised. Please refer to your email."

      # In case of a successful authentication, log the user in.
      .then => @_createUserSession req, res, persistentLogin.getCookieData().user, true

    # Make sure the user exists.
    .then -> User.countAsync {_id:req.session.userId}
    .then (amount) -> amount is 1

    # In case of an AuthError, we're going to assume the user is not logged-in.
    .catch AuthError, (err) -> false


  ###*
   * Throw an exception if the request was not made by a logged in user. Return null otherwise.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {null}
  ###
  ensureLogin: (req) ->
    return null if req.session?.userId?
    throw new ServerError 401, "You are not logged in."

  ###*
   * Ensure that the request mongoose query filters by author.
   *
   * @param {http.IncomingMessage} req The Express request object.
   * @param {null} res Not used by this method.
   * @param {String} field ("author") The field to filter on.
   *
   * @return {null}
  ###
  ensureOwnership: (req, res, field = 'author') ->
    @ensureLogin req
    throw new Error "No query." unless req.quer?
    where = {}
    where[field] = req.session.userId
    req.quer.where where
    (if Array.isArray req.body then req.body else [req.body])
    .forEach (resource) -> resource?[field] = req.session.userId
    return null

  ###*
   * Attempt to log a user in by reading their credentials from the request body.
   *
   * In theory, this method should not need protection against bots by taking a number of
   * security measures. This happens to provide users with a more friendly way to log in.
   *
   * @return {Promise} A promise of a user document. Gets rejected with an appropriate
   *                   error message when the credentials are unsatisfactory.
  ###
  login: (req, res) ->

    # Figure out by what means to find the user.
    find = switch
      when 'username' of req.body then username: req.body.username.toLowerCase()
      when 'email' of req.body then email: req.body.email.toLowerCase()
      when 'login' of req.body
        login = req.body.login.toLowerCase()
        $or: [{email: login}, {username: login}]
      else false

    # If we have no means to find the user.
    throw new ServerError 400, "No username or email address given." unless find

    # Find the user
    User.findOneAsync find, '+password'

    # Ensure the user exists and fake hashing time if they don't.
    .then (user) ->
      return user if user
      Promise.delay Math.random()*25 + 55
      .throw new AuthError AuthError.MISSMATCH, "User not found."

    # Ensure the user has a password. This might not be the case if they were imported from 0.4.
    .then (user) =>
      return user if user.password

      # Send the user an email, unless we just did that.
      Promise.try =>
        return if user.id in @migrationNoticeTimeouts
        (new Mail)
        .to user
        .from "Webistor Team <hello@webistor.net>"
        .subject "Webistor was updated!"
        .template "account/migration-notice", user.toObject()
        .send()
        .then =>
          @migrationNoticeTimeouts.push user.id
          setTimeout (=>
            @migrationNoticeTimeouts.splice (@migrationNoticeTimeouts.indexOf user.id), 1
          ), 1000*60*5

      # Tell the user what happened and abort.
      .throw new ServerError 401, "
        You need to set a new password before being able to log in. We've just sent you an
        email with the details. Our apologies for the inconvenience."

    # Authenticate the user.
    .then (user) =>

      # The password must match the rules defined in the database schema.
      if req.body.password
        method = 'authenticatePassword'
        value = req.body.password
        passwordRegex = User.schema.tree.password.validate[0]
        throw new AuthError AuthError.MISSMATCH, "Password out of bounds." unless passwordRegex.test value

      # The token must be 32 characters long.
      else if req.body.token
        method = 'authenticateToken'
        value = req.body.token
        throw new AuthError AuthError.MISSMATCH, "Token out of bounds." unless value.length is 32

      # If we have no means to authenticate the user.
      else throw new ServerError 400, "No password or token given."

      # Create the authentication object (in the above scope) and perform the authentication.
      auth = @authFactory.get user
      auth[method] value
      .return auth

    # Store the users ID in their session and return the user object without password.
    .then (auth) =>
      auth.expire()
      @_createUserSession req, res, auth.user._id, req.body.persistent is true
      .return _.omit auth.user.toObject(), 'password'

    # Generate a user-friendly error message.
    .catch AuthError, (err) ->

      # Too many authentication attempts.
      if err.reason is AuthError.LOCKED
        throw new ServerError 401, "
          You have expended your authentication attempts. Please wait an hour and retry.
          This is a safety measure to protect your account from theft. If you were not the
          cause of this error message, please contact support."

      # Invalid credentials.
      if err.reason is AuthError.MISSMATCH
        throw new ServerError 401, "Invalid username/email or password/token."

      # Expired authentication token.
      if err.reason is AuthError.MISSING
        throw new ServerError 401, "
          The token you are using is not present on the server. In most cases this means
          that the token has expired. You can only use a login token for up to an hour
          after generating it."

      # Some other reason.
      throw new ServerError 500, "
        Something went wrong while attempting to log you in. Try again later. If this
        problem persists, please contact support."

  ###*
   * Create or modify the persistent log-in cookie.
   *
   * @method rotatePersistentLogin
  ###
  rotatePersistentLogin: (req, res) ->
    return null unless req.session?.userId? and req.session?.persistent is true
    new PersistentLogin(req, res).rotate().return(null)

  ###*
   * Check for the existence of a username.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A promise of a boolean indicating whether the user was found (true) or not (false).
  ###
  usernameExists: (req) ->
    throw new ServerError 400, "No username given." unless req.body.username
    Promise.resolve true if req.body.username in config.reservedUserNames
    User.findOneAsync {username:req.body.username.toLowerCase()}
    .then (user) -> return user?

  ###*
   * Register a new user.
   *
   * @throws {ServerError} If the current release stage is not in open beta or post release.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A promise of the created user object.
  ###
  register: (req) ->

    # Force some variables to this scope.
    user = null
    invitation = null

    # Intercept invitation token.
    token = req.body.invitation
    delete req.body.invitation

    # Find a matching invitation and validate it if necessary.
    Invitation.findOneAsync {email:req.body.email}, '+token'
    .then (result) ->
      invitation = result
      return if config.releaseStage in ['publicBeta', 'postRelease']
      throw new ServerError 403, "Invalid invitation token." unless result and token? and result.token is token

    # Create the user.
    .then -> user = new User req.body

    # Validate given data.
    .then ->
      throw new ServerError 400, "No password given." unless req.body.password?
      user.validateAsync()

    # Proceed by checking if the username is taken or not.
    .then -> User.findOneAsync {username:user.username}
    .then (result) ->
      throw new ServerError 409, "Username is taken." if result?

    # Proceed by checking if the user is already registered.
    .then -> User.findOneAsync {email:user.email}
    .then (user) -> throw new ServerError 409, "Email address is taken." if user?

    # Make friends if this user was invited.
    .then ->
      return unless invitation and invitation.author
      user.friends.push invitation.author

    # Proceed to register the user.
    .then -> user.saveAsync()

    # Proceed to update the potential user invitation.
    .then ->
      return unless invitation
      invitation.set
        user: user.id
        status: 'registered'
        token: null
      d = Promise.defer()
      invitation.save d.callback
      p1 = d.promise
      return p1 unless invitation.author
      p2 = User.updateAsync {_id:invitation.author}, {$push:friends:user.id}
      Promise.join p1, p2

    # Cast validation errors to something our crummy code can work with.
    .catch mongoose.Error.ValidationError, (err) ->
      throw new ServerError 400, err.toString()

    # Return the user.
    .then -> _.omit user.toObject(), 'password'

  ###*
   * Log a user out, removing them from their session.
   *
   * @return {String} Status message.
  ###
  logout: (req, res) ->
    @_destroyUserSession req, res
    .return "Successfully logged out."

  ###*
   * Send a password reset token to a given email address.
   *
   * The email address is obtained from the JSON body as "email".
   *
   * If the email address does not belong to any registered user, we send them an email
   * telling them they may want to sign up.
   *
   * The generated token is only usable for up to an hour after creation.
   *
   * @param {http.IncomingMessage} req The Express request object.
   * @param {String} req.body.email The email address to send a token to.
   *
   * @return {String} Status message.
  ###
  sendPasswordToken: (req) ->
    throw new ServerError 400, "No email address given." unless req.body.email

    # Detect if the email address is in our database.
    User.findOneAsync email:req.body.email
    .then (user) =>

      # If the user doesn't exist. Send them a mail to relief them of their confusion.
      unless user
        return (new Mail)
        .to req.body.email
        .from "Webistor Team <hello@webistor.net>"
        .subject "You have no account here"
        .template 'account/confused-newcomer', email:req.body.email
        .send()

      # Get or create the password token authentication object for the user.
      auth = @passwordTokenAuth[user.id] or= @authFactory.create user, => delete @passwordTokenAuth[user.id]

      # Generate a token with which they can reset their password.
      token = auth.generateToken()

      # Send them the token.
      (new Mail)
      .to user
      .from "Webistor Team <hello@webistor.net>"
      .subject "Your password reset ticket"
      .template "account/password-token", {user, token}
      .send()

    # Done.
    .return "Mail sent."

  ###*
   * Reset the password of the given user to the given password.
   *
   * @param {http.IncomingMessage} req The Express request object.
   * @param {String} req.body.id The user id.
   * @param {String} req.body.password The new password.
   * @param {String} req.body.token A valid password reset token.
   *
   * @return {String} Status message.
  ###
  resetPassword: (req, res) ->

    # Ensure the data is present.
    id = req.body.id or throw new ServerError 400, "User ID missing."
    token = req.body.token or throw new ServerError 400, "Token missing."
    password = req.body.password or throw new ServerError 400, "Password missing."

    # Ensure the token is present and usable.
    unless @passwordTokenAuth[id]? and not @passwordTokenAuth[id].isExpired()
      throw new ServerError 401, "The token you are using is not present on the server. In
        most cases this means that the token has expired. You can create a new token by
        submitting another password reset request."

    # Validate the token.
    (auth = @passwordTokenAuth[id]).authenticateToken token

    # Catch errors and translate them to something the user can work with.
    .catch AuthError.Predicate(AuthError.EXPIRED), (err) ->
      throw new ServerError 400, "The authentication token you are using has expired. This
        means too much time has passed between now and the request for the token. You can
        create a new token by submitting another password reset request."
    .catch AuthError.Predicate(AuthError.LOCKED), (err) ->
      throw new ServerError 400, "Too many attempts to log into your account have been
        made recently. To protect your account from theft it has been locked for an hour."
    .catch AuthError.Predicate(AuthError.MISSING), (err) ->
      throw new ServerError 400, "This token appears to have been used already. You can
        create a new token by submitting another password reset request."

    # If the token is valid, find the user.
    .then -> User.findByIdAsync id

    # Set the users password and save.
    .then (user) ->
      user.set 'password', password
      user.saveAsync()

    # Authenticate the user. They just provided a password that is now valid.
    .then =>
      @_createUserSession req, res, id, req.body.persistent is true

    # All done.
    .return "Password updated."

  _createUserSession: (req, res, id, persistent = false) ->
    req.session.userId = id
    return Promise.resolve() unless persistent
    new PersistentLogin(req, res).rotate()

  _destroyUserSession: (req, res) ->
    req.session.destroy()
    new PersistentLogin(req, res).destroy()
