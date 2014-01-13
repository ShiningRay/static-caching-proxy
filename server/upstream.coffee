machina = require 'machina'

Upstream = machina.Fsm.extends
  initialState: "up"
  states:
    down:
      start: ->
    up:
      start: ->