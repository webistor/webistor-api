http = require 'http'
express = require 'express'

###*
 * Creates a new proxy server, internal management requests.
 * @param  {object} config  Dependency injection of the configuration values.
 *                          See `/config.coffee`.
 * @param  {object} opts    Holds the options for this client.
 *                          - stableClient: the express stable client.
 *                          - apiServer: the express server instance.
 *                          - newClient: (optional) the express new client.
 * @return {Express}        The created proxy server.
###
module.exports = (config, opts) ->
  
  proxyServer = http.createServer (req, res) ->
    root = config.domainName
    host = req.headers.host.split(':')[0]
    switch host
      when root
        res.writeHead 301, Location: "http://www.#{root}#{req.url}"
        res.end()
      when "www.#{root}" then opts.stableClient arguments...
      when "new.#{root}" then opts.newClient arguments...
      when "api.#{root}" then opts.apiServer arguments...
      else
        body = "Host #{host} not recognized. This might be due to bad server configuration."
        res.writeHead 400, "Invalid host.", {
          'Content-Length': body.length
          'Content-Type': 'text/plain'
        }
        res.end body

  # Listen on the set http port. Downgrade process permissions once set up.
  proxyServer.listen config.proxy.httpPort, ->
    process.setgid config.proxy.gid
    process.setuid config.proxy.uid
  
  # Create an admin server.
  adminServer = express()
  
  # Bring the application to an idle state.
  adminServer.get '/shutdown', (req, res) ->
    
    closeOrder = []
    closeOrder.push opts.server.db.disconnect
    closeOrder.push opts.server.close
    closeOrder.push opts.stableclient.close
    closeOrder.push opts.newClient.close if opts.newClient?
    closeOrder.push proxyServer.close
    
    closeMethod = ->
      if closeOrder.length > 0
        closer = closeOrder.shift()
        closer(closeMethod)
      else
        res.status(200).end()
    
  # Listen on admin port.
  adminServer.listen config.proxy.adminPort
  
  # Return both servers.
  return {proxyServer, adminServer}
