Promise = require 'bluebird'
_ = require 'lodash'
ServerError = require './server-error'

module.exports = class Controller

  ###*
   * Get middleware for an action.
   *
   * The action is expected to return the data to send to the client. If no data is
   * provided, the next middleware will be called. If the return value is a Promise, its
   * promised return value will be waited for instead.
   *
   * @param {String} actionName The name of the action (method name of the implementing controller).
   * @param {Object} args... Further optional arguments to pass to the action at calltime.
   *
   * @return {Function} The middleware for Express.
  ###
  getMiddleware: (actionName, args...) -> (req, res, next) =>

    # Get the action. Respond with an error if it does not exist.
    action = @getAction actionName
    return @sendError req, res, new ServerError 501, "Controller method not implemented." unless action

    # Try to execute the action. If an error occurs, respond with the error.
    try
      ret = action req, res, args...
    catch err
      return @sendError req, res, err

    # Either call the next middlware, or respond with the return value, depending on whether it's given.
    return next() unless ret?
    return @sendData req, res, ret unless Promise.is ret

    # At this point we can treat the return value as a promise, and handle is that way.
    ret
    .then (data) => if data? then @sendData req, res, data else do next
    .catch (err) => @sendError req, res, err

  ###*
   * Get synchrounous middleware for an action.
   *
   * @deprecated getMiddleware now handles this automatically.
   *
   * The action is expected to return the data to send to the client. If no data is
   * provided, the next middleware will be called.
   *
   * @param {String} actionName The name of the action (method name of the implementing controller).
   * @param {Object} args... Further optional arguments to pass to the action at calltime.
   *
   * @return {Function} The middleware for Express.
  ###
  getSyncMiddleware: (actionName, args...) ->
    throw new Error "Deprecated: SessionController.prototype.getSyncMiddleware"

  ###*
   * Find the implementing controller method of the given name, and bind it to this.
   *
   * @param {String} name The name of the method.
   *
   * @return {Function|false} The method, or false of non found.
  ###
  getAction: (name) ->
    return false unless @[name] instanceof Function
    @[name].bind this

  ###*
   * Respond to a request with the given error.
   *
   * This normalizes the error for a consistent API.
   *
   * @param {http.IncomingMessage} req The Express request object.
   * @param {http.ServerResponse} req The Express response object.
   * @param {String|Error} err The error message or instance.
   *
   * @chainable
  ###
  sendError: (req, res, err) ->
    statusCode = err.statusCode or 500
    res.send statusCode, error:(if err instanceof Error then err.message else err)

  ###*
   * Respond to a request with the given data.
   *
   * This normalizes the data for a consistent API.
   *
   * @param {http.IncomingMessage} req The Express request object.
   * @param {http.ServerResponse} req The Express response object.
   * @param {Object} data Any object. Scalar values are sent as `{value: <scalar>}`.
   *
   * @chainable
  ###
  sendData: (req, res, data) ->
    res.send (if _.isObject data then data else value:data)
