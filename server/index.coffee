_              = require 'underscore'
http           = require('http')
httpProxy      = require 'http-proxy'
fs             = require 'fs'
pathUtil       = require 'path'
#Sequelize     = require("sequelize")
util           = require 'util'
url            = require('url')
streamBuffers  = require("stream-buffers")
nodefn         = require("when/node/function")
{CacheStore}   = require './cache'
{EventEmitter} = require 'events'
Stream         = require 'stream'

target =
  hostname: 'nodejs.org',
  port: 80,

store = (url, res, options={}) ->
  if res instanceof Stream
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

      setTimeout ->
        expires = res.getHeader('expires')
        #console.log res.getHeader('cache-control')
        last_modified = res.getHeader('last-modified') || res.getHeader('date')
        etag = last_modified = res.getHeader('etag')

        CacheStore.write url, tmpBuffer.getContents(), {
          expires_at: expires,
          created_at: last_modified
          etag: etag
          }, (err) ->
          #throw err if err
          tmpBuffer.destroy()
          if err
            console.log err
          else
            console.log 'finish writing to cache file'
  else
    CacheStore.write url, res, options, (err) ->
      #throw err if err
      if err
        console.log err
      else
        console.log 'finish writing to cache file'
      res.destory() if res.destory

revalidate = (req, entry) ->
  # req.setHeader 'If-Modified-Since'
  console.log 'revalidating', req.url
  p = url.parse(req.url)
  options = _.defaults({
    method: 'GET',
    headers: req.headers,
    path: p.path
  }, target)

  if entry and entry.isValid()
    if entry.options.created_at
      options.headers['If-Modified-Since'] = \
        entry.options.created_at.toDate().toUTCString()

    options.headers['If-None-Match'] = entry.options.etag if entry.options.etag
  else
    options.headers['cache-control'] = 'no-cache'
  console.log options
  outgoing = http.request options, (upstream) ->
    console.log 'revalidate result', req.url, upstream.statusCode
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
        store req.url, content,
          created_at: h['last-modified'] || h.date
          expires_at: h.expires
          etag: h.etag

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

debug = (proxy) ->
  proxy.on('start', (req, res, target) ->
    console.log 'starting', req.url
  ).on( 'forward', (req, res, forward) ->
    console.log 'forwarding', req.url
  ).on('proxyResponse', (req, res, upstream) ->
    console.log 'response', req.url
  ).on('end', (req, res, upstream) ->
    console.log 'ending', req.url
  )

cachable = (req) ->
  req.method is 'GET'

proxyServer = httpProxy.createServer((req, res, proxy) ->
  if cachable(req)
    console.log 'receive requst', req.url
    CacheStore.fetch req.url, (err, entry) ->
      #throw err if err
      console.log 'find cache', err
      data = entry?.value
      if not err and data.length > 0
        # hit
        res.end(data)
        if entry and entry.isExpired()
          revalidate(req, entry)
        else
          console.log 'not expired', entry.key
        proxyServer.emit 'hit', req, data
        # TODO revalidate in background
        # revalidate(req, proxy) if outdated # now > expired_at
      else
        # miss
        store(req.url, res)  # hook to store
        pass(req, res, proxy)
        proxyServer.emit 'miss', req
  else
    pass()
).listen(8000, 'localhost').on 'upgrade', (req, socket, head) ->
  proxyServer.proxy.proxyWebSocketRequest(req, socket, head)
.on 'hit', (req, data) ->
  console.log('hit', req.url)
.on 'miss', (req) ->
  console.log 'miss', req.url

orignalServer = http.createServer( (req, res) ->
  res.writeHead(200, { 'Content-Type': 'text/plain' })
  res.write("request successfully proxied: #{req.url}
    #{JSON.stringify(req.headers, true, 2)}")
  res.end()
).listen 9000
