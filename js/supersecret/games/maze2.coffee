shuffle = (l) ->
  newl = (i for i in l)
  swaps = 10
  for swap in [swaps..0]
    i = Math.floor(Math.random() * newl.length)
    j = Math.floor(Math.random() * newl.length)
    if i != j
      t = newl[i]
      newl[i] = newl[j]
      newl[j] = t
  return newl

generateId = (obj) ->
  if typeof(obj) == 'number'
    return 'number' + obj
  else if typeof(obj) == 'string'
    return 'string' + obj
  else
    return 'object' + JSON.stringify(obj)

class Set
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

  add: (item) ->
    id = generateId(item)
    if id not of @items
      @items[id] = JSON.parse(JSON.stringify(item))
      @length++

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
    return newSet

class Graph
  constructor: ->
    @nodes = {}

  addNode: (obj) ->
    id = generateId(obj)
    if not @exists(obj)
      @nodes[id] = {data: obj, connections: new Set()}
    return id

  exists: (obj) ->
    id = generateId(obj)
    return id of @nodes

  connect: (obj1, obj2) ->
    id1 = @addNode(obj1)
    id2 = @addNode(obj2)
    @nodes[id1].connections.add(id2)
    @nodes[id2].connections.add(id1)

  disconnect: (obj1, obj2) ->
    id1 = generateId(obj1)
    id2 = generateId(obj2)
    @nodes[id1].connections.remove(id2)
    @nodes[id2].connections.remove(id1)

  connected: (obj1, obj2) ->
    id1 = generateId(obj1)
    id2 = generateId(obj2)
    return id1 of @nodes and id2 of @nodes and @nodes[id1].connections.contains(id2)

  connections: (obj) ->
    id = generateId(obj)
    out = []
    return out if id not of @nodes
    @nodes[id].connections.forEach((item) ->
      out.push item)
    return out



class MazeGenerator
  constructor: (width, height, opt_generate) ->
    @size =
      width: width
      height: height
    @graph = new Graph()
    start = [Math.floor(Math.random() * @size.width), Math.floor(Math.random() * @size.height)]
    @stack = [[null, start]]
    if opt_generate is undefined or opt_generate
      while not @generated()
        @generateNext()

  draw: (context) ->
    for x in [0..@size.width - 1]
      for y in [0..@size.height - 1]
        p = [x, y]
        context.fillStyle = '#000'
        if @graph.exists(p)
          context.fillStyle = '#fff'
        xx = x / @size.width * context.canvas.width
        yy = y / @size.height * context.canvas.height
        dx = 1 / @size.width * context.canvas.width
        dy = 1 / @size.height * context.canvas.height
        context.fillRect(
          xx,
          yy,
          dx,
          dy)
        if not @graph.connected([x, y], [x - 1, y])
          context.strokeStyle = '#000'
          context.beginPath()
          context.moveTo(xx, yy)
          context.lineTo(xx, yy + dy)
          context.closePath()
          context.stroke()
        # if not @graph.connected([x, y], [x + 1, y])
        #   context.strokeStyle = '#000'
        #   context.beginPath()
        #   context.moveTo(xx + dx, yy)
        #   context.lineTo(xx + dx, yy + dy)
        #   context.closePath()
        #   context.stroke()
        if not @graph.connected([x, y], [x, y - 1])
          context.strokeStyle = '#000'
          context.beginPath()
          context.moveTo(xx, yy)
          context.lineTo(xx + dx, yy)
          context.closePath()
          context.stroke()
        # if not @graph.connected([x, y], [x, y + 1])
        #   context.strokeStyle = '#000'
        #   context.beginPath()
        #   context.moveTo(xx, yy + dy)
        #   context.lineTo(xx + dx, yy + dy)
        #   context.closePath()
        #   context.stroke()

  generated: ->
    return @stack.length == 0

  generateNext: ->
    return if @generated()
    item = null
    prev = null
    while @stack.length > 0 and item == null
      [prev, item] = @stack.pop()
      item = null if @graph.exists(item)
    return if item == null
    [x, y] = item
    @graph.addNode(item)
    if prev
      @graph.connect(prev, item)
    neighborSet = new Set([[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]])
    neighbors = shuffle(neighborSet.toArray())
    for neighbor in neighbors
      [xx, yy] = neighbor
      if not @graph.exists(neighbor) and 0 <= xx < @size.width and 0 <= yy < @size.height
        @stack.push([item, neighbor])

supersecret.Game = class Maze2
  constructor: (container, width, height) ->
    console.log('hey')
    canvas = $('<canvas>')[0]
    canvas.width = width
    canvas.height = height
    $(container).append(canvas)
    @context = canvas.getContext('2d')
    @context.fillStyle = '#000'
    @context.fillRect(0, 0, canvas.width, canvas.height)

    noise = new SimplexNoise()
    @updateDelta = 0

    console.log('generating maze...')
    @maze = new MazeGenerator(20, 20)

  render: (delta) ->
    if not @maze.generated()
      @updateDelta += delta
      if @updateDelta > 10
        @updateDelta = 0
        #debugger
        @maze.generateNext()
    @maze.draw(@context)

  start: ->
    lastRender = new Date().getTime()
    r = (->
      now = new Date().getTime()
      @render(now - lastRender)
      lastRender = now
      requestAnimationFrame(r)
    ).bind(this)
    requestAnimationFrame(r)
