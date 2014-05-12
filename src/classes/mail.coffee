path = require 'path'
nodemailer = require 'nodemailer'
Promise = require 'bluebird'
emailTemplates = Promise.promisify require 'email-templates'
config = require '../config'
log = require 'node-logging'

module.exports = class Mail

  # Constants.
  @TEMPLATE_DIRECTORY: path.resolve __dirname, '../templates/mail'

  # Create the NodeMailer transport object.
  @transport: Promise.promisifyAll nodemailer.createTransport config.mail.type, config.mail.options or {}

  ###*
   * Normalize recipients.
   *
   * When given a string, a comma-separated list of email addresses is assumed. When given
   * an object its `email` property will be used. When given an array, every value is
   * normalized and concatenated.
   *
   * @param {Object} input The recipients to be normalized.
   *
   * @return {[String]} An array of trimmed email addresses.
  ###
  @normalizeRecipients: (input) ->

    # Figure out the input type.
    type = if input instanceof Array then 'array' else typeof input

    # Normalize.
    return switch type
      when 'array' then input.reduce ((a, b) => a.concat Mail.normalizeRecipients b.email or b), []
      when 'object' then @normalizeRecipients input.email
      when 'string' then input.trim().split /\s*[,;]\s*/

  ##
  ## CLASS MEMBERS
  ##

  _from:     "bot@#{config.domainName}"
  _subject:  "Message from #{config.domainName}"
  _text:     'Keep cool.'
  _html:     '<b>Keep cool.</b>'
  _to:       null
  _template: null

  ###*
   * Construct a new Mail.
   *
   * All arguments are optional and can be given through the referred to methods.
   *
   * @param {String} from {@see Mail::from}
   * @param {Array} to {@see Mail::to}
   * @param {String} subject {@see Mail::subject}
   * @param {String} body {@see Mail::body}
   *
   * @return {Mail}
  ###
  constructor: (from, to, subject, body) ->
    @_to = []
    @from from if from
    @to to if to
    @subject subject if subject
    @body body if body

  ###*
   * Set the sender of the email.
   *
   * If the "@domain"-part is omitted in the address, the configured domain name will
   * automatically be appended.
   *
   * @param {String} sender The name or email address of the sender.
   *
   * @chainable
  ###
  from: (sender) ->
    @_from = if '@' in sender then sender else "#{sender}@#{config.domainName}"
    return this

  ###*
   * Add recipients to this mailer.
   *
   * @param {Object} recipients The recipients. Normalized by {@see Mail.normalizeRecipients}.
   *
   * @chainable
  ###
  to: (recipients) ->
    @_to.push email for email in Mail.normalizeRecipients(recipients) when email not in @_to
    return this

  ###*
   * Set a subject.
   *
   * @param {String} topic The subject of the email.
   *
   * @chainable
  ###
  subject: (@_subject) ->
    return this

  ###*
   * Set the message body in HTML.
   *
   * @param {String} html
   *
   * @chainable
  ###
  html: (@_html) ->
    return this

  ###*
   * Set the message body in plain text.
   *
   * @param {String} text
   *
   * @chainable
  ###
  text: (@_text) ->
    return this

  ###*
   * Set both html and text body.
   *
   * @type {String} body
   *
   * @chainable
  ###
  body: (body) ->
    @text body
    @html body
    return this

  ###*
   * Set template name and template data which will be used to generate a template upon sending the mail.
   *
   * When passed no name or data, the template is un-set.
   *
   * @param {String} name The name of an email template.
   *
   * @param {Object} data Data for the template.
   *
   * @chainable
  ###
  template: (name, data) ->
    if name and data then @_template = name:name, data:data
    else @_template = null
    return this

  ###*
   * Generate the mail body from a template.
   *
   * @param {String} name The name of an email template.
   * @param {Object} data Data for the template.
   *
   * @return {Promise} A promise bound to this instance which resolves with this instance
   *                   once the mail body has been generated.
  ###
  generate: (name, data) ->
    Promise.bind this
    .then -> emailTemplates Mail.TEMPLATE_DIRECTORY
    .then (template) -> Promise.promisify(template) name, data
    .spread (html, text) ->
      @text text
      @html html
      @template()

  ###*
   * Send the email.
   *
   * This auto-generates ({@see Mail::generate}) the template if a name and data are set
   * prior to actually sending the mail.
   *
   * @return {Promise} A promise of the nodemailer response object.
  ###
  send: ->

    # Generate the template if needed.
    (if @_template then @generate @_template.name, @_template.data else Promise.resolve())

    # Send out the email.
    .then =>
      log.dbg "Sending mail to #{@_to.join('; ')}"
      Mail.transport.sendMailAsync
        from: @_from
        to: @_to.join ','
        subject: @_subject
        text: @_text if @_text
        html: @_html if @_html
      .then (res) =>
        log.dbg "Done sending mail to #{@_to.join('; ')}"
        return res
