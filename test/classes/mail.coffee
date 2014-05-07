path = require 'path'
config = require '../_config'
Mail = require '../../src/classes/mail'
{User} = require '../../src/schemas'

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

  describe "class interactions", ->

    it "should allow setting options through the constructor", ->
      mail = new Mail mailTemplate.from, mailTemplate.to, mailTemplate.subject
      mail._from.must.be "#{mailTemplate.from}@#{config.domainName}"
      mail._to.must.be.an Array
      mail._to.must.have.length 1
      mail._to[0].must.be mailTemplate.to
      mail._subject.must.be mailTemplate.subject

    it "should allow setting options through method-chaining", ->
      mail = (new Mail)
      .from mailTemplate.from
      .to mailTemplate.to
      .subject mailTemplate.subject
      .body mailTemplate.body
      mail._from.must.be "#{mailTemplate.from}@#{config.domainName}"
      mail._to.must.be.an Array
      mail._to.must.have.length 1
      mail._to[0].must.be mailTemplate.to
      mail._subject.must.be mailTemplate.subject
      mail._text.must.be mailTemplate.body

  describe "::to", ->

    userTemplate =
      email: 'test@example.com'
      username: 'test'
      password: 'suchpassword'

    before (done) -> User.remove {}, onSuccess => User.create userTemplate, onSuccess (@user) => done()
    after (done) -> User.remove {}, done

    it "should allow setting recipients through User objects", ->
      bob = @user
      mail = new Mail
      mail.to bob
      mail._to[0].must.be bob.email

    it "should allow setting multiple recipients through comma or semi-colon separated values", ->
      mail = new Mail
      mail.to ' a@example.com, b@example.com   ;c@example.com   '
      mail._to.must.be.an Array
      mail._to.must.have.length 3
      mail._to[0].must.be 'a@example.com'
      mail._to[1].must.be 'b@example.com'
      mail._to[2].must.be 'c@example.com'

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
      mail.body mailTemplate.body
      mail.send()
      done()

    it "should reach multiple addresses", (done) ->
      mail = new Mail mailTemplate.from, ['aldwin.vlasblom@gmail.com', 'aldwin@tuxion.nl'], 'Test Multiple'
      mail.body mailTemplate.body
      mail.send()
      done()

    it "should get an answer within two minutes", (done) ->
      @timeout 1000*60*2
      @slow 1000*10
      mail = new Mail mailTemplate.from, mailTemplate.to, mailTemplate.subject
      mail.body mailTemplate.body
      mail.send().done (res) ->
        res.must.have.property 'messageId'
        done()

    it "should transfer HTML messages", (done) ->
      mail = new Mail mailTemplate.from, mailTemplate.to, mailTemplate.subject
      mail.html "<ul><li><b>#{mailTemplate.body}</b></li></ul>"
      mail.send()
      done()
