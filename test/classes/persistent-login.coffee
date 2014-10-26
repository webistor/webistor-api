sinon = require 'sinon'
PersistentLogin = require '../../src/classes/persistent-login'
schemas = require '../../src/schemas'
Promise = require 'bluebird'

describe.only "PersistentLogin", ->

  describe "constructor", ->

    req = {}
    res = {}

    it "should throw when not given a request", ->
      try new PersistentLogin null, res
      catch err then return
      throw new Error "No error was thrown"

    it "should throw when not given a response", ->
      try new PersistentLogin req, null
      catch err then return
      throw new Error "No error was thrown"

    it "should store request and response", ->
      pl = new PersistentLogin req, res
      pl.req.must.be req
      pl.res.must.be res

  describe ".generate", ->

    it "should throw when user is not logged-in", ->

      req = {session:{}}
      res = {}

      try new PersistentLogin(req, res).generate()
      catch err then return
      throw new Error "No error was thrown"
