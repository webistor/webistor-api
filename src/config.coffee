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
  releaseStage: ['alpha', 'closedBeta', 'openBeta', 'postRelease'][1]

  # NodeMailer transport options.
  # See: https://github.com/andris9/Nodemailer#setting-up-a-transport-method
  mail:
    type: 'sendmail'
    options: path: '/usr/sbin/sendmail'
