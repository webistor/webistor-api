Promise = require 'bluebird'
bcrypt = require 'bcrypt'
randtoken = require 'rand-token'
_ = require 'lodash'
log = require 'node-logging'
AuthError = require './auth-error'
{Login, User} = require '../schemas'
config = require '../config'
Mail = require './mail'

Promise.promisifyAll Login
Promise.promisifyAll Login.prototype
Promise.promisifyAll User
Promise.promisifyAll User.prototype
Promise.promisifyAll bcrypt

module.exports = class PersistentLogin

  req: null
  res: null
  login: null

  ###*
   * The constructor
   *
   * @method construct
   *
   * @param {Express.Request} @req The request object.
   * @param {Express.Response} @res The response object.
   *
   * @throws {Error} If the request or response objects aren't given.
  ###
  constructor: (@req, @res) ->
    throw new Error "Request object not given" unless @req?
    throw new Error "Response object not given" unless @res?

  ###*
   * Generate a persistent login cookie.
   *
   * @method generate
   *
   * @throws {Error} If this method is called when the user is not authenticated.
   *
   * @return {Promise} A promise that resolves once the tokenpair is stored and the cookie is set.
  ###
  generate: ->

    # User must be logged in.
    throw new Error "User must be logged in to generate a persistent login cookie" unless @req.session.userId?

    # Create the Login document.
    login = new Login
      user: @req.session.userId
      accessToken: @newToken()
      seriesToken: @newToken()

    # Save it to the database and send it as a cookie.
    login.saveAsync()
    .then => @setCookieData login.user, login.accessToken, login.seriesToken

  ###*
   * Get rid of any traces of the current persistent cookie.
   *
   * @method destroy
   *
   * @return {Promise} A promise that resolves when the tokenpair is removed from database and cookie.
  ###
  destroy: ->
    @getLogin()
    .then (login) ->
      return unless login?
      login.remove()
    .then =>
      @res.clearCookie 'login'

  ###*
   * Generate a new access token for the current persistent cookie.
   *
   * This method needs to be called with every request the user makes to the server to
   * ensure that the cookie is always fresh.
   *
   * @method rotate
   *
   * @throws {Error} If this method is called when the user is not authenticated.
   *
   * @return {Promise} A promise which resolves once the tokenpair has been updated.
  ###
  rotate: ->

    # User must be logged in.
    throw new Error "User must be logged in to rotate the persistent login cookie" unless @req.session.userId?

    # If no cookie is given; generate one.
    return @generate() unless @exists()

    # Get the given cookie data.
    {user, accessToken, seriesToken} = @getCookieData()

    # Find the corresponding database entry.
    @getLogin(user, seriesToken).then (login) =>

      # If the no corresponding database entry was found; generate one.
      return @generate() unless login?

      # Generate a replacement access token.
      accessToken = @newToken()

      # Edit the access token.
      login.set 'accessToken', accessToken
      login.set 'lastAccess', new Date

      # Then save it to the database and the cookie.
      login.saveAsync()
      .then => @setCookieData user, accessToken, seriesToken

  ###*
   * Validate whether the cookie presented by a user is authentic.
   *
   * The promise returned by this method rejects with an AuthError in case of
   * authentication-failure. The AuthError will have a MISSING code if the tokenpair
   * wasn't found. It will have a MISSMATCH code if the tokenpair existed, but didn't
   * match up.
   *
   * In the latter case it can be assumed that cookie-theft occurred. An email will be
   * sent to the user and any other tokenpairs for the user will be removed. You should
   * catch this error and make sure to invalidate any sessions the user might have.
   *
   * @method authenticate
   *
   * @return {Promise} A promise which resolves when the cookie is authentic and rejects otherwise.
  ###
  authenticate: ->

    # Fail authentication if we have no cookie.
    return Promise.reject new AuthError AuthError.MISSING, "No cookie presented" unless @exists()

    # Get the given cookie data.
    {user, accessToken, seriesToken} = @getCookieData()

    # Find the corresponding database entry.
    @getLogin(user, seriesToken).then (login) =>

      # Fail authentication of no database entry exists.
      throw new AuthError AuthError.MISSING, "No corresponding entry found." unless login?

      # Pass validation if the tokens match.
      return true if accessToken is login.get 'accessToken'

      # At this point, an outdated token must have been presented. This indicates theft.

      # Find the victim.
      User.findOneAsync {_id:login.user}

      # Warn the victim and destroy their other tokenpairs.
      .then (victim) ->

        # If the victim doesn't exist; who cares that someone is trying to steal from them?
        throw new AuthError AuthError.MISSING, "The user does not exist." unless victim?

        # Log this event.
        log.inf "Possible authentication cookie leak detected for #{victim.email}."

        # Create a mail for the victim to help them recover.
        mail = new Mail
        mail.to victim.get 'email'
        mail.from "Webistor Team <hello@webistor.net>"
        mail.subject "Potential account compromise"
        mail.template "account/cookie-compromised", user:victim

        # Send the mail. Log the event of a failure.
        mailPromise = mail.send().catch (err) ->
          log.err "Could not send cookie-compromised mail to #{victim.email}: #{err}"

        # Remove all other logins. Log the event of a failure.
        removalPromise = Login.removeAsync(_id:victim.id).catch (err) ->
          log.err "Failed to clear tokenpairs for #{victim.email}: #{err}"

        # Wait for both promises to settle.
        Promise.join mailPromise, removalPromise

      # Throw a MISSMATCH auth exception.
      .throw new AuthError AuthError.MISSMATCH, "Presented token did not match actual token in the series."

  ###*
   * Returns true if the persistent login cookie is present on the request object.
   *
   * @method exists
   *
   * @return {Boolean}
  ###
  exists: -> !! @req.cookies.login

  ###*
   * Get the persistent login cookie parsed data.
   *
   * @method getCookieData
   *
   * @return {Object} An object with the keys: `user`, `accessToken` and `seriesToken`.
  ###
  getCookieData: ->
    [user, accessToken, seriesToken] = @req.cookies.login.split '.'
    return {user, accessToken, seriesToken}

  ###*
   * Set the persistent cookie.
   *
   * @method setCookieData
   *
   * @param {String} user The user ID to store in the cookie.
   * @param {String} accessToken The access token to store in the cookie.
   * @param {String} seriesToken The series token to store in the cookie.
  ###
  setCookieData: (user, accessToken, seriesToken) ->
    @res.cookie 'login', "#{user}.#{accessToken}.#{seriesToken}",
      expires: new Date Date.now() + config.authentication.persistentCookieLifetime
      httpOnly: true

  ###*
   * Generate a token.
   *
   * @method newToken
   *
   * @return {String} A set of random characters.
  ###
  newToken: ->
    randtoken.generate 16

  ###*
   * Find the tokenpair matching the given user and series.
   *
   * @method getLogin
   *
   * @param {String} user The user ID to match against.
   * @param {String} seriesToken The series token to match against.
   *
   * @return {Promise} A promise that resolves with either a Login object or null,
   *                   depending on whether a match was found.
  ###
  getLogin: (user, seriesToken) ->
    return Promise.resolve null unless user? and seriesToken?
    return Promise.resolve @login if @login?
    Login.findOneAsync {user, seriesToken}
    .then (login) => @login = login
