nodemailer = require 'nodemailer'
Promise = require 'bluebird'
log = require 'node-logging'
emailTemplates = Promise.promisify require 'email-templates'
Mail = require './mail'
config = require '../config'

module.exports = class BatchMail extends Mail

  batching: false
  _batch: (->)

  ###*
   * Construct a new BatchMail.
   *
   * All arguments are optional and can be given through the referred to methods.
   *
   * @param {String} from {@see Mail::from}
   * @param {Array} to {@see Mail::to}
   * @param {String} subject {@see Mail::subject}
   * @param {Function} batch {@see BatchMail::batch}
   *
   * @return {BatchMail}
  ###
  constructor: (from, to, subject, batch) ->
    super from, to, subject
    @batch batch if batch

  ###*
   * Ensure Mail::to isn't called while batching.
   *
   * @throws {Error} If called during a batch.
   *
   * @inheritDoc
  ###
  to: ->
    throw new Error "Can not overwrite recipients while sending the mail." if @batching
    super

  ###*
   * Set the batch-handler.
   *
   * The batch handler is a callback function which takes one argument: The recipient
   * email address. Before every individual email is sent, the batch handler will be
   * called in the context of a new Mail instance and expected to change the necessary
   * options for the specific recipient:
   *
   * ```coffeescript
   * (new BatchMail).batch (recipient) ->
   *   this.subject "Dear #{recipient}"
   *   this.body "You are #{recipient}!"
   * ```
   *
   * If the function returns a Promise, its resolve-value will be waited for and used
   * instead.
   *
   * Any method can be called inside the batch-handler, including setting templates or
   * even sending the mail. It is not recommended to do either of these: Setting templates
   * should be done via {@see BatchMail::template} as it is more efficient, and sending
   * is done automatically by {@see BatchMail::send}.
   *
   * @throws {Error} If called during a batch.
   *
   * @param {Function} callback The batch handler function.
   *
   * @chainable
  ###
  batch: (callback) ->
    throw new Error "Can not overwrite batch-handler while sending the mail." if @batching
    @_batch = callback
    return this

  ###*
   * Set template name and data generator function.
   *
   * This overrides the batch-handler. Any custom batch-handling should be done in the
   * given generator function. The generated batch handler will optimise and take care of
   * templating. It is therefore not recommended to manually override template settings
   * inside the generator.
   *
   * @param {String} name The name of an email template.
   *
   * @param {Function} data A function like the batch-handler ({@see BatchMail::batch})
   *                        which is expected to return (or promise) the template-data for
   *                        the indivdual recipient.
   *
   * @chainable
  ###
  template: Mail::template

  ###*
   * Generate the batch-handler from a template-name and its data generator function.
   *
   * @throws {Error} If called during a batch.
   *
   * @param {String} name The name of an email template.
   * @param {Object} data The data generator function ({@see BatchMail::template}).
   *
   * @return {Promise} A promise bound to this instance which resolves with this instance
   *                   once the batch-handler has been generated.
  ###
  generate: (name, data) ->
    throw new Error "Can not generate batch-handler while sending the mail." if @batching
    Promise.bind this
    .then -> emailTemplates Mail.TEMPLATE_DIRECTORY
    .then (template) -> Promise.promisify(template) name, true
    .then (batch) ->
      @batch (recipient) ->
        Promise.try data, recipient, this
        .then (data) =>
          return unless data?
          Promise.promisify(batch) data, null
          .spread (html, text) =>
            @text text
            @html html
      @template()

  ###*
   * Send the emails.
   *
   * This auto-generates ({@see BatchMail::generate}) the batch-handler if a template name
   * and data-generator are set prior to actually sending the mail.
   *
   * A separate Mail instance is created for every recipient of this mail. The batch
   * handler set on this BatchMail instance will be called in the context of the new Mail
   * and is expected to perform modifications to the instance (which by default copies
   * the state of this BatchMail) in order to personalize the email for the recipient.
   * Read more at {@see BatchMail::batch}.
   *
   * @throws {Error} If called during a batch.
   *
   * @return {Promise} A promise of an object with two keys:
   *                   * `done`: An array of objects containing `email` and `response`.
   *                   * `failed`: An array of objects containing `email` and `error`.
  ###
  send: ->

    # Don't try to send while you send or you'll be harassed by an overused internet meme.
    throw new Error "Yo dawg. I herd you like sending." if @batching

    # Generate the batch-handler if needed.
    (if @_template then @generate @_template.name, @_template.data else Promise.resolve())

    # Start batching.
    .then =>

      # Log.
      log.dbg "Starting batch-mail to #{@_to.length} recipients..."

      # Lock some methods.
      @batching = true

      # Call the batch handler and send an email for every recipient.
      promises = []
      for recipient in @_to
        mail = new Mail @_from, recipient, @_subject
        mail.text @_text
        mail.html @_html
        p = Promise.try @_batch, recipient, mail
        .bind mail
        .then mail.send
        promises.push p

      # Return the array of promises.
      return promises

    # Wait for all promises to have settled their state.
    .settle()

    # When it's all done: Set batching back to false and build output.
    .then (settled) =>

      log.dbg "Completed batch-mail."

      @batching = false
      done = []
      failed = []

      for inspection, index in settled
        if inspection.isFulfilled() then done.push {email: @_to[index], response: inspection.value()}
        else failed.push {email: @_to[index], error: inspection.error()}

      return {done, failed}
