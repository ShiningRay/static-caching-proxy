_ = require('underscore')
machina = require('machina')(_)

Upstream = machina.Fsm.extend
  initialState: 'online'
  states:
    online:
      _onEnter: ->
    offine:
      _onEnter: ->