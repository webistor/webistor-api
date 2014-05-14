path = require 'path'
nodemailer = require 'nodemailer'
Promise = require 'bluebird'
emailTemplates = Promise.promisify require 'email-templates'
config = require '../config'
log = require 'node-logging'
EmailAddress = require './email-address'

module.exports = class Mail

  # Constants.
  @TEMPLATE_DIRECTORY: path.resolve __dirname, '../templates/mail'
  @R_SPLIT_ADDRESSES: /\s*[,;]\s*/

  # Create the NodeMailer transport object.
  @transport: Promise.promisifyAll nodemailer.createTransport config.mail.type, config.mail.options or {}

  ##
  ## CLASS MEMBERS
  ##

  _from:     "bot@#{config.domainName}"
  _subject:  "Message from #{config.domainName}"
  _text:     null
  _html:     null
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
   * @param {String} text {@see Mail::text}
   * @param {String} html {@see Mail::html}
   *
   * @return {Mail}
  ###
  constructor: (from, to, subject, text, html) ->
    @_to = []
    @from from if from
    @to to if to
    @subject subject if subject
    @text text if text
    @html html if html

  ###*
   * Set the sender of the email.
   *
   * The sender may be given as a mere name. If so, this function will intelligently
   * generate the email address based on config.domainName:
   *
   * ```coffeescript
   * m = new Mail
   * m.from "Bob"
   * m._from.address == "Bob <bob@example.com>"
   * ```
   *
   * @param {String|Object} sender The name or email address of the sender, or a user object.
   *
   * @chainable
  ###
  from: (sender) ->

    # We got an already created instance.
    if sender instanceof EmailAddress
      @_from = sender
      return this

    # Normalize user (or user-like) object.
    unless typeof sender is 'string'
      sender = if sender.username? then "#{sender.username} <#{sender.email}>" else sender.email

    # Normalize string without address.
    unless '@' in sender
      address = sender.replace(/[^\w]/g, '.').replace(/^\.+/, '').replace(/\.+$/, '').toLowerCase()
      address = "#{address}@#{config.domainName}"
      sender = "#{sender} <#{address}>"

    # Create EmailAddress.
    @_from = EmailAddress.create(sender)[0]

    # Chain.
    return this

  ###*
   * Add recipients to this mailer.
   *
   * @param {Object} recipients The recipients. Normalized by {@see EmailAddress.create}.
   *
   * @chainable
  ###
  to: (recipients) ->
    @_to.push email for email in EmailAddress.create recipients when not @_to.some (to) -> to.equals email
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
    @_template = if name and data then {name, data} else null
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

      # Filter out invalid email addresses.
      to = @_to.filter (email) ->
        return true if email.isValid()
        log.dbg "Removing invalid recipient: '#{email.getAddress()}'"
        return false

      # Throw an error of no recipients remain.
      throw new Error "No valid recipients are set." if to.length is 0

      # Send the mail.
      Mail.transport.sendMailAsync
        from: @_from.format()
        bcc: to.map (email) -> email.format()
        subject: @_subject
        text: @_text if @_text
        html: @_html if @_html
