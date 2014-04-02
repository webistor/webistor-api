Promise = require 'bluebird'
_ = require 'lodash'

module.exports = class Controller

  ###*
   * Get middleware for an action.
   *
   * The action is expected to return a promise of the data to send to the client. If no
   * data is provided, the next middleware will be called.
   *
   * @param {String} actionName The name of the action (method name of the implementing controller).
   * @param {Object} args... Further optional arguments to pass to the action at calltime.
   *
   * @return {Function} The middleware for Express.
  ###
  getMiddleware: (actionName, args...) -> (req, res, next) =>
    action = @getAction actionName
    return res.send 501, error: new Error "Controller method not implemented." unless action
    action req, res, args...
    .then (data) -> if data? then res.send (if _.isObject data then data else value:data) else do next
    .catch (err) -> res.send err.statusCode or 500, error: (if err instanceof Error then err.message else err)

  ###*
   * Get synchrounous middleware for an action.
   *
   * The action is expected to return the data to send to the client. If no data is
   * provided, the next middleware will be called.
   *
   * @param {String} actionName The name of the action (method name of the implementing controller).
   * @param {Object} args... Further optional arguments to pass to the action at calltime.
   *
   * @return {Function} The middleware for Express.
  ###
  getSyncMiddleware: (actionName, args...) -> (req, res, next) =>
    action = @getAction actionName
    return res.send 501, error: new Error "Controller method not implemented." unless action
    try
      data = action req, res, args...
      if data? then res.send (if _.isObject data then data else value:data) else do next
    catch err then res.send err.statusCode or 500, error: (if err instanceof Error then err.message else err)

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
