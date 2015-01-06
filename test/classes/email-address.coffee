EmailAddress = require '../../src/classes/email-address'

describe "EmailAddress", ->

  describe ".create", ->

    it "should turn an array of plain addresses into an array of EmailAddress objects", ->
      recipients = ['a@example.com', 'b@example.com']
      emails = EmailAddress.create recipients
      emails.must.be.an Array
      emails.must.have.length 2
      emails[0].must.be.an EmailAddress
      emails[0].getAddress().must.be 'a@example.com'
      emails[1].must.be.an EmailAddress
      emails[1].getAddress().must.be 'b@example.com'

    it "should parse fully-formatted and plain addresses", ->
      recipients = ['Mister A <a@example.com>', 'b@example.com', '<c@example.com>']
      emails = EmailAddress.create recipients
      emails.must.have.length 3
      emails[0].getAddress().must.be 'a@example.com'
      emails[1].getAddress().must.be 'b@example.com'
      emails[2].getAddress().must.be 'c@example.com'

    it "should parse objects with an email property", ->
      bob = {email: 'bob@example.com'}
      emails = EmailAddress.create bob
      emails.must.have.length 1
      emails[0].getAddress().must.be bob.email

    it "should parse comma/semicolon-separated values", ->
      recipients = ' a@example.com, b@example.com   ;c@example.com   '
      emails = EmailAddress.create recipients
      emails.must.have.length 3
      emails[0].getAddress().must.be 'a@example.com'
      emails[1].getAddress().must.be 'b@example.com'
      emails[2].getAddress().must.be 'c@example.com'

  describe "validation", ->

    it "should validate valid email addresses", ->
      emails = EmailAddress.create ['Mister A <a@example.com>', 'b@example.com', '<c@example.com>']
      email.isValid().must.be true for email in emails

    it "should invalidate invalid email addresses", ->
      emails = EmailAddress.create ['Mister A <a..@example.com>', 'The Man', '<@_@>']
      email.isValid().must.be false for email in emails
