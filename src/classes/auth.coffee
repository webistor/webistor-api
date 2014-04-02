Promise = require 'bluebird'
bcrypt = Promise.promisifyAll require 'bcrypt'
randtoken = require 'rand-token'
_ = require 'lodash'
AuthError = require './auth-error'

module.exports = class Auth
  
  # The default is 10 at this moment in time, but this should be increased on faster servers.
  @SALT_WORK_FACTOR: 10
  
  # Any multi-step authentication attempts have one hour to complete before expiring.
  @EXPIRATION_DURATION: 1000*60*60
  
  # Any multi-step authentication attempts should complete in under the following amount of steps.
  @MAX_ALLOWED_ATTEMPTS: 10
  
  # Container for middleware.
  @Middleware: {
    
    ###*
     * Middleware for Mongoose which hashes a password.
     *
     * @param {Object} options Middleware options.
     *                         * `key` ("password"): The field in the calling document to hash.
     *                         * `force` (false): Whether to hash even if the password hasn't changed.
     *
     * @return {Function} The middleware.
    ###
    hashPassword: (options = {}) ->
      
      # Complete options.
      _.defaults options,
        force: false
      
      # Return the middleware.
      return (next) ->
        return do next unless options.force or this.isModified 'password'
        bcrypt.genSalt Auth.SALT_WORK_FACTOR
        .then (salt) => bcrypt.hash @password, salt
        .then (hash) => @password = hash
        .catch (err) -> next err
        .done -> do next
        
  }
  
  # Class properties.
  expireTimeout: -1
  expired: false
  expireCallbacks: null
  attempts: 0
  singleUseToken: null
  
  ###*
   * Construct an authentication object for the given user.
   *
   * @param {db.User} user A User model.
   * @param {Function} onExpire An optional callback for when the authentication class expires.
  ###
  constructor: (@user, onExpire) ->
    @expireCallbacks = []
    @onExpire onExpire if onExpire?
    @refresh()
  
  ###*
   * Attempt to authenticate the user by comparing the given password to his own password.
   *
   * @param {String} password The password to compare to the users.
   *
   * @return {Promise} A promise which will only resolve if the user is authenticated.
  ###
  authenticatePassword: (password) ->
    @attempt()
    return Promise.reject new AuthError "Authentication expired.", AuthError.EXPIRED if @isExpired()
    return Promise.reject new AuthError "Authentication locked.", AuthError.LOCKED if @isLocked()
    bcrypt.compare password, @user.password
    .then (ok) -> throw new AuthError "Non-matching passwords.", AuthError.MISSMATCH unless ok
  
  ###*
   * Attempt to authenticate the user from the given authentication token.
   *
   * @param {String} token The authentication token.
   *
   * @return {Promise} A promise which will only resolve if the user is authenticated.
  ###
  authenticateToken: (token) ->
    @attempt()
    return Promise.reject new AuthError "Authentication expired.", AuthError.EXPIRED if @isExpired()
    return Promise.reject new AuthError "Authentication locked.", AuthError.LOCKED if @isLocked()
    bcrypt.compare token, @token
    .then (ok) -> throw new AuthError "Non-matching tokens.", AuthError.MISSMATCH unless ok
  
  ###*
   * Generate a single-use authentication token (removing the previous).
   *
   * NOTE:
   *   Because the previous token is removed before the refresh, this method might be used
   *   to extend the life of this instance by MAX_ALLOWED_ATTEMPTS*EXPRATION_DURATION.
   *   This shouldn't pose a problem to security, because the life since the last
   *   generated token will still always be <= EXPRATION_DURATION.
   *   One problem that might arise is one where bad guys attempt to flood our server
   *   memory by keeping alive a high amount of instances, but that's pretty far-fetched.
   *
   * @return {Promise} A promise of the token to compare against later.
  ###
  generateToken: ->
    @singleUseToken = null
    @attempt()
    return Promise.reject new AuthError "Authentication expired.", AuthError.EXPIRED if @isExpired()
    return Promise.reject new AuthError "Authentication locked.", AuthError.LOCKED if @isLocked()
    token = randtoken.generate 32
    bcrypt.genSalt Auth.SALT_WORK_FACTOR
    .then (salt) -> bcrypt.hash token, salt
    .then (hash) => @singleUseToken = hash
    .return token
  
  ###*
   * Determine if this authentication session is locked for any reason.
   *
   * @return {Boolean}
  ###
  isLocked: ->
    @attempts > Auth.MAX_ALLOWED_ATTEMPTS
  
  ###*
   * Increment the total amount of authentication attempts and refresh the expiry date.
   *
   * @chainable
  ###
  attempt: ->
    @attempts++
    @refresh()
  
  ###*
   * Refresh the expiry date.
   *
   * This is ignored when the instance is locked, expired, or waiting for a token.
   *
   * @chainable
  ###
  refresh: ->
    return this if @isLocked() or @isExpired() or @singleUseToken?
    clearTimeout @expireTimeout if @expireTimeout > -1
    @expireTimeout = setTimeout @expire.bind(@), Auth.EXPIRATION_DURATION
    return this
  
  ###*
   * Add a callback for the event of an expiration.
   * 
   * The callback is executed during the next tick if the instance has already expired.
   *
   * @param {Function} callback The function to call.
   *
   * @chainable
  ###
  onExpire: (callback) ->
    
    if @isExpired()
      process.nextTick callback
      return this
    
    @expireCallbacks.push callback
    return this
  
  ###*
   * Expire this instance, making it immutable and unusable and calling the callbacks.
   * 
   * @return null
  ###
  expire: ->
    Object.freeze this
    @expired = true
    callback() for callback in @expireCallbacks when callback instanceof Function
    return null
  
  ###*
   * Return true if this authentication instance has expired.
   *
   * @return {Boolean}
  ###
  isExpired: -> @expired
