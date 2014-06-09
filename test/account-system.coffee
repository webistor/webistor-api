supertest = require 'supertest'
config = require './_config'
Auth = require '../src/classes/auth'
{server} = require '../src'
{User} = server.db


##
## HELPERS
##

onSuccess = (callback) -> (err, args...) ->
  throw err if err
  callback? args...


##
## TESTS
##

describe "The authentication class", ->

  userTemplate =
    email: 'aldwin.vlasblom@gmail.com'
    username: 'avaq'
    password: "suchpassword"

  before (done) ->
    Auth.EXPIRATION_DURATION = 200
    User.remove {}, onSuccess => User.create userTemplate, onSuccess (@user) => done()

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
    @slow 750
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

    userTemplate =
      email: 'aldwin.vlasblom@gmail.com'
      username: 'avaq'
      password: "suchpassword"

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

    logError = (done) -> (err, res) ->
      return done() unless err
      responseErr = res?.body?.error or res?.text
      message = (err.message or err.toString())
      message += (" because: " + responseErr) if responseErr
      done new Error message

    req = supertest server

    agentArcher = supertest.agent server
    agentBond   = supertest.agent server
    agentCortez = supertest.agent server

    archer = username: 'archer', email: 'sterling@isis.example.com', password: 'guest'
    bond   = username: 'bond007', email: 'james.bond@rn.example.com', password: '��U�yύi�'
    cortez = username: 'spykid', email: 'carmen_h8_school@msn.example.com', password: '[)14p3r'

    before (done) -> User.create archer, done
    after (done) -> User.remove {}, done

    it "should repond with value:false when performing a login-check without a present session", (done) ->
      req.get '/session/loginCheck'
      .expect 200
      .expect value:false
      .end logError done

    it "should respond with 404 when the 'me' resource is requested without a present session", (done) ->
      req.get '/users/me'
      .expect 404
      .end logError done

    it "should not allow logging in with empty credentials", (done) ->
      req.post '/users/me'
      .send {}
      .expect 400
      .end logError done

    it "should not allow logging in with invalid username", (done) ->
      req.post '/users/me'
      .send username: "bob", password: "suchpassword"
      .expect 401
      .end logError done

    it "should not allow logging in with invalid password", (done) ->
      req.post '/users/me'
      .send username: "archer", password: "suchpassword"
      .expect 401
      .end logError done

    it "should allow logging in with valid credentials", (done) ->
      agentArcher.post '/users/me'
      .send username: archer.username, password: archer.password
      .expect 200
      .end onSuccess (res) ->
        res.body.username.must.be archer.username
        res.body.must.not.have.property 'password'
        done()

    it "should repond with value:true when performing a login-check with a present session", (done) ->
      agentArcher.get '/session/loginCheck'
      .expect value:true
      .end logError done

    it "should respond with the logged in user when the 'me' resource is requested with a present session", (done) ->
      agentArcher.get '/users/me'
      .expect 200
      .end onSuccess (res) ->
        res.body.username.must.be archer.username
        res.body.must.not.have.property 'password'
        done()

    it "should not share sessions between agents", (done) ->
      agentBond.get '/users/me'
      .expect 404
      .end logError done

    it "should respond with value:true when checking the existence of an existing username", (done) ->
      req.post '/session/nameCheck'
      .send username: archer.username
      .expect value:true
      .end logError done

    it "should respond with value:false when checking the existence of a non-existing username", (done) ->
      req.post '/session/nameCheck'
      .send username: 'bob'
      .expect value:false
      .end logError done

    it "should prevent users registration while in alpha release state", (done) ->
      config.releaseStage = 'alpha'
      agentBond.post '/users'
      .send bond
      .expect 403
      .end logError done

    it "should allow user registration while in public beta release state", (done) ->
      config.releaseStage = 'publicBeta'
      agentBond.post '/users'
      .send bond
      .expect 200
      .end onSuccess (res) ->
        res.body.username.must.be bond.username
        res.body.must.have.property '_id'
        res.body.must.not.have.property 'password'
        done()

    it "should have registerred the user", (done) ->
      req.post '/session/nameCheck'
      .send username: bond.username
      .expect value:true
      .end logError done
