supertest = require 'supertest'
config = require './_config'
{server} = require '../src'
{Tag, User, mongoose} = server.db

onSuccess = (callback) -> (err, args...) ->
  throw err if err
  callback? args...

avaq = {username:'avaq',email:'aldwin.vlasblom@gmail.com',password:'suchpassword'}

describe "The Tag model", ->

  before (done) -> User.remove {}, onSuccess => User.create avaq, onSuccess (@author) => done()

  it "should be a model", ->
    (new Tag).must.be.instanceof Tag
    Tag.create.must.exist()

  it "should create tags", (done) ->
    tags = []
    tags.push {author:@author, title: "Tag#{n}"} for n in [1..10]
    Tag.create tags, onSuccess (tag1) ->
      tag1.must.have.property '_id'
      tag1.must.have.property 'author'
      done()

  it "should have created 10 tags", (done) ->
    Tag.count {}, onSuccess (num) ->
      num.must.be 10
      done()

describe 'API:', ->

  req = supertest server
  agentAvaq = supertest.agent server

  onSuccess = (callback) -> (err, res) ->
    return callback res unless err
    responseErr = res?.body?.error or res?.text
    message = (err.message or err.toString())
    message += (" because: " + responseErr) if responseErr
    throw new Error message

  before (done) -> User.remove {}, onSuccess => User.create avaq, onSuccess (@author) => done()

  before (done) ->
    agentAvaq.post '/users/me'
    .send {username:avaq.username, password:avaq.password}
    .end done

  after (done) -> User.remove {}, done
  after (done) -> Tag.remove {}, done

  describe "Managing custom tags", ->

    it "should not allow access to users without a session", (done) ->
      req.get '/tags'
      .expect 401
      .end done

    it "should allow logged-in users to create tags", (done) ->
      agentAvaq.post '/tags'
      .send {title: 'MyTag'}
      .expect 201
      .end onSuccess (res) ->
        res.body.must.have.property '_id'
        done()

    it "should return only authored tags to logged in users", (done) ->
      agentAvaq.get '/tags'
      .expect 200
      .end onSuccess (res) =>
        res.body.must.be.an Array
        res.body.must.have.length 1
        res.body[0].must.have.property '_id'
        @tags = res.body
        done()

    it "should allow logged in users to patch tags", (done) ->
      tags = @tags.concat [{title: 'MySecondTag'}]
      tags[0].title = 'MyFirstTag'
      agentAvaq.patch '/tags'
      .send tags
      .expect 200
      .end onSuccess (res) ->
        res.body.must.be.an Array
        res.body.must.have.length 2
        res.body[0].title.must.be 'MyFirstTag'
        res.body[1].title.must.be 'MySecondTag'
        res.body[1].must.have.property '_id'
        done()
