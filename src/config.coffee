module.exports =
  domainName: 'webistor.net'
  clientPort: 3000
  serverPort: 3001
  httpPort: null
  debug: false
  timezone: 'Europe/Amsterdam'
  publicHtml: '../ui/public'
  database: 'mongodb://localhost/webistor'
  logLevel: 'debug'
  whitelist: ['localhost', 'webistor.net']
  sessionKeys: ['sesamopenu']

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
