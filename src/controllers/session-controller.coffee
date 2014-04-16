Controller = require './base/controller'
Promise = require 'bluebird'
_ = require 'lodash'
AuthError = require '../classes/auth-error'
log = require 'node-logging'
{User} = require '../schemas'

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
    return Promise.reject "Not logged in." unless @isLoggedIn req
    Promise.promisify(User.findById, User) req.session.userId

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
    throw new Error "You are not logged in."

  ###*
   * Ensure that the request mongoose query filters by author.
   *
   * @param {http.IncomingMessage} req The Express request object.
   * @param {http.ServerResponse} res The Express response object.
   * @param {String} field ["author"] The field to filter on.
   *
   * @return {null}
  ###
  ensureOwnership: (req, res, field = 'author') ->
    @ensureLogin req
    throw new Error "No query." unless req.quer?
    where = {}
    where[field] = req.session.userId
    req.quer.where where
    req.body?[field] = req.session.userId
    return null

  ###*
   * Attempt to log a user in by reading their credentials from the request body.
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
    else false

    # If we have no means to find the user.
    return Promise.reject "No username or email address given." unless find

    # Figure out by which means to authenticate the user.
    authType = if 'token' of req.body
      {method: 'authenticateToken', value: req.body.token}
    else if 'password' of req.body
      {method: 'authenticatePassword', value: req.body.password}
    else false

    # If we have no means to authenticate the user.
    return Promise.reject "No password or token given." unless authType

    # We want the auth object out here.
    auth = null

    # Find the user in the database and force-include the password.
    Promise.promisify(User.findOne, User) find, '+password'

    # Authenticate the user.
    .then (user) =>
      throw new AuthError "User not found.", AuthError.MISSMATCH unless user
      auth = @authFactory.get(user)
      return auth[authType.method] authType.value

    # Store the users ID in their session and return the user object without password.
    .then ->
      req.session.userId = auth.user._id
      return _.omit auth.user, 'password'

    # Generate a user-friendly error message.
    .catch AuthError, (err) ->

      # Too many authentication attempts.
      if err.reason is AuthError.LOCKED
        throw new Error "
          You have expended your authentication attempts. Please wait an hour and retry.
          This is a safety measure to protect your account from theft. If you were not the
          cause of this error message, please contact support."

      # Missing credentials.
      if err.reason is AuthError.MISSMATCH
        throw new Error "
          Invalid username/email or password/token." + (if auth?.attempts > 2 then " "+"
          Please note that your account will be locked out after too many attempts and you
          will not be able to log in or use the password forgotten function for an hour." else '')

      # Expired authentication token.
      if err.reason is AuthError.MISSING and authType.method is 'authenticateToken'
        throw new Error "
          The token you are using is not present on the server. In most cases this means
          that the token has expired. You can only use a login token for up to an hour
          after generating it."

      # Some other reason.
      throw new Error "
        Something went wrong while attempting to log you in. Try again later. If this
        problem persists, please contact support."

  ###*
   * Log a user out, removing them from their session.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {String} Status message.
  ###
  logout: (req) ->
    throw new Error "User wasn't logged in." unless @isLoggedIn req
    delete req.session.userId
    return "Successfully logged out."
