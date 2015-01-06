Promise = require 'bluebird'
{Tag} = require '../schemas'

Promise.promisifyAll Tag
Promise.promisifyAll Tag.prototype

_wait= ->
  new Promise (resolve) -> process.nextTick resolve

module.exports = countTagsTimesUsed = ->
  _wait()
  .then -> Tag.findAsync()
  .then (tags) ->
    Promise.reduce tags, ((memo, tag) ->
      tag.countTimesUsedAsync()
      .then (timesUsed) ->
        return tag.removeAsync() if timesUsed is 0
        tag.set 'num', timesUsed
        tag.saveAsync()
      .then _wait
      .return memo-1
    ), tags.length
