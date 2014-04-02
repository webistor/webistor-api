http = require 'http'
express = require 'express'
Promise = require 'bluebird'
config = require './config'
log = require 'node-logging'

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
client.listen config.clientPort


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
  next()

# Set up shared middleware.
server.use favicon

# Parse request body as JSON.
server.use express.json()

# Import database schemas.
server.db = require './schemas'

# Route: Set up simple database routes.
# server.db.Entry.methods ['get', 'post', 'put', 'delete']

# Route: Set up authentication related routes.
# server.post 'auth/user', (req, res, next) -> res.send Auth.createUser req.body
# server.post 'auth/session', (req, res, next) -> res.send Auth.createSession req.body

# Start listening on the server port.
server.listen config.serverPort


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
proxy.listen 1337