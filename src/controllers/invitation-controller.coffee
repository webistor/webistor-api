Controller = require './base/controller'
Promise = require 'bluebird'
ServerError = require './base/server-error'
User = Promise.promisifyAll (require '../schemas').User
Invitation = Promise.promisifyAll (require '../schemas').Invitation
config = require '../config'
log = require 'node-logging'

module.exports = class InvitationController extends Controller

  ###*
   * Store an unaccepted invitation under the given email address.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A Promise of
  ###
  request: (req, res) ->

    # Ensure an email address was given.
    throw new ServerError 400, "No email address given." unless req.body.email

    # Check the database if the user already has an account with us.
    User.findOneAsync {email:req.body.email}, lean:true
    .then (user) ->

      throw new ServerError 600, "User already has an account."

    # Check the database if the user is already in the system.
    Invitation.findAsync {email:req.body.email}, lean:true

    # Hide "user in the system" errors from the response.
    .catch (ServerError.Predicate 600), (err) ->
      log.dbg "Failed to create invitation request for #{req.body.email}: #{err.message}"

    .then ->
      res.end 201


    # inv = Promise.promisifyAll new Invitation email:req.body.email
    # inv.saveAsync()

  ###*
   * The logged in user expends an invitation "coupon" in order to invite a friend.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A Promise of an Invitation document.
  ###
  invite: (req) ->

