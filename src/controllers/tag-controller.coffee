Controller = require './base/controller'
Promise = require 'bluebird'
config = require '../config'
ServerError = require './base/server-error'
log = require 'node-logging'
Tag = Promise.promisifyAll (require '../schemas').Tag

module.exports = class TagController extends Controller

  ###*
   * Patch up the Tag collection with a partial array of tag-objects.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A promise of an Array of the processed Tag models.
  ###
  patch: (req) ->

    # Ensure we have an array of stuff.
    throw new ServerError 400, "No data received." unless req.body instanceof Array

    # Normalize input by either creating new models or finding the matching models.
    Promise.map req.body, (ltag) ->

      # Setting the author explicitly prevents users from pretending to be someone else.
      ltag.author = req.session.userId

      # Return a new model if the tag has no _id.
      return Promise.promisifyAll new Tag ltag unless ltag._id

      # Find the tag which needs to be updated. Filtering by author prevents users from
      # updating tags they do not themselves own.
      Tag.findOneAsync _id:ltag._id, author:req.session.userId
      .then (stag) ->
        throw new ServerError 400, "Not all tags found in the database." unless stag?
        Promise.promisifyAll stag.set ltag

    # Validate all the tags.
    .then (tags) ->
      Promise.map tags, (tag) -> tag.validateAsync()
      .return tags

    # Save all the tags.
    .then (tags) ->
      Promise.map tags, (tag) -> tag.saveAsync().get 0
