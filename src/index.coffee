http = require 'http'
express = require 'express'
Promise = require 'bluebird'
config = require './config'
log = require 'node-logging'
AuthFactory = require './classes/auth-factory'
SessionController = require './controllers/session-controller'
EntryController = require './controllers/entry-controller'
TagController = require './controllers/tag-controller'
InvitationController = require './controllers/invitation-controller'
favicon = require 'static-favicon'
{json} = require 'body-parser'
session = require 'cookie-session'
serveStatic = require 'serve-static'

##
## SHARED
##

# Create shared middleware.
favicon = favicon "#{config.publicHtml}/icons/favicon.ico"

# Set up logging.
# Promise.onPossiblyUnhandledRejection -> log.dbg 'Supressing PossiblyUnhandledRejection.'
Promise.longStackTraces() if config.logLevel is 'debug'
log.setLevel config.logLevel


##
## CLIENT
##

# Instantiate client application-server.
client = express()

# Content Security Policy.
client.use (req, res, next) ->
  res.header 'Content-Security-Policy', [
    "default-src 'none'"
    "style-src 'self' http://fonts.googleapis.com/ http://netdna.bootstrapcdn.com/"
    "font-src 'self' http://themes.googleusercontent.com/ http://netdna.bootstrapcdn.com/ http://fonts.gstatic.com/"
    "script-src 'self' 'unsafe-eval'"
    "img-src 'self'"
    "connect-src http://api.#{config.domainName}:#{config.httpPort}/" + (
      if config.debug then " ws://localhost:9485/ http://localhost:#{config.serverPort}" else ''
    )
  ].join(';\n')
  next()

# Set up shared middleware.
client.use favicon

# Set up routing to serve up static files from the /public folder, or index.html.
client.use serveStatic config.publicHtml
client.get '*', (req, res) -> res.sendfile "#{config.publicHtml}/index.html"

# Start listening on the client port.
client.listen config.clientPort if config.clientPort


##
## SERVER
##

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

# Set up shared middleware.
# server.use favicon

# Parse request body as JSON.
server.use json strict:true

# Set up session support.
server.use session key: 'session', keys: config.sessionKeys, signed: true

# Import database schemas.
server.db = require './schemas'
server.db.mongoose.connect config.database

# Instantiate controllers.
server.sessionController = new SessionController new AuthFactory
server.entryController = new EntryController
server.tagController = new TagController
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
server.db.Entry.methods ['get', 'post', 'put', 'delete']
server.db.Entry.before 'get', ensureOwnership
server.db.Entry.before 'post', ensureOwnership
server.db.Entry.before 'put', ensureOwnership
server.db.Entry.before 'delete', ensureOwnership
server.db.Entry.register server, '/entries'
server.get '/entries', ensureLogin
server.get '/entries', server.entryController.getMiddleware 'search'

# Route: Set up tag REST routes.
server.db.Tag.methods ['get', 'post', 'put', 'delete']
server.db.Tag.before 'get', ensureOwnership
server.db.Tag.before 'post', ensureOwnership
server.db.Tag.before 'put', ensureOwnership
server.db.Tag.before 'delete', ensureOwnership
server.db.Tag.after 'get', server.tagController.getMiddleware 'addNum'
server.db.Tag.after 'post', server.tagController.getMiddleware 'addNum'
server.db.Tag.after 'put', server.tagController.getMiddleware 'addNum'
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


##
## DAEMON
##

# Only perform daemon related setup if enabled.
if config.daemon?.enabled

  # Better not have debug mode enabled past this point.
  log.err "WARNING: Ensure debug mode is disabled in a production environment." if config.debug

  # Create a simple "proxy" server which will forward requests made to the daemon port
  # to the right express server.
  proxy = http.createServer (req, res) ->
    root = config.domainName
    host = req.headers.host.split(':')[0]
    switch host
      when root, "www.#{root}" then client arguments...
      when "api.#{root}" then server arguments...
      else do ->
        body = "Host #{host} not recognized. This might be due to bad server configuration."
        res.writeHead 400, "Invalid host.", {
          'Content-Length': body.length
          'Content-Type': 'text/plain'
        }
        res.end body

  # Listen on the set http port. Downgrade process permissions once set up.
  proxy.listen config.daemon.httpPort, ->
    process.setgid config.daemon.gid
    process.setuid config.daemon.uid

  # Create an admin server.
  admin = express()

  # Bring the application to an idle state.
  admin.get '/shutdown', (req, res) ->
    server.db.disconnect client.close server.close proxy.close ->
      res.status(200).end()
      admin.close()

  # Listen on admin port.
  admin.listen config.daemon.adminPort



##
## EXPORTS
##

# Export our servers when in debug mode.
module.exports = {client, server, proxy, admin} if config.debug
