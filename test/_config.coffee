require('bluebird').longStackTraces()
module.exports = config = require '../src/config'
config.domainName = 'localhost'
config.clientPort = null
config.serverPort = null
config.daemon = null
config.database = host:'localhost', name:'webistor-test'
config.logLevel = 'debug'
config.debug = true
