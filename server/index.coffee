http = require('http')
httpProxy = require 'http-proxy'
fs = require 'fs'
pathUtil = require 'path'
#Sequelize = require("sequelize")
util = require 'util'
mkdirp = require('mkdirp')
streamBuffers = require("stream-buffers")
#nodefn = require("when/node/function")


cacheBase = '/tmp'
cachePath = (path, next) ->
  if path[-1] == '/'
    path = pathUtil.join path, 'index.html'
  
  path = pathUtil.join cacheBase, path
  dir = pathUtil.dirname path
  name = pathUtil.basename path
  ext = pathUtil.extname name
  if ext == ''
    path += '.html'
  if ext == '.'
    path += 'html'
  mkdirp dir, (err, made) ->
    throw err if err
    next path
      
openCache = (path, cb) ->
  cachePath path, (file) ->
    console.log("open #{file}")
    cb(fs.createWriteStream(file, {flags: 'w'}))

proxy = httpProxy.createServer((req, res, proxy) ->
  url = req.url
  if req.method is 'GET'
    cachePath url, (file) ->
      fs.readFile file, (err, data) ->
        throw err if err
        if data.length > 0
          res.end(data)
        else
          buffer = httpProxy.buffer(req)
          _write = res.write
          _end = res.end
          tmpBuffer = new streamBuffers.WritableStreamBuffer
            initialSize: (100 * 1024)        # start as 100 kilobytes.
            incrementAmount: (10 * 1024)    # grow by 10 kilobytes each 

          res.write = (chunk, encoding, cb) ->
            tmpBuffer.write(chunk, encoding, cb)
            _write.call(res, chunk, encoding, cb)

          res.end = (chunk, encoding, cb) ->
            tmpBuffer.end(chunk, encoding, cb)
            _end.call(res, chunk, encoding, cb)
          

          res.on 'finish',  ->
            console.log 'finish'
            openCache url, (stream) ->
              stream.end tmpBuffer.getContents()
              stream.on 'finish', ->
                console.log 'finished stream'
                tmpBuffer.destroy()
          
          
          proxy.proxyRequest(req, res,
            host: 'localhost',
            port: 9000,
            buffer: buffer)
).listen(8000, 'localhost')

orignalServer = http.createServer( (req, res) ->
  res.writeHead(200, { 'Content-Type': 'text/plain' })
  res.write("request successfully proxied: #{req.url}\n#{JSON.stringify(req.headers, true, 2)}")
  res.end()
).listen 9000
