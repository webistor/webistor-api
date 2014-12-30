Controller = require './base/controller'
Promise = require 'bluebird'
ServerError = require './base/server-error'
config = require '../config'
log = require 'node-logging'
Mail = require '../classes/mail'

module.exports = class FeedbackController extends Controller

  ###*
   * Send user feedback to hello@webistor.net.
   *
   * @param {http.IncomingMessage} req The Express request object. Required fields:
   *                                   `req.body.subject`: The feedback subject line.
   *
   * @return {Promise} A Promise which resolves once the response is generated.
  ###
  contribution: (req, res) ->

    # Ensure an subject was given.
    throw new ServerError 400, "No subject given." unless req.body.subject

    # Send an email to hello@webistor.net.
    new Mail()
    .from req.body.email
    .to 'hello@webistor.net'
    .subject "Webistor Feedback - #{req.body.subject}"
    .template "feedback/contribution", {req.body}
    .send()
