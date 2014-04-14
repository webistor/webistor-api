{User} = require '../schemas'

module.exports = class AuthFactory

  # Class properties.
  byUserId: null
  byIP: null
  Auth: require './auth'

  ###*
   * Instantiate the factory.
  ###
  constructor: (@Auth=@Auth) ->
    @byUserId = {}
    @byIP = {}

  ###*
   * Create and cache, or get from cache, an Auth instance.
   *
   * The instance is automatically removed from cache when it expires, subsequent calls
   * to this method will therefore retrieve or create, based on what's appropriate.
   *
   * @param {User} user A user model. This is passed to the Auth object, but also used as a cache key.
   * @param {String} ip The IP address making the request.
   *
   * @return {Auth} An instance of Auth.
  ###
  get: (user, ip) ->

    # Ensure we have the right input.
    throw new Error "First argument must be an instance of User." unless user instanceof User

    # Either get, or create the Auth instance.
    auth = @byUserId[user._id] or= do =>
      new @Auth user, =>
        @totalAttempts -= @byUserId[user._id].attempts
        delete @byUserId[user._id]
      .on 'attempt', => @totalAttempts++

    #
