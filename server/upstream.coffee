machina = require 'machina'
{EventEmitter} = require 'events'

class Upstream extends EventEmitter
  initialState: "up"
  states:
    down:
      start: ->
    up:
      start: ->