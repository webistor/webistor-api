express = require 'express'
{json} = require 'body-parser'
cookie = require 'cookie-parser'
session = require 'express-session'
MongoStore = require 'express-session-mongo'

InvitationController = require './controllers/invitation-controller'
SessionController = require './controllers/session-controller'
EntryController = require './controllers/entry-controller'
TagController = require './controllers/tag-controller'
AuthFactory = require './classes/auth-factory'

###*
 * Creates a new server, the central API.
 * @param  {object} config  Dependency injection of the configuration values.
 *                          See `/config.coffee`.
 * @param  {object} opts    Holds the options for this server. Currently none.
 * @return {Express}        The created server express instance.
###
module.exports = (config, opts) ->

  # Instantiate API server.
  server = express()

  # Access control.
  server.use (req, res, next) ->
    return next() unless req.headers.origin?
    originDomain = req.headers.origin.match(/^\w+:\/\/(.*?)([:\/].*?)?$/)[1]
    if originDomain in config.whitelist
      res.header 'Access-Control-Allow-Origin', req.headers.origin
      res.header 'Access-Control-Allow-Credentials', 'true'
      if req.method is 'OPTIONS'
        res.header 'Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH'
        res.header 'Access-Control-Allow-Headers', req.headers['access-control-request-headers']
        return res.end()
    next()

  # Parse request body as JSON.
  server.use json strict:true

  # Import database schemas and connect to the MongoDB.
  server.db = require './schemas'
  server.db.mongoose.connect "mongodb://#{config.database.host}/#{config.database.name}"

  # Set up cookie support.
  server.use cookie()

  # Set up session support.
  server.use session
    name: 'session'
    secret: config.authentication.secret
    resave: true
    saveUninitialized: false
    store: new MongoStore
      host: config.database.host
      db: config.database.name
  server.tagController = new TagController
      collection: 'sessions'

  # Instantiate controllers.
  server.sessionController = new SessionController new AuthFactory
  server.entryController = new EntryController
  server.invitationController = new InvitationController

  # Route: Set up user system routes.
  server.get '/users/me', server.sessionController.getMiddleware 'getUser'
  server.post '/users/me', server.sessionController.getMiddleware 'login'
  server.delete '/users/me', server.sessionController.getMiddleware 'logout'
  server.get '/session/loginCheck', server.sessionController.getMiddleware 'isLoggedIn'
  server.post '/session/nameCheck', server.sessionController.getMiddleware 'usernameExists'
  server.post '/password-reset', server.sessionController.getMiddleware 'sendPasswordToken'

  # TODO: Protect this request with anti-botting measures.
  server.post '/users', server.sessionController.getMiddleware 'register'
  server.post '/users/:id/password-reset', server.sessionController.getMiddleware 'resetPassword'

  # Shared middleware.
  ensureLogin = server.sessionController.getMiddleware 'ensureLogin'
  ensureOwnership = server.sessionController.getMiddleware 'ensureOwnership'

  # Route: Set up entry REST routes.
  server.get '/entries', ensureLogin
  server.get '/entries', server.entryController.getMiddleware 'search'
  server.db.Entry.methods ['get', 'post', 'put', 'delete']
  server.db.Entry.before 'get', ensureOwnership
  server.db.Entry.before 'post', ensureOwnership
  server.db.Entry.before 'post', server.entryController.getMiddleware 'ensureUniqueURI'
  server.db.Entry.before 'post', server.entryController.getMiddleware 'detectDirtyTags'
  server.db.Entry.after 'post', server.entryController.getMiddleware 'cacheDirtyTags'
  server.db.Entry.before 'put', ensureOwnership
  server.db.Entry.before 'put', server.entryController.getMiddleware 'ensureUniqueURI'
  server.db.Entry.before 'put', server.entryController.getMiddleware 'detectDirtyTags'
  server.db.Entry.after 'put', server.entryController.getMiddleware 'cacheDirtyTags'
  server.db.Entry.before 'delete', ensureOwnership
  server.db.Entry.before 'delete', server.entryController.getMiddleware 'detectDirtyTags'
  server.db.Entry.after 'delete', server.entryController.getMiddleware 'cacheDirtyTags'
  server.db.Entry.register server, '/entries'

  # Route: Set up tag REST routes.
  server.db.Tag.methods ['get', 'post', 'put', 'delete']
  server.db.Tag.before 'get', ensureOwnership
  server.db.Tag.before 'get', server.entryController.getMiddleware 'updateDirtyTags'
  server.db.Tag.before 'post', ensureOwnership
  server.db.Tag.before 'put', ensureOwnership
  server.db.Tag.before 'delete', ensureOwnership
  server.db.Tag.register server, '/tags'
  server.patch '/tags', ensureLogin
  server.patch '/tags', server.tagController.getMiddleware 'patch'

  # Route: Set up invitation related routes.
  server.get '/invitations/:token', server.invitationController.getMiddleware 'findByToken'
  server.post '/invitations/request', server.invitationController.getMiddleware 'request'
  server.post '/invitations', ensureLogin
  server.post '/invitations',  server.invitationController.getMiddleware 'invite'

  # Start listening on the server port.
  server.listen config.serverPort if config.serverPort

  return server
