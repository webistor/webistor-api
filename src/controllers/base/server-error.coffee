module.exports = class ServerError extends Error

  statusCode: 500

  constructor: (statusCode..., @message) ->
    @name = "AuthError"
    @statusCode = statusCode[0] if statusCode.length > 0
    Error.captureStackTrace this, AuthError
