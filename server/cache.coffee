_              = require 'underscore'
pathUtil       = require 'path'
mkdirp         = require('mkdirp')
fs             = require 'fs'
w              = require 'when'
callbacks      = require 'when/callbacks'
nodefn         = require 'when/node/function'
moment         = require('moment')
{EventEmitter} = require 'events'
ReadWriteLock = require('rwlock')
querystring = require 'querystring'
cacheBase = '/tmp/cache'
exports.cachePath = cachePath = (path, next) ->

  path = '/' if path == ''
  if path.substr(path.length-1) == '/'
    path = pathUtil.join path, 'index.html'
  path = pathUtil.join cacheBase, path
  path = querystring.unescape(path.replace(/[:?"*<>|]/g, '_')).replace('&amp;','&') # remove illegal character under windows
  dir = pathUtil.dirname path
  name = pathUtil.basename path
  # ext = pathUtil.extname name
  # if ext == ''
  #   path += '.html'
  # if ext == '.'
  #   path += 'html'
  mkdirp dir, (err, made) ->
    #throw err if err
    console.log if err
    next path

exports.setBase = (dir) ->
  cacheBase = dir

writeFile = nodefn.lift fs.writeFile
readFile = nodefn.lift fs.readFile

#hacks for fs-mock
if fs.constructor.toString() != 'function Object() { [native code] }'
  writeFile = (f) ->
    w = nodefn.lift fs.writeFile
    w.call(fs, f)
  readFile = (f) ->
    r = nodefn.lift fs.readFile
    r.call(fs, f)
defaultExpiresIn = moment.duration("30:00")

class CacheEntry
  constructor: (@key, @value, @options={}) ->
    @options.created_at ?= moment @options.created_at
    unless moment.isMoment(@options.expires_at)
      @options.expires_at = moment(@options.expires_at)
    if @options.expires_at.isBefore()
      @options.expires_at = moment().add(defaultExpiresIn)
    @options.length = parseInt(@options.length)
    @options.length = @value.length if _.isNaN(@options.length)

  isExpired: ->
    @options.expires_at and @options.expires_at.isBefore()

  isValid: ->
    _.all([@options.created_at.isValid(),
           @options.expires_at.isValid(),
           @options.length and not _.isNaN(@options.length),
           @options.length == @value.length
          ], _.identity)

CacheStore = new EventEmitter
exports.CacheStore = CacheStore
exports.CacheEntry = CacheEntry
lock = new ReadWriteLock
readLock = callbacks.lift (key, cb) ->
  lock.readLock(key, cb)
writeLock = callbacks.lift (key, cb) ->
  lock.writeLock(key, cb)
_.extend CacheStore,
  locks: {}
  waiters: {}
  cachePath: cachePath
  fetchQ: (key) ->
    #@locks[key] = _.uniqueId('c')
    self = this
    callbacks.call(cachePath, key).then (path) ->
      w.all([
        # readLock(path),
        readFile(path),
        readFile("#{path}.meta")
      ]).then (all) ->
        [value, meta] = all
        # [release, value, meta] = all
        meta = JSON.parse(meta)
        meta.created_at = moment(meta.created_at)
        meta.expires_at = moment meta.expires_at
        entry = new CacheEntry(key, value, meta)
        # for waiting in waiters[key]
        #   waiting.got key, entry
        # release()
        process.nextTick( -> self.emit('fetched', key, entry))
        entry
  fetch: (key, got) ->
    lock.readLock key, (release) =>
      @fetchQ(key).then (entry) ->
        release()
        got(null, entry)
      , (err) ->
        release()
        got(err)

  storeQ: (key, entry) ->
    self = this
    callbacks.call(cachePath, key).then (path) ->
      w.all([
        # writeLock(path),
        writeFile(path, entry.value),
        writeFile("#{path}.meta", JSON.stringify(entry.options))
      ]).then((all) ->
        process.nextTick( -> self.emit('stored', key, entry))
        all[0]() if typeof all[0] is 'function'
      )
  store: (key, entry, written) ->
    written ?= ->
    lock.writeLock key, (release) =>
      @storeQ(key, entry).then (all) ->
        release()
        written(null)
      , (err) ->
        release()
        written(err)
  writeQ: (key, value, options={}) ->
    @storeQ(key, new CacheEntry(key, value, options))

  write: (key, value, options, written) ->
    if typeof options is 'function'
      written = options
      options = {}

    @store(key, new CacheEntry(key, value, options), written)

if not module.parent
  key = 'aaaa/bbbb'
  # e = new CacheEntry(key, 'aaaaaaabbbb', {expires_at: new Date()})

  # console.log(e.isExpired())
  # console.log(e.size())
  #CacheStore.store(key, e, (err) -> console.log(err.stack))
  CacheStore.write(key, 'vvvvvvvv', (err) -> console.log(err))
  # setTimeout ->
  #   CacheStore.fetch key, (err, entry) ->
  #     console.log(err)
  #     console.log(entry.value.toString())
  # , 1000
