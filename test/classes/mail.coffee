path = require 'path'
config = require '../_config'
Mail = require '../../src/classes/mail'
EmailAddress = require '../../src/classes/email-address'
{User} = require '../../src/schemas'

# Test email address first.
require "./email-address"

Mail.TEMPLATE_DIRECTORY = path.resolve __dirname, '../templates/mail'

onSuccess = (callback) -> (err, args...) ->
  console.log err if err
  throw err if err
  callback? args...

describe "Mail", ->

  mailTemplate =
    from: 'bob'
    to: 'aldwin.vlasblom@gmail.com'
    subject: 'Test subject'
    body: 'Test body'

  describe "::from", ->

    it "should create an EmailAddress", ->
      mail = new Mail
      mail.from "bob@example.com"
      mail._from.must.be.an EmailAddress

    it "should not touch already valid input", ->
      mail = new Mail
      mail.from "bob@example.com"
      mail._from.getAddress().must.be "bob@example.com"

    it "should use username and email when present in the given object", ->
      mail = new Mail
      mail.from {username: "Bob", email: "bob@example.com"}
      mail._from.getAddress().must.be "bob@example.com"
      mail._from.getName().must.be "Bob"

    it "should create an email address when not given", ->
      mail = new Mail
      mail.from "Bob"
      mail._from.getAddress().must.be "bob@#{config.domainName}"
      mail._from.getName().must.be "Bob"

  describe "::to", ->

    it "should normalize addresses", ->
      mail = new Mail
      mail.to "Bob <bob@example.com>"
      mail._to.must.be.an Array
      mail._to[0].must.be.an EmailAddress
      mail._to[0].getAddress().must.be "bob@example.com"
      mail._to[0].getName().must.be "Bob"

    it "should allow adding addresses in batches", ->
      mail = new Mail
      mail.to "bob@example.com"
      mail.to "ben@example.com"
      mail._to.must.have.length 2
      mail.to "bob@example.com"
      mail._to.must.have.length 2

  describe "class interactions", ->

    it "should allow setting options through the constructor", ->
      mail = new Mail mailTemplate.from, mailTemplate.to, mailTemplate.subject
      mail._to.must.be.an Array
      mail._to.must.have.length 1
      mail._to[0].getAddress().must.be mailTemplate.to
      mail._subject.must.be mailTemplate.subject

    it "should allow setting options through method-chaining", ->
      mail = (new Mail)
      .from mailTemplate.from
      .to mailTemplate.to
      .subject mailTemplate.subject
      .text mailTemplate.body
      mail._to.must.be.an Array
      mail._to.must.have.length 1
      mail._to[0].getAddress().must.be mailTemplate.to
      mail._subject.must.be mailTemplate.subject
      mail._text.must.be mailTemplate.body

  describe "templating", ->

    it "should be able to generate body from templates", (done) ->
      mail = new Mail
      mail.generate 'test-both', mailTemplate
      .then ->
        mail._html.must.contain "<b"
        mail._html.must.contain "color: #f00"
        mail._html.must.contain mailTemplate.body
        mail._text.must.contain "**#{mailTemplate.body}**"
      .done done

  describe.skip "sending", ->

    it "should be possible", (done) ->
      mail = new Mail mailTemplate.from, mailTemplate.to, mailTemplate.subject
      mail.text mailTemplate.body
      mail.send()
      done()

    it "should reach multiple addresses", (done) ->
      mail = new Mail mailTemplate.from, ['aldwin.vlasblom@gmail.com', 'aldwin@tuxion.nl'], 'Test Multiple'
      mail.text mailTemplate.body
      mail.send()
      done()

    it.skip "should get an answer within two minutes", (done) ->
      @timeout 1000*60*2
      @slow 1000*10
      mail = new Mail mailTemplate.from, mailTemplate.to, mailTemplate.subject
      mail.text mailTemplate.body
      mail.send()
      .then (res) -> res.must.have.property 'messageId'
      .done done

    it "should transfer HTML messages", (done) ->
      mail = new Mail mailTemplate.from, mailTemplate.to, mailTemplate.subject
      mail.html "<ul><li><b>#{mailTemplate.body}</b></li></ul>"
      mail.send()
      done()
