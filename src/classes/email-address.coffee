addressParser = require 'address-rfc2822'
validateAddress = require 'rfc822-validate'

###*
 * Wrapper class for the address-rfc2822 Address object which adds validation.
###
module.exports = class EmailAddress

  ###*
   * Normalizes given input and return an array of new EmailAddress objects.
   *
   * When given a string, a comma-separated list of email addresses is assumed. When given
   * an object its `email` property will be used. When given an array, every value is
   * normalized and any sub-arrays are flattened.
   *
   * @param {Object} input The recipients to be normalized.
   *
   * @return {[EmailAddress]} An array of EmailAddress objects.
  ###
  @create: (input) ->

    # Determine the type.
    type = (
      if input instanceof EmailAddress then 'email'
      else if input instanceof Array then 'array'
      else typeof input
    )

    # Normalize based on the type.
    return switch type
      when 'email' then [input]
      when 'array' then input.reduce ((a, b) => a.concat EmailAddress.create b), []
      when 'object' then EmailAddress.create input.email
      when 'string' then (addressParser.parse input).map (a) -> new EmailAddress a
      else throw new Error "Could not parse recipients."

  address: null

  ###*
   * Constrct a new EmailAddress.
   *
   * @param {String} address An address-rfc2822-module Address object.
  ###
  constructor: (@address) ->

  ###*
   * Casting this to a string will return the reformatted email address.
   *
   * @return {String}
  ###
  toString: ->
    @format()

  ###*
   * Get the plain email address.
   *
   * @return {String}
  ###
  getAddress: ->
    @address.address

  ###*
   * Reformat from parsed input.
   *
   * @return {String}
  ###
  format: ->
    @address.format()

  ###*
   * Get the guessed name from the phrase or the comment section of the address.
   *
   * @return {String}
  ###
  getName: ->
    @address.name()

  ###*
   * Get the part before the @-sign.
   *
   * @return {String}
  ###
  getUser: ->
    @address.user()

  ###*
   * Get the part after the @-sign.
   *
   * @return {String}
  ###
  getHost: ->
    @address.host()

  ###*
   * Return true if the address complies with rfc-822.
   *
   * @return {Boolean}
  ###
  isValid: ->
    validateAddress @getAddress()

  ###*
   * Return true if both addresses are the same.
   *
   * @param {EmailAddress|String} address The EmailAddress or string to compare to.
   *
   * @return {Boolean}
  ###
  equals: (address) ->
    email = if address instanceof EmailAddress then address else new EmailAddress address
    return email.getAddress() is @getAddress()
