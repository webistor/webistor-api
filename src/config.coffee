module.exports =
  domainName: 'webistor.net'
  clientPort: null
  serverPort: null
  debug: false
  logLevel: ['debug', 'info', 'error'][0]
  timezone: 'Europe/Amsterdam'
  publicHtml: '/absolute/path/to/public'
  whitelist: ['localhost', 'webistor.net', 'www.webistor.net']

  # Database settings.
  database:
    host: 'localhost'
    name: 'webistor'

  # Session settings.
  sessions:
    secret: 'sesamopenu',
    lifetime: 1000*60*60*24

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

  # Daemon settings.
  daemon:
    enabled: true
    httpPort: 80
    adminPort: 3002
    uid: 'node'
    gid: 'node'
