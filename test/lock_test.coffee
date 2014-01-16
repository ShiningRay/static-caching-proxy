lock = require '../server/lock'

#simulate race condition

describe '#writeLockAsync', ->
  @timeout(15000)
  resource = []
  fun = (i, cb) ->
    console.log(arguments)
    setTimeout ->
      resource.push(i)
      cb()
    , Math.random()*2000

  it 'should be ordered', (done) ->
    f = lock.writeLock(fun, 'resource')
    for i in [0..4]
      f(i, ->)
    setTimeout ->
      try
        resource.should.eql([0,1,2,3,4])
        done()
      catch e
        done(e)
    , 10000
