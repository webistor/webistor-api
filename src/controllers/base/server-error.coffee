module.exports = class ServerError extends Error

  @Predicate: (statusCode) -> (err) -> err instanceof ServerError and err.statusCode is statusCode

  statusCode: 500

  constructor: (statusCode..., @message) ->
    @name = "ServerError"
    @statusCode = statusCode[0] if statusCode.length > 0
    Error.captureStackTrace this, ServerError
