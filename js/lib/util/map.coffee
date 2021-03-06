require('util/id')
require('util/worker')

exports.Map = class
  constructor: ->
    @data = {}
    @dataIndex = {}
    @size = 0

  keys: ->
    return key for key of @dataIndex

  contains: (key) ->
    id = generateId(key)
    return id of @data

  put: (key, value) ->
    id = generateId(key)
    @data[id] = value
    @dataIndex[id] = key
    @size++

  get: (key) ->
    return @data[generateId(key)]

  removeById: (id) ->
    if id of @data
      delete @data[id]
      delete @dataIndex[id]
      @size--

  remove: (key) ->
    @removeById generateId(key)

  pop: ->
    for id of @dataIndex
      key = @dataIndex[id]
      value = @data[id]
      @removeById(id)
      return [key, value]

  forEach: (f) ->
    for key of @data
      f(@dataIndex[key], @data[key])

  forEachPop: (f) ->
    while @size > 0
      f(@pop()...)

  forEachPopAsync: (f, callback) ->
    worker = new WhileWorker({
      condition: (->
        return @size > 0
      ).bind(this)
      work: (->
        f(@pop())
      ).bind(this)
    }, {
      ondone: callback
    })
    worker.run()
    return worker
