trumpet = require 'trumpet'
fs      = require 'fs'
w       = require 'when'
nodefn  = require 'when/node/function'

unique = (array) ->
    o = {}
    for i in array
    	o[i] = i
    Object.keys(o)

prefetch = (path, cb) ->
	tr      = trumpet()
	queue   = []
	enqueue = (href) -> queue.push(href)
	attrExt = (attr) ->
		(node) ->
			node.getAttribute(attr, enqueue)
	srcAttr  = attrExt 'src'
	hrefAttr = attrExt 'href'

	tr.selectAll 'a', hrefAttr
	tr.selectAll 'link', hrefAttr
	tr.selectAll 'img', srcAttr
	tr.selectAll 'script', srcAttr
	tr.on 'end', ->
		queue = unique(queue)
		#console.log(queue)
		cb(null, queue)
	tr.on 'error', cb
	fs.createReadStream(path).pipe(tr)

prefetchPromise = nodefn.lift prefetch

process.on 'message', (msg) ->
	prefetch msg, (queue) ->
		process.send i for i in queue

if process.argv.length > 2
	w.reduce(prefetchPromise(file) for file in process.argv[2..-1], ((a, b) -> a.concat(b)), []).then((res) ->
		console.log unique(res).join("\n")
	, (err) ->
		console.error err
	)
else
	process.stdin.on 'data', (data) ->
		prefetch data.toString().replace(/[\r\n]*$/, ''), (queue) ->
			process.stdout.write queue.join("\n") + "\n" if queue.length > 0