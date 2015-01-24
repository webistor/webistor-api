module.exports =
  debug: false
  logLevel: ['debug', 'info', 'error'][0]
  
  domainName: 'webistor.net'
  timezone: 'Europe/Amsterdam'
  clientPort: null
  serverPort: null
  
  stableHtml: '/home/node/webistor/app-stable/public/'
  newHtml: '/home/node/webistor/app-new/public/'
  
  # For Content Security Policy
  whitelist: ['localhost', 'webistor.net', 'www.webistor.net', 'new.webistor.net']

  # Database settings.
  database:
    host: 'localhost'
    name: 'webistor'

  # Authentication settings.
  authentication:
    secret: 'sesamopenu',
    sessionLifetime: 1000*60*60*24
    persistentCookieLifetime: 1000*60*60*24*14

  # The release stage is used mainly for access control.
  releaseStage: ['alpha', 'privateBeta', 'openBeta', 'publicBeta', 'postRelease'][1]

  # The maximum amount of email addresses that any user is allowed invite to the open beta.
  maxUserInvitations: 5

  # NodeMailer transport options.
  # See: https://github.com/andris9/Nodemailer#setting-up-a-transport-method
  mail:
    type: 'sendmail'
    options: path: '/usr/sbin/sendmail'

  # An array of usernames which users are not allowed to take.
  reservedUserNames: ['me']

  # Proxy settings.
  proxy:
    enabled: true
    httpPort: 80
    adminPort: 3002
    uid: 'node'
    gid: 'node'
