lib.load('random', 'graph')

lib.export('MazeGenerator',
  class MazeGenerator
    constructor: (width, height, opt_generate) ->
      @size =
        width: width
        height: height
      @graph = new Graph()
      start = [Math.floor(Math.random() * @size.width), Math.floor(Math.random() * @size.height)]
      @stack = [[null, start]]
      if opt_generate is undefined or opt_generate
        console.log('generating')
        while not @generated()
          @generateNext()

    canMove: (p1, p2) ->
      return @graph.connected(p1, p2)

    getMoves: (p) ->
      return @graph.connections(p)

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
      neighbors = random.shuffle(neighborSet.toArray())
      for neighbor in neighbors
        [xx, yy] = neighbor
        if not @graph.exists(neighbor) and 0 <= xx < @size.width and 0 <= yy < @size.height
          @stack.push([item, neighbor]))


lib.export('MazeGenerator3',
  class MazeGenerator3
    constructor: (size, opt_generate) ->
      @size = size.concat([])
      @graph = new Graph()
      start = (Math.floor(Math.random() * s) for s in @size)
      @stack = [[null, start]]
      if opt_generate is undefined or opt_generate
        console.log('generating')
        while not @generated()
          @generateNext()

    canMove: (p1, p2) ->
      return @graph.connected(p1, p2)

    getMoves: (p) ->
      return @graph.connections(p)

    getUngeneratedNeighbors: (p) ->
      neighbors = []
      maybeAddNeighbor = ((index, modifier) ->
        neighbor = p.concat([])
        neighbor[index] += modifier
        if 0 <= neighbor[index] < @size[index] and not @graph.exists(neighbor)
          neighbors.push neighbor
      ).bind(this)
      for s in [0..@size.length - 1]
        maybeAddNeighbor(s, -1)
        maybeAddNeighbor(s, 1)
      return neighbors



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
      #neighborSet = new Set([[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]])
      neighbors = random.shuffle(@getUngeneratedNeighbors(item))
      for neighbor in neighbors
        @stack.push([item, neighbor])
)
