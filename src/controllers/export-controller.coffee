Controller = require './base/controller'
EntryController = require './entry-controller'
Promise = require 'bluebird'
ServerError = require './base/server-error'
config = require '../config'
log = require 'node-logging'

module.exports = class ExportController extends Controller

  ###*
   * Export the entries in 'bookmark' format.
   *
   * @return {Promise} A Promise which resolves once the response is generated.
  ###
  bookmarks: (req, res) ->

    return EntryController.search()
