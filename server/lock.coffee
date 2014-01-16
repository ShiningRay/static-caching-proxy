{EventEmitter} = require 'events'
seq = 0
locks = {}
waiters = {}

lockEvent = new EventEmitter

next = (id) ->
  if waiters[id] and waiters[id].length > 0
    [method, args, scope] = waiters[id].shift()
    method.apply(scope, args)
  else
    delete locks[id]
    delete waiters[id]

# readLock = (method, id, scope) ->

writeLock = (method, id, scope) ->
  (args...) ->
    l = args.length-1
    if typeof args[l] is 'function'
      cb = args[l]
      args.push(cb)
      args[l] = ->
        args[l+1].apply(scope, arguments)
        next(id)
    if locks[id]
      waiters[id] ?= []
      waiters[id].push([method, args, scope])
    else
      locks[id] = id
      method.apply(scope, args)


exports.writeLock = writeLock