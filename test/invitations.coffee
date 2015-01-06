supertest = require 'supertest'
config = require './_config'
{server} = require '../src'
{Invitation, User} = server.db


##
## HELPERS
##

onSuccess = (callback) -> (err, args...) ->
  throw err if err
  callback? args...

fixError = (callback) -> (err, res) ->
  return callback(null, res) unless err
  responseErr = res?.body?.error or res?.text
  message = (err.message or err.toString())
  message += (" because: " + responseErr) if responseErr
  callback new Error message


##
## TESTS
##

describe "Invitation (REST)", ->

  after (done) -> Invitation.remove {}, done
  after (done) -> User.remove {}, done

  req = supertest server

  describe.skip 'requests', ->

    avaq = email:'aldwin.vlasblom@gmail.com'

    it 'should respond with an error code when email address is not given', (done) ->
      req.post '/invitations/request'
      .expect 400
      .end fixError done

    it 'should handle new addresses by creating a new record', (done) ->
      req.post '/invitations/request'
      .send avaq
      .expect 201
      .end fixError onSuccess (err) ->
        Invitation.findOne avaq, onSuccess (inv) ->
          inv.must.exist()
          inv.must.have.property '_id'
          inv.must.have.property 'status'
          inv.status.must.be 'awaiting'
          done()

    it 'should handle already existing addresses by pretending to have created a new record', (done) ->
      req.post '/invitations/request'
      .send avaq
      .expect 201
      .end fixError (err) ->
        throw err if err
        Invitation.count avaq, onSuccess (amount) ->
          amount.must.be 1
          done()

    it 'should handle already existing users by pretending to have created a new record', (done) ->
      User.create {email: avaq.email, username: 'Avaq', password: 'suchpassword'}, (err) ->
        throw err if err
        req.post '/invitations/request'
        .send avaq
        .expect 201
        .end fixError done
