supertest = require 'supertest'
require './_config'
Auth = require '../src/classes/auth'
{server} = require '../src'
{User} = server.db
{session} = server


##
## HELPERS
##

onSuccess = (callback) -> (err, args...) ->
  throw err if err
  callback? args...

userTemplate =
  email: 'aldwin.vlasblom@gmail.com'
  username: 'avaq'
  password: "suchpassword"


##
## TESTS
##

describe "The authentication class", ->

  before (done) ->
    Auth.EXPIRATION_DURATION = 200
    User.create userTemplate, onSuccess (@user) => done()

  after (done) ->
    Auth.EXPIRATION_DURATION = 1000*60*60
    @user.remove done

  @slow 500

  it "should be a class", ->
    Auth.must.be.function()
    (new Auth).must.be.instanceof Auth

  it "should trigger the callback on expiration", (done) ->
    setTimeout (->), 200
    auth = new Auth @user, done

  it "should not expire if refreshed in time", (done) ->
    passed = false
    auth = new Auth @user, ->
      passed.must.be true
      done()
    setTimeout (->auth.refresh()), 150
    setTimeout (->passed = true), 300

  it "should lock after the maximum attempts", ->
    auth = new Auth @user
    auth.attempt() for i in [0..Auth.MAX_ALLOWED_ATTEMPTS]
    auth.isLocked().must.be true

  it "should compare passwords properly", (done) ->
    auth = new Auth @user
    auth.authenticatePassword userTemplate.password
    .done done, onSuccess

  it "should generate tokens and compare them properly", (done) ->
    auth = new Auth @user
    token = auth.generateToken()
    token.must.have.length 32
    auth.authenticateToken token
    .done done, onSuccess


describe "Managing users", ->

  describe "directly through mongoose", ->

    before (done) -> User.remove {}, done
    afterEach (done) -> User.remove {}, done

    it "should have the right interface available", ->
      User.create.must.be.function()
      usr = new User
      usr.must.be.instanceof User
      usr.must.have.property 'save'

    it "should store users and hash passwords", (done) ->
      pw = userTemplate.password
      usr = new User userTemplate
      usr.save onSuccess (usr, num) ->
        usr.password.must.not.be pw
        num.must.be 1
        done()

    it "should have deleted new users after previous tests", (done) ->
      User.count onSuccess (count) ->
        count.must.be 0
        done()

  describe "through the REST API", ->

    before (done) -> User.create userTemplate, done
    after (done) -> User.remove {}, done

    req = supertest server
    agent = supertest.agent server

    it "should repond with value:false when doing a login check without a login", (done) ->
      req.get '/session/loginCheck'
      .expect 200
      .expect value:false
      .end done

    it "should respond with 404 when the 'me' resource is requested without a login", (done) ->
      req.get '/users/me'
      .expect 404
      .end done

    it "should not allow logging in with empty credentials", (done) ->
      req.post '/users/me'
      .expect 401
      .expect error: "No username or email address given."
      .end done

    it "should not allow logging in with invalid credentials", (done) ->
      req.post '/users/me'
      .send username: "Bob", password: "suchpassword"
      .expect 401
      .expect error: "Invalid username/email or password/token."
      .end done

    it "should allow logging in with valid credentials", (done) ->
      agent.post '/users/me'
      .send username: userTemplate.username, password: userTemplate.password
      .expect 200
      .end onSuccess (res) ->
        res.body.username.must.be userTemplate.username
        done()

    it "should repond with value:true when doing a login check with a login", (done) ->
      agent.get '/session/loginCheck'
      .expect 200
      .expect value:true
      .end done

    it "should respond with the logged in user when the 'me' resource is requested with a login", (done) ->
      agent.get '/users/me'
      .expect 200
      .end onSuccess (res) ->
        res.body.username.must.be userTemplate.username
        done()

    it "should not share sessions between agents", (done) ->
      supertest.agent server
      .get '/users/me'
      .expect 401
      .end done
