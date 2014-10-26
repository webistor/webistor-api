Controller = require './base/controller'
Promise = require 'bluebird'
ServerError = require './base/server-error'
User = Promise.promisifyAll (require '../schemas').User
Invitation = Promise.promisifyAll (require '../schemas').Invitation
config = require '../config'
log = require 'node-logging'
Mail = require '../classes/mail'

module.exports = class InvitationController extends Controller

  ###*
   * Find an invitation by its token.
   *
   * @param {http.IncomingMessage} req The Express request object. Required fields:
   *                                   `req.params.token`: The token.
   *
   * @return {Promise} A promise of an invitation.
  ###
  findByToken: (req) ->
    throw new ServerError 400, "No token provided." unless req.params.token
    Invitation.findOneAsync {token:req.params.token}, '+token'
    .then (invitation) ->
      throw new ServerError 404, "Invitation not found." unless invitation
      return invitation

  ###*
   * Store an unaccepted invitation under the given email address.
   *
   * @param {http.IncomingMessage} req The Express request object. Required fields:
   *                                   `req.body.email`: The email address.
   *
   * @return {Promise} A Promise which resolves once the response is generated.
  ###
  request: (req, res) ->

    # Ensure an email address was given.
    throw new ServerError 400, "No email address given." unless req.body.email

    # Check the database if the user already has an account with us.
    User.findOneAsync {email:req.body.email}
    .then (user) ->

      # If the user is found, send them an email to remind them.
      return unless user?
      new Mail()
      .from 'Webistor <hello@webistor.net>'
      .to user
      .subject 'Requested invitation - already registered'
      .template 'invitations/user-already-registered', {user}
      .send()

      # Throw an exception to prevent following steps from being executed.
      .throw new ServerError 600, "User already has an account."

    # Check the database if the user is already in the system.
    .then ->
      d = Promise.defer()
      Invitation.findOne({email:req.body.email}, '+token').populate('author').exec(d.callback)
      return d.promise

    # Handle the database result.
    .then (invitation) ->

      # Skip this step if the user wasn't already on the invite list.
      return unless invitation?

      # Ensure the invitation has a valid status.
      unless invitation.status in ['awaiting', 'accepted']
        throw new ServerError 500, "Invitation process completed but user not found."

      # Send an email to tell the user in which status their invitation is.
      new Mail()
      .from 'Webistor <hello@webistor.net>'
      .to invitation.email
      .subject "Requested invitation - #{invitation.status}"
      .template "invitations/user-already-#{invitation.status}", {invitation}
      .send()

      # Throw an exception to prevent following steps from being executed.
      .throw new ServerError 600, "User already has a(n) #{invitation.status} invitation."

    # Create and save a new invitation.
    .then -> Promise.promisifyAll(new Invitation email:req.body.email).saveAsync()

    # Send the user an email to let them know they've been added to the waiting list.
    .spread (invitation) ->
      new Mail()
      .from 'Webistor <hello@webistor.net>'
      .to invitation.email
      .subject "Requested invitation - confirmation"
      .template "invitations/request-confirmation", {invitation}
      .send()

    # Hide "user in the system" errors from the response.
    .catch (ServerError.Predicate 600), (err) ->
      log.dbg "Failed to create invitation request for #{req.body.email}: #{err.message}"

    # Send the response.
    .then -> res.status(201).send(email:req.body.email)

  ###*
   * The logged in user expends an invitation "coupon" in order to invite a friend.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A Promise of an Invitation document.
  ###
  invite: (req) ->

