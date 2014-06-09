path = require 'path'
util = require 'util'
config = require '../_config'
Mail = require '../../src/classes/mail'
BatchMail = require '../../src/classes/batch-mail'
Promise = require 'bluebird'

# Test the parent class first.
require './mail'

onSuccess = (callback) -> (err, args...) ->
  console.log err if err
  throw err if err
  callback? args...

describe "BatchMail", ->

  before ->
    @ORIG_MAIL_TEMPLATE_DIRECTORY = Mail.TEMPLATE_DIRECTORY
    Mail.TEMPLATE_DIRECTORY = path.resolve __dirname, '../templates/mail'

  after ->
    Mail.TEMPLATE_DIRECTORY = @ORIG_MAIL_TEMPLATE_DIRECTORY

  describe "::batch", ->

    it "should set a batch handler function", ->

      mail = (new BatchMail).batch (recipient) ->
        recipient.must.be "test"
        return recipient

      mail._batch.must.be.a Function
      mail._batch('test').must.be 'test'


  describe "templating", ->

    it "should be able to generate batch-handler from templates", (done) ->

      mail = new BatchMail
      mail2 = new Mail

      mail.generate 'test-both', (recipient) ->
        this.must.be mail2
        return {body:"You are #{recipient}!"}

      .then ->
        mail._batch.must.be.a Function
        mail._batch.call(mail2, 'test').then ->
          mail2._text.must.contain "**You are test!**"

      .done done

    it "should handle errors in template generation", (done) ->
      mail = (new BatchMail)
      .generate 'generation-error', (recipient) -> {}
      .then -> done new Error 'No errors were handled'
      .catch (err) -> done()

    it "should handle errors in template population", (done) ->
      mail = new BatchMail
      mail.generate 'population-error', (recipient) -> {}
      .then -> Promise.try mail._batch, 'test@example.com', new Mail
      .then -> done new Error 'No errors were handled'
      .catch (err) -> done()

  describe.skip "sending", ->

    it "should execute batch script and send individual mails", (done) ->

      @timeout 1000*10
      @slow 1000*2

      mail = (new BatchMail)
      .from 'bob'
      .to ['aldwin.vlasblom@gmail.com', 'aldwin@tuxion.nl', 'doomed-to-fail']
      .batch (recipient) ->
        @subject "Dear #{recipient}"
        @text "This is a test mail"
      .send()
      .then (result) ->
        result.done.must.have.length 2
        result.done[0].email.getAddress().must.be 'aldwin.vlasblom@gmail.com'
        result.done[0].response.must.have.property 'messageId'
        result.failed.must.have.length 1
        result.failed[0].email.getAddress().must.be 'doomed-to-fail'
        result.failed[0].must.have.property 'error'
      .done -> done()
