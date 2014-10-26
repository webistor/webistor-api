module.exports = class AuthError extends Error

  @Predicate: (reason) -> (err) -> err instanceof AuthError and err.reason is reason

  @UNKNOWN: 0
  @EXPIRED: 1
  @MISSMATCH: 2
  @LOCKED: 3
  @MISSING: 4

  reason: 0

  constructor: (reason..., @message) ->
    @name = "AuthError"
    @reason = reason[0] if reason.length > 0
    Error.captureStackTrace this, AuthError
