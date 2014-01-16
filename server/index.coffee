_              = require 'underscore'
http           = require('http')
httpProxy      = require 'http-proxy'
fs             = require 'fs'
pathUtil       = require 'path'
#Sequelize     = require("sequelize")
util           = require 'util'
urlUtil=url    = require('url')
streamBuffers  = require("stream-buffers")
nodefn         = require("when/node/function")
{CacheStore}   = require './cache'
{EventEmitter} = require 'events'
Stream         = require 'stream'
{fork}         = require 'child_process'
target =
  hostname: 'buy.rongyi.com',
  port: 80,

formatUrl = (url) ->
  parsed = urlUtil.parse(url)
  parsed.protocol ?= 'http'
  parsed.hostname ?= target.hostname
  parsed.port ?= target.port
  delete parsed.port if parsed.port == 80
  urlUtil.format(parsed)
storeHook = (url, res, options={}) ->
  _write    = res.write
  _end      = res.end
  tmpBuffer = new streamBuffers.WritableStreamBuffer

  # intercept write and end to duplicate stream content
  res.write = (chunk, encoding, cb) ->
    tmpBuffer.write(chunk, encoding, cb)
    _write.call(res, chunk, encoding, cb)

  res.end = (chunk, encoding, cb) ->
    if chunk
      tmpBuffer.end(chunk, encoding, cb)
    else
      tmpBuffer.end()
    _end.call(res, chunk, encoding, cb)

  res.on 'finish',  ->
    console.log 'finished Upstream Response'

    process.nextTick ->
      expires = res.getHeader('expires')
      #console.log res.getHeader('cache-control')
      last_modified = res.getHeader('last-modified') || res.getHeader('date')
      etag = last_modified = res.getHeader('etag')
      content_type = res.getHeader('content-type')
      content = tmpBuffer.getContents()
      CacheStore.write url, content , {
        expires_at: expires,
        created_at: last_modified
        etag: etag
        content_type: content_type
        length: res.getHeader('content-length')
        }, (err) ->
        #throw err if err
        tmpBuffer.destroy()
        if err
          console.log err
        else
          console.log 'finish writing to cache file', url
store = (url, res, options={}) ->
  CacheStore.write url, res, options, (err) ->
    #throw err if err
    if err
      console.log err
    else
      console.log 'finish writing to cache file'
    res.destory() if res.destory

revalidate = (url, entry, headers={}) ->
  console.log 'revalidating', url
  p = urlUtil.parse(url)
  headers = _.clone(headers)
  options = _.defaults({
    method: 'GET',
    headers: headers,
    path: p.path
  }, target)

  if entry and entry.isValid()
    if entry.options.created_at
      headers['If-Modified-Since'] = \
        entry.options.created_at.toDate().toUTCString()

    headers['If-None-Match'] = entry.options.etag if entry.options.etag
  else
    headers['cache-control'] = 'no-cache'

  outgoing = http.request options, (upstream) ->
    console.log 'revalidate result', url, upstream.statusCode
    if upstream.statusCode == 304
      # not modified
      console.log outgoing.path, 'not modified'
    else
      tmpBuffer = new streamBuffers.WritableStreamBuffer
      upstream.resume()
      upstream.pipe tmpBuffer
      upstream.on 'end', ->
        content = tmpBuffer.getContents()
        #console.log(content.toString())
        h = upstream.headers
        store url, content,
          created_at: h['last-modified'] || h.date
          expires_at: h.expires
          etag: h.etag
          content_type: h['content-type']
          length: h['content-length']

        tmpBuffer.destroy()
      .on 'error', (err) ->
        console.log err
      .on 'clientError', (err) ->
        console.log err

  .on 'error', (e) ->
    console.log('problem with request: ' + e.message)
  .end()

pass = (req, res, proxy) ->
  buffer = httpProxy.buffer(req)
  proxy.proxyRequest(req, res,
    host: target.hostname
    port: target.port
    buffer: buffer)

cachable = (req) ->
  req.method is 'GET'

startPrefetcher = ->
  options = {}
  if process.execArgv.indexOf('--debug') > -1
    options.execArgv = ['--debug=5859']
  child = fork __dirname+'/prefetcher.js', [], options

  CacheStore.on 'stored', (key, entry) ->
    console.log 'stored', key
    if child.connected
      if (entry.options.content_type || key).indexOf('html') > -1
        # only analyze html
        CacheStore.cachePath key, (path) ->
          child.send
            path: path
            url: key

  child.on 'message', (url) ->
    # console.log 'from child', url
    u = urlUtil.parse(url)
    delete u.hash
    url = urlUtil.format(u)
    # only prefetch the things we are interested in
    if u.hostname == target.hostname
      CacheStore.fetch url, (err, entry) ->
        if err or !entry
          revalidate(url, entry)


unless module.parent
  proxyServer = httpProxy.createServer((req, res, proxy) ->
    if cachable(req)
      url = formatUrl req.url
      console.log 'receive requst', url
      CacheStore.fetch url, (err, entry) ->
        #throw err if err
        if not err and entry
          # hit
          console.log 'find cache', entry.key
          res.setHeader('Content-Type', entry.options.content_type) if entry.options.content_type
          res.setHeader('Etag', entry.options.etag) if entry.options.etag
          res.setHeader('Date', entry.options.created_at.toDate().toUTCString()) if entry.options.created_at
          res.setHeader('Content-Length', entry.value.length)
          res.statusCode = 200
          res.end(entry.value)
          if entry and entry.isExpired()
            revalidate(url, entry, req.headers)
          else
            console.log 'not expired', entry.key
          proxyServer.emit 'hit', req, data
          # TODO revalidate in background
          # revalidate(req, proxy) if outdated # now > expired_at
        else
          # miss
          # don't proxy cache headers
          req.headers['host'] = "#{target.hostname}:#{target.port||80}"
          delete req.headers['accept-encoding']
          delete req.headers['if-modified-since']
          delete req.headers['if-none-match']
          storeHook(url, res)  # hook to store
          pass(req, res, proxy)
          proxyServer.emit 'miss', req
    else
      pass(req, res, proxy)
  ).listen(8000, 'localhost').on 'upgrade', (req, socket, head) ->
    proxyServer.proxy.proxyWebSocketRequest(req, socket, head)
  .on 'hit', (req, data) ->
    console.log('hit', req.url)
  .on 'miss', (req) ->
    console.log 'miss', req.url

  # aaa
  startPrefetcher()

