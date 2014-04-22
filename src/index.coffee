http = require 'http'
express = require 'express'
Promise = require 'bluebird'
config = require './config'
log = require 'node-logging'
AuthFactory = require './classes/auth-factory'
SessionController = require './controllers/session-controller'
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
    "font-src 'self' http://themes.googleusercontent.com/ http://netdna.bootstrapcdn.com/"
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
server.session = new SessionController new AuthFactory

# Route: Set up session controller routes.
server.get '/users/me', server.session.getMiddleware 'getUser'
server.post '/users/me', server.session.getMiddleware 'login'
server.delete '/users/me', server.session.getMiddleware 'logout'
server.get '/session/loginCheck', server.session.getMiddleware 'isLoggedIn'

# Shared middleware.
ensureLogin = server.session.getMiddleware 'ensureLogin'
ensureOwnership = server.session.getMiddleware 'ensureOwnership'

# Route: Set up entry REST routes.
server.db.Entry.methods ['get', 'post', 'put', 'delete']
server.db.Entry.before 'get', ensureOwnership
server.db.Entry.before 'post', ensureOwnership
server.db.Entry.before 'put', ensureOwnership
server.db.Entry.before 'delete', ensureOwnership
server.db.Entry.register server, '/entries'

# Route: Set up tag REST routes.
server.db.Tag.methods ['get', 'post', 'put', 'delete']
server.db.Tag.before 'get', ensureOwnership
server.db.Tag.before 'post', ensureOwnership
server.db.Tag.before 'put', ensureOwnership
server.db.Tag.before 'delete', ensureOwnership
server.db.Tag.register server, '/tags'

# Start listening on the server port.
server.listen config.serverPort if config.serverPort


##
## PROXY
##

# Create a super simple "proxy" server.
proxy = http.createServer (req) ->
  root = config.domainName
  switch req.headers.host.split(':')[0]
    when root, "www.#{root}" then client arguments...
    when "api.#{root}" then server arguments...

# Attempt to listen on the HTTP port.
proxy.listen config.httpPort if config.httpPort

# Export our servers.
module.exports = {client, server, proxy}
