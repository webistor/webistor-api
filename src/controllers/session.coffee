Controller = require './base/controller'
Promise = require 'bluebird'

module.exports = class Session extends Controller
  
  authFactory: null
  User: null
  
  constructor: (@authFactory, @User) ->
  
  getUser: (req) ->
    return Promise.reject "Not logged in." unless @isLoggedIn req
    Promise.promisisfy(@User.findById, @User) req.session.userId
  
  isLoggedIn: (req) ->
    req.session.userId?
  
  login: (req) ->
    
