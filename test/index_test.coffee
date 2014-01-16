rewire = require 'rewire'
server = rewire '../server/index'

describe '#revalidate', ->
  server.__get__ 'revalidate'
  it '', ->