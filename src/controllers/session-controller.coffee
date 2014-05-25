Controller = require './base/controller'
Promise = require 'bluebird'
_ = require 'lodash'
AuthError = require '../classes/auth-error'
ServerError = require './base/server-error'
log = require 'node-logging'
User = Promise.promisifyAll (require '../schemas').User
config = require '../config'

module.exports = class SessionController extends Controller

  authFactory: null

  ###*
   * Construct a session controller.
   *
   * @param {AuthFactory} @authFactory The AuthFactory instance to use for authentication.
  ###
  constructor: (@authFactory) ->

  ###*
   * Promise a user document based on the session.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A promise of a user mongo document.
  ###
  getUser: (req) ->
    throw new ServerError 404, "Not logged in." unless @isLoggedIn req
    User.findByIdAsync req.session.userId

  ###*
   * Return true if a user is logged in, false otherwise.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Boolean}
  ###
  isLoggedIn: (req) ->
    req.session.userId?

  ###*
   * Throw an exception if the request was not made by a logged in user. Return null otherwise.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {null}
  ###
  ensureLogin: (req) ->
    return null if @isLoggedIn req
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
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A promise of a user document. Gets rejected with an appropriate
   *                   error message when the credentials are unsatisfactory.
  ###
  login: (req) ->

    # Figure out by what means to find the user.
    find = if 'username' of req.body
      {username: req.body.username.toLowerCase()}
    else if 'email' of req.body
      {email: req.body.email.toLowerCase()}
    else if 'login' of req.body
      login = req.body.login.toLowerCase()
      {$or: [{email: login}, {username: login}]}
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

    # Authenticate the user.
    .then (user) =>

      # The password must match the rules defined in the database schema.
      if req.body.password
        method = 'authenticatePassword'
        value = req.body.password
        passwordRegex = User.schema.tree.password.match
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
    .then (auth) ->
      req.session.userId = auth.user._id
      return _.omit auth.user.toObject(), 'password'

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
        throw new ServerError 401, "
          Invalid username/email or password/token. Please note that your account will be
          locked out after too many attempts and you will not be able to log in or use the
          password forgotten function for an hour."

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
   * Check for the existance of a username.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A promise of a boolean indicating whether the user was found (true) or not (false).
  ###
  usernameExists: (req) ->
    throw new ServerError 400, "No username given." unless req.body.username
    Promise.resolve true if req.body.username in config.reservedUserNames
    User.findOneAsync {username:req.body.username}
    .then (user) -> user?

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

    # Can only autonomously register during open beta or after release.
    unless config.releaseStage in ['openBeta', 'postRelease']
      throw new ServerError 403, "User registration is not allowed at this stage."

    # Create the user object locally.
    user = Promise.promisifyAll new User req.body

    # Validate given data.
    user.validateAsync()

    # Proceed by checking if the username is taken or not.
    .then => @usernameExists req
    .then (exists) -> throw new ServerError 409, "Username is taken." if exists

    # Proceed by checking if the user is already registered.
    .then -> User.findOneAsync {email:user.email}
    .then (user) -> throw new ServerError 409, "Email address is taken." if user?

    # Proceed to register the user.
    .then -> user.saveAsync()
    .spread (user) -> _.omit user.toObject(), 'password'

  ###*
   * Log a user out, removing them from their session.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {String} Status message.
  ###
  logout: (req) ->
    throw new ServerError 404, "User wasn't logged in." unless @isLoggedIn req
    delete req.session.userId
    return "Successfully logged out."
