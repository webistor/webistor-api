Controller = require './base/controller'
Promise = require 'bluebird'
config = require '../config'
ServerError = require './base/server-error'
log = require 'node-logging'
{User, Tag, Entry} = require '../schemas'
_ = require 'lodash'

Promise.promisifyAll User
Promise.promisifyAll User.prototype
Promise.promisifyAll Tag
Promise.promisifyAll Tag.prototype
Promise.promisifyAll Entry
Promise.promisifyAll Entry.prototype

module.exports = class EntryController extends Controller

  constructor: ->
    @dirtyTags = {}

  ###*
   * Uses the given query parameters to perform an extensive search of entries.
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A promise of the found entries.
  ###
  search: (req) ->

    # Gather input.
    options = req.query.options or {}
    search = @_parseSearchQuery req.query.query or ''
    language = req.query.ln
    conditions = []

    # Text search?
    if search.search.length > 0
      ts = {$search:search.search}
      ts.$language = language if language?
      conditions.push {$text:ts}

    # Ensure the user will have access to every result.
    conditions.push {$or:[
      {author: req.session.userId}
      {publicShare: true}
      {userShare: req.session.userId}
    ]}

    # Filter by URI?
    conditions.push {url:options.uri} if options.uri?

    # Find author ID's.
    authorPromise = Promise.try ->

      # If the special $all group is given, don't filter by any authors.
      return false if 'all' in search.groups

      # Start with no author ID's.
      authors = []

      # Handle special @me user.
      if 'me' in search.users
        search.users.splice search.users.indexOf('me'), 1
        authors.push req.session.userId

      # Add specific authors.
      userPromise = User.findAsync {username:$in:search.users}, '_id', {lean:true}
      .then (users) -> authors.push id for id in users.map (u) -> u._id

      # Find the friends of the user.
      friendsPromise = User.findByIdAsync req.session.userId, 'friends', {lean:true}
      .get 'friends'

      # Handle special $friends group.
      if 'friends' in search.groups
        search.groups.splice search.groups.indexOf('friends'), 1
        friendsPromise = friendsPromise.then (friends) ->
          authors.push id for id in friends
          return friends

      # Add authors from groups.
      # groupPromise = Group.findAsync {author:req.session.userId, name:$in:search.groups}, {lean:true}
      # .then (groups) -> authors.push id for id in users for users in groups.map (g) -> g.users

      # Once all the work is done.
      Promise.join friendsPromise, userPromise

      # Resolve with all unique author IDs. If none are present, set defaults.
      .spread (friends) ->

        # If authors aren't yet filtered, set default filters to @me and $friends.
        unless authors.length > 0
          authors.push req.session.userId
          authors.push id for id in friends

        # Ensure all duplicates are removed.
        authors = _.uniq authors

        # Return the resulting authors.
        return authors

    # Add a condition to filter by authors if needed.
    .then (authors) ->
      conditions.push {author:$in:authors} unless authors is false

    # Find tag ID's.
    tagPromise = Promise.try ->
      return false unless search.tags.length > 0
      tagConditions = {author:req.session.userId, title:$in:search.tags}
      tagConditions.$text = ts if ts?
      Tag.findAsync tagConditions, {lean:true}
      .then (tags) -> tags.map (t) -> t._id

    # Add a condition to filter by tags if needed.
    .then (tags) ->
      conditions.push {tags:$all:tags} if tags.length > 0

    # Once all condition building has been done..
    Promise.join authorPromise, tagPromise

    # Execute the database query.
    .then ->
      q = Entry.find {$and: conditions}
      q.sort '-created'
      q.limit options.limit if options.limit?
      q.exec()

  ###*
   * Throw an error if req.body.url is already used by an entry.
   *
   * @method ensureUniqueURI
   *
   * @param {http.IncomingMessage} req The Express request object.
   *
   * @return {Promise} A promise of the found entries.
  ###
  ensureUniqueURI: (req) ->
    return unless req.body.url?.length > 0
    Entry.findOneAsync {url:req.body.url, author:req.session.userId}
    .then (result) ->
      return if not result or result.id is req.body._id
      throw new ServerError 400, "The URI specified is already in use by one of your other entries."

  ###*
   * Analyze a request body to detect what which tags will change as a result of the request.
   *
   * @method detectDirtyTags
  ###
  detectDirtyTags: (req, res) ->
    _toString = (tag) -> tag.toString()
    return switch req.method.toLowerCase()
      when 'post'
        req.dirtyTags = req.body.tags
        null
      when 'delete'
        Promise.promisify(req.quer.findOne, req.quer)()
        .then (entry) -> req.dirtyTags = entry.get('tags').map _toString
        .return null
      when 'put'
        Promise.promisify(req.quer.findOne, req.quer)()
        .then (entry) ->
          req.dirtyTags = _.xor req.body.tags, entry.get('tags').map _toString
        .return null
      else null

  ###*
   * Store previously found dirty tags.
   *
   * @method cacheDirtyTags
  ###
  cacheDirtyTags: (req, res) ->
    return if res.locals.bundle instanceof Error
    return null unless req.dirtyTags?.length > 0
    log.dbg "Flagging #{req.dirtyTags.length} tags as dirty for user #{req.session.userId}."
    cache = @dirtyTags[req.session.userId] or= []
    cache.push tag for tag in req.dirtyTags when tag not in cache
    return null

  ###*
   * Ensure the tags of the currently logged in user are no longer dirty by recalculating
   * the "num" property.
   *
   * @method updateDirtyTags
  ###
  updateDirtyTags: (req, res) ->

    # Reference the cache of the logged in user.
    cache = @dirtyTags[req.session.userId]

    # Skip all of this if the author doesn't have any dirty tags right now.
    return unless cache?.length > 0

    # Log.
    log.dbg "Cleaning up #{cache.length} dirty tags for user #{req.session.userId}."

    # Iterate all the dirty tags of this author, mapping them to the promises of their resolution.
    Promise.map cache, (id) =>
      tag = null
      Tag.findByIdAsync id
      .then (result) ->
        tag = result
        tag.countTimesUsedAsync()
      .then (timesUsed) =>
        return tag.removeAsync() if timesUsed is 0
        tag.set 'num', timesUsed
        tag.saveAsync()
      .then ->
        cache.splice cache.indexOf(id), 1

    # Wait for all promises to resolve.
    .all()

    # No longer flag these tags as dirty.
    .then => delete @dirtyTags[req.session.userId] if cache?.length is 0

    # No return value.
    .return null

  ###*
   * Parses a search-query.
   *
   * @param {String} query A search query.
   *
   * @return {Object} The result of the query analysis.
  ###
  _parseSearchQuery: (query) ->

    # Initiate variables.
    tags = []
    users = []
    groups = []
    indexes = []
    search = ''

    # Parse the search query.
    for value in query.trim().split ' '
      value = value.trim()
      continue if value is ''
      if value.length > 1 then switch value.charAt 0
        when '#' then v = value.slice 1; tags.push v unless v in tags
        when '@' then v = value.slice 1; users.push v unless v in users
        when '$' then v = value.slice 1; groups.push v unless v in groups
        when ':' then v = value.slice 1; indexes.push v unless v in indexes
        else search += " #{value}"
      else search += " #{value}"

    # Is empty?
    empty = (
      search is '' and tags.length is 0 and users.length is 0 and
      groups.length is 0 and indexes.length is 0
    )

    # Return the results.
    {query, tags, users, groups, search, indexes, empty}
