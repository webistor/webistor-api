express = require 'express'
serveStatic = require 'serve-static'
staticFavicon = require 'static-favicon'

###*
 * Creates a new client, static file host.
 * @param  {object} config  Dependency injection of the configuration values.
 *                          See `/config.coffee`.
 * @param  {object} opts    Holds the options for this client.
 *                          - html: the location of local files to serve.
 *                          - port: (optional) the port to listen on directly.
 * @return {Express}        The created client express instance.
###
module.exports = (config, opts) ->

  # Favicon middleware.
  favicon = staticFavicon "#{opts.html}/icons/favicon.ico"

  # Instantiate client application-server.
  client = express()

  # Content Security Policy.
  client.use (req, res, next) ->

    # Arrays of whitelisted domains for styles and fonts.
    styleDomains = ['fonts.googleapis.com', 'netdna.bootstrapcdn.com']
    fontDomains = ['themes.googleusercontent.com', 'netdna.bootstrapcdn.com', 'fonts.gstatic.com']

    # Chrome implemented CSP properly.
    if /Chrome/.test req.headers['user-agent']
      styles = styleDomains.join(' ')
      fonts = fontDomains.join(' ')

    # Others didn't.
    else
      styles =
        styleDomains.map((domain) -> "http://#{domain}").join(' ') + ' ' +
        styleDomains.map((domain) -> "https://#{domain}").join(' ')
      fonts =
        fontDomains.map((domain) -> "http://#{domain}").join(' ') + ' ' +
        fontDomains.map((domain) -> "https://#{domain}").join(' ')

    # Send the CSP header.
    res.header 'Content-Security-Policy', [
      "default-src 'none'"
      "style-src 'self' 'unsafe-inline' " + styles
      "font-src 'self' " + fonts
      "script-src 'self' 'unsafe-eval'"
      "img-src 'self'"
      "connect-src api.#{config.domainName}:#{config.proxy.httpPort}" + (
        if config.debug then " ws://localhost:9485/ localhost:#{config.serverPort}" else ''
      )
    ].join(';\n')

    # Next middleware.
    next()

  # Set up shared middleware.
  client.use favicon

  # Set up routing to serve up static files from the /public folder, or index.html.
  client.use serveStatic opts.html
  client.get '*', (req, res) -> res.sendFile "#{opts.html}/index.html"

  # Start listening on the client port, if any.
  client.listen opts.port if opts.port
  
  # Return the express instance.
  return client
