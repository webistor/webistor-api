mongoose = require 'mongoose'
{Schema} = mongoose
{ObjectId} = Schema.Types
Auth = require './classes/auth'
config = require './config'
validateEmail = require 'rfc822-validate'

##
## SCHEMA DEFINITIONS
##

# Export Schemas.
schemas =

  # The User schema.
  User: new Schema
    email:    type: String, required: true, unique: true, lowercase: true, validate: [
      validateEmail, "given email address is not valid"
    ]
    username: type: String, required: true, unique: true, lowercase: true, match: /^[\w-_]{4,48}$/
    password: type: String, required: true, select: false, match: /^.{4,48}$/
    friends:  type: [ObjectId], ref: 'user'

  # The Group schema.
  Group: new Schema
    author:  type: ObjectId, ref: 'user', required: true, index: true
    members: type: [ObjectId], ref: 'user'

  # The Entry schema.
  Entry: new Schema
    author:       type: ObjectId, ref: 'user', required: true, index: true
    created:      type: Date, default: Date.now
    lastModified: type: Date, default: Date.now
    userShare:    type: [ObjectId], ref: 'user'
    groupShare:   type: [ObjectId], ref: 'group'
    publicShare:  type: Boolean, default: false
    title:        type: String, trim: true, match: /^.{1,255}$/
    url:          type: String
    description:  type: String
    tags:         type: [ObjectId], ref: 'tag'

  # The Tag schema.
  Tag: new Schema
    author: type: ObjectId, ref: 'user', index: true
    title:  type: String, trim: true, match: /^[\w\s]{1,255}$/
    color:  type: String, match: /^[0-9A-F]{6}$/
    # Warning! The following property can stale and should therefore not be relied upon.
    num:    type: Number, default: 0


##
## EXTRA
##

# Add user password hashing middleware.
schemas.User.pre 'save', Auth.Middleware.hashPassword()

# Add text indexes for text-search support.
schemas.Entry.index {title:'text', description:'text'}, {default_language: 'en'}

# This method can be relied upon to return the actual number of entries.
schemas.Tag.method 'getNum', (cb) -> @model('tag').count {tags:@id}, cb

##
## MODELS
##

# Create and export models.
models = {mongoose}
models[key] = mongoose.model key.toLowerCase(), schema for own key, schema of schemas
module.exports = models
