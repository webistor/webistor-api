http = require 'http'
express = require 'express'
Promise = require 'bluebird'
config = require './config'
log = require 'node-logging'
AuthFactory = require './classes/auth-factory'
SessionController = require './controllers/session-controller'

##
## SHARED
##

# Create shared middleware.
favicon = express.favicon "#{config.publicHtml}/icons/favicon.ico"

# Set up logging.
Promise.onPossiblyUnhandledRejection -> log.dbg 'Supressing PossiblyUnhandledRejection.'
Promise.longStackTraces() if config.logLevel is 'debug'
log.setLevel config.logLevel


##
## CLIENT
##

# Instantiate client application-server.
client = express()

# Set up shared middleware.
client.use favicon

# Set up routing to serve up static files from the /public folder, or index.html.
client.use express.static config.publicHtml
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
      res.header 'Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE'
      res.header 'Access-Control-Allow-Headers', req.headers['access-control-request-headers']
  next()

# Set up shared middleware.
# server.use favicon

# Parse request body as JSON.
server.use express.json()

# Set up session support.
server.use express.cookieParser();
server.use express.cookieSession secret: config.sessionSecret, cookie: maxAge: 60 * 60 * 1000

# Send OPTIONS response at this point.
server.use (req, res, next) ->
  if req.method is 'OPTIONS' then res.send() else next()

# Import database schemas.
server.db = require './schemas'
server.db.mongoose.connect config.database

# Instantiate controllers.
server.session = new SessionController new AuthFactory

# Route: Set up authentication related routes.
server.get '/users/me', server.session.getMiddleware 'getUser'
server.post '/users/me', server.session.getMiddleware 'login'
server.delete '/users/me', server.session.getSyncMiddleware 'logout'
server.get '/session/loginCheck', server.session.getSyncMiddleware 'isLoggedIn'

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
