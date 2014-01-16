FS = require 'fs-mock'
mockery = require 'mockery'
moment = require 'moment'
test_options =
  created_at: new Date(),
  etag: 'a etag'
fs = new FS
  "tmp/cache":
    "index.html": "test"
    "index.html.meta": JSON.stringify(test_options)
mockery.registerMock('fs', fs)
mockery.registerAllowable('../server/cache', true)
CacheStore = null
describe 'CacheStore', ->
  beforeEach =>
    mockery.enable
      useCleanCache: true
    CacheStore = require('../server/cache').CacheStore

  afterEach ->
    mockery.disable()
  describe '#cachePath', ->
    maps =
      '': '/index.html'
      '/': '/index.html'
      '/index': '/tmp/cache/index'
      '/index/': '/tmp/cache/index/index.html'
      '/index/test': '/tmp/cache/index/test'
    for k, v of maps
      it "should map #{k} to #{v}", (done) ->
        CacheStore.cachePath k, (path) ->
          path.should.equal(v)
          done()
  describe '#fetch', ->
    # @timeout(10000)
    it 'should get cache entry', (done) =>
      CacheStore.fetch '/', (err, entry) =>
        return done(err) if err
        try
          entry.should.be.ok
          entry.value.toString().should.equal('test')
          entry.options.etag.should.equal(test_options.etag)
          entry.options.created_at.toDate().toString().should.equal(test_options.created_at.toString())
          done()
        catch e
          done(e)
  # describe '#write', (done) ->
  #   @timeout(10000)


describe 'CacheEntry', ->
  CacheEntry = require( '../server/cache').CacheEntry
  describe '.new', ->
    it 'should be valid', ->
      entry = new CacheEntry('key', 'value')
      entry.key.should.be.equal('key')
      entry.value.should.be.equal('value')
      entry.isValid().should.be.true
      entry.options.length.should.equal('value'.length)
  describe '#isExpired', ->
    it 'should be expired after expires_at', ->
      entry = new CacheEntry 'key', 'value'
      entry.options.expires_at = moment("1984-10-30 10:30:00")
      entry.isExpired().should.be.true
