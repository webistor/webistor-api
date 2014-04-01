Promise = require 'bluebird'
bcrypt = Promise.promisifyAll require 'bcrypt'
_ = require 'lodash'

module.exports = class Auth
  
  @SALT_WORK_FACTOR: 10
  
  @Middleware: {
    
    ###*
     * Middleware for Mongoose which hashes a password.
     *
     * @param {mongoose.Schema} model The 
     *
     * @param {Object} options Middleware options.
     *                         * `key` ("password"): The field to use in the request body.
     *                         * `force` (false): Whether to hash even if the password hasn't changed.
     *
     * @return {Function} The middleware.
    ###
    hashPassword: (options = {}) ->
      
      # Complete options.
      _.defaults options,
        key: 'password'
        force: false
      
      # Return the middleware.
      return (next) ->
        return do next unless options.force or not this.isModified options.key
        bcrypt.genSalt Auth.SALT_WORK_FACTOR
        .then (salt) => bcrypt.hash this[options.key], salt
        .then (hash) => this[options.key] = hash
        .catch (err) -> next err
        .done -> do next
        
  }
  
  ###*
   * Determine whether two given passwords are matching.
   *
   * @param {String} candidate The first password.
   * @param {String} password The second password.
   *
   * @return {Promise} A promise of a boolean which is true when the passwords are matching.
  ###
  @matchPassword: (candidate, password) ->
    bcrypt.compare candidate, password
    
