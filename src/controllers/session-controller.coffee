Controller = require './base/controller'
Promise = require 'bluebird'
_ = require 'lodash'
AuthError = require '../classes/auth-error'

module.exports = class SessionController extends Controller

  authFactory: null
  User: null

  ###*
   * Construct a session controller.
   *
   * @param {AuthFactory} @authFactory The AuthFactory instance to use for authentication.
   * @param {Function} @User The model class to use for interacting with storage.
  ###
  constructor: (@authFactory, @User) ->

  ###*
   * Promise a user document based on the session.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A promise of a user mongo document.
  ###
  getUser: (req) ->
    return Promise.reject "Not logged in." unless @isLoggedIn req
    Promise.promisisfy(@User.findById, @User) req.session.userId

  ###*
   * Return true if a user is logged in.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Boolean}
  ###
  isLoggedIn: (req) ->
    req.session.userId?

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
      _.pick req.body, 'username'
    else if 'email' of req.body
      _.pick req.body, 'email'
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

    # Find the user in the database.
    Promise.promisisfy(@User.findOne, @User) find

    # Authenticate the user.
    .then (user) =>
      throw new AuthError "User not found.", AuthError.MISSMATCH unless user
      auth = @authFactory.get(user)
      auth[authType.method] authType.value

    # Store the users ID in their session.
    .then ->
      req.session.userId = user._id

    # Return the user object without password.
    .return _.omit auth.user, 'password'

    # Generate a user-friendly error message.
    .catch (AuthError, err) ->

      # Too many authentication attempts.
      if err.reason is AuthError.LOCKED
        throw new Error "
          You have expended your authentication attempts. Please wait an hour and retry.
          This is a safety measure to protect your account from theft. If you were not the
          cause of this error message, please contact an administrator."

      # Missing credentials.
      if err.reason is AuthError.MISSMATCH
        throw new Error "
          Invalid username/email or password/token." + if auth.attempts > 2 then "
          Please note that your account will be locked out after too many attempts and you
          will not be able to log in or use the password forgotten function for an hour."

      # Expired authentication token.
      if err.reason is AuthError.MISSING and authType.method is 'authenticateToken'
        throw new Error "
          The token you are using is not present on the server. In most cases this means
          that the token has expired. You can only use a login token for up to an hour
          after generating it."

      # Some other reason.
      throw new Error "
        Something went wrong while attempting to log you in. Try again later. If this
        problem persists, please contact an administrator."
