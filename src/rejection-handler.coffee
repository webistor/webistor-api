Promise = require 'bluebird'

# Collection of rejected promises and their reasons.
rejections = []

# Push possibly unhandled rejections into the collection when they occur.
Promise.onPossiblyUnhandledRejection (ex, promise) -> rejections.push {ex, promise}

# Remove unhandled rejections from the collection when they are handled.
Promise.onUnhandledRejectionHandled (promise) ->
  break for rejection, index in rejections when rejection.promise is promise
  rejections.splice index, 1

###*
 * Logs all currently unhandled rejections to stderr.
 *
 * @return {Promise} A promise which will be resolved if no unhandled rejections were
 *                   logged or rejected otherwise.
###
module.exports = handleRejections = ->
  return Promise.resolve() unless rejections.length > 0
  log.err rejection.ex for rejection in rejections
  rejections = []
  return Promise.throw new Error "#{rejections.length} Unhandled rejections have been logged."
