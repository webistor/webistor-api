module.exports = config = require '../src/config'
config.clientPort = false
config.serverPort = false
config.httpPort = false
config.database = 'mongodb://localhost/webistor-test'
config.logLevel = 'critical'
