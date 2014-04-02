{User} = require '/schemas'

module.exports = class AuthFactory
  
  # Class properties.
  instances: null
  Auth: require './auth'
  
  ###*
   * Instantiate the factory.
  ###
  constructor: (@Auth=@Auth) ->
    @instances = {}
  
  ###*
   * Create and cache, or get from cache, an Auth instance.
   * 
   * The instance is automatically removed from cache when it expires, subsequent calls
   * to this method will therefore retrieve or create, based on what's appropriate.
   *
   * @param {User} user A user model. This is passed to the Auth object, but also used as a cache key.
   *
   * @return {Auth} An instance of Auth.
  ###
  get: (user) ->
    throw new Error "First argument must be an instance of User." unless user instanceof User
    @instances[user._id] or= @create user, => delete @instances[user._id]
  
  ###*
   * Instantiate an Auth.
   *
   * @param {User} user An instance of User to pass to the Auth constructor.
   * @param {Function} onExpire An optional callback for when the Auth expires.
   *
   * @return {Auth} A new Auth instance.
  ###
  create: (user, onExpire) ->
    throw new Error "First argument must be an instance of User." unless user instanceof User
    new @Auth user, onExpire
