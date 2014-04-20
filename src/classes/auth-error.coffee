module.exports = class AuthError extends Error

  @UNKNOWN: 0
  @EXPIRED: 1
  @MISSMATCH: 2
  @LOCKED: 3
  @MISSING: 4

  reason: 0

  constructor: (@message, @reason = @reason) ->
    @name = "AuthError"
    Error.captureStackTrace this, AuthError
