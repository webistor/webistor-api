log = require 'node-logging'
Promise = require 'bluebird'

countTagsTimesUsed = require './tasks/count-tags-times-used'
config = require './config'
client = require './client'
server = require './server'
proxy = require './proxy'

##
## SHARED
##

# Set up logging.
# Promise.onPossiblyUnhandledRejection -> log.dbg 'Supressing PossiblyUnhandledRejection.'
Promise.longStackTraces() if config.logLevel is 'debug'
log.setLevel config.logLevel

##
## CLIENTS
##

# Instantiate stable client application-server.
stableClient = client config,
  html: config.stableHtml
  port: config.clientPort

# Instantiate new client application-server, when in production mode.
unless config.debug
  newClient = client config,
    html: config.newHtml
    port: false

##
## SERVER
##

# Instantiate API server.
apiServer = server config, {}

##
## Proxy
##

# Only perform proxy related setup if enabled.
if config.proxy?.enabled

  # Better not have debug mode enabled past this point.
  log.err "WARNING: Ensure debug mode is disabled in a production environment." if config.debug
  
  # Create a simple "proxy" server which will forward requests made to the proxy port
  # to the right express server.
  
  opts =
    stableClient: stableClient
    apiServer: apiServer
  
  opts.newClient = newClient unless config.debug
  
  {proxyServer, adminServer} = proxy config, opts
  
##
## MAIN
##

log.dbg "Counting the usage times on all tags..."
countTagsTimesUsed()
.catch (err) -> log.err "Failed counting tags: #{err}"
.done -> log.dbg "Finished counting tags."

##
## EXPORTS
##

# Export our servers when in debug mode.
module.exports = {stableClient, apiServer, proxyServer, adminServer} if config.debug
