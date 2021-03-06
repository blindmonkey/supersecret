require('util/id')
require('time/now')
require('util/worker')

exports.Set = class
  constructor: (l) ->
    @items = {}
    @length = 0
    if l
      for i in l
        @add(i)

  map: (f) ->
    out = []
    @forEach((item) ->
      out.push f(item)
    )
    return out

  toArray: ->
    out = []
    @forEach((item) ->
      out.push item)
    return out

  forEach: (f) ->
    for item of @items
      f(@items[item])

  forEachPair: (f) ->
    keys = Object.keys(@items)
    for i in [0..keys.length-2]
      for j in [i+1..keys.length-1]
        f(@items[keys[i]], @items[keys[j]])

  forEachPop: (f, untilFunction) ->
    while @length > 0
      f(@pop())
      if untilFunction and untilFunction()
        return

  forEachPopAsync: (f, callback) ->
    worker = new WhileWorker({
      condition: (->
        return @length > 0
      ).bind(this)
      work: (->
        f(@pop())
      ).bind(this)
    }, {
      ondone: callback
    })
    worker.run()
    return worker

  add: (items...) ->
    for item in items
      id = generateId(item)
      if id not of @items
        @items[id] = JSON.parse(JSON.stringify(item))
        @length++

  peek: ->
    if @length == 0
      throw 'Cannot peek at an empty set'
    for key of @items
      return @items[key]

  pop: ->
    if @length == 0
      throw 'Cannot pop from an empty set'
    for key of @items
      item = @items[key]
      #@remove(item)
      delete @items[key]
      @length--
      return item

  contains: (item) ->
    id = generateId(item)
    return id of @items

  remove: (item) ->
    id = generateId(item)
    if id of @items
      delete @items[id]
      @length--

  union: (other) ->
    newSet = new Set()
    @forEach((item) ->
      newSet.add(item))
    other.forEach((item) ->
      newSet.add(item))
    return newSet

  unionThis: (other) ->
    other.forEach((item) =>
      @add(item))
    return @

  intersection: (other) ->
    newSet = new Set()
    @forEach((item) ->
      newSet.add(item) if other.contains(item))
    return newSet

  subtract: (other) ->
    newSet = new Set()
    @forEach(((item) ->
      if not other.contains(item)
        newSet.add item
    ).bind(this))
    return newSet
