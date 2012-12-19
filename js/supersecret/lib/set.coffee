lib.load('id', 'now', 'worker')

lib.export('Set', class Set
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
    # lastUpdated = now()
    # g = (->
    #   lastUpdated = now()
    #   while @length > 0
    #     if now() - lastUpdated > 100
    #       setTimeout(g, 100)
    #       return
    #   callback()
    # ).bind(this)
    # g()

  add: (item) ->
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
    return newSet)
