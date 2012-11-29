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

    canMove: (x, y, xto, yto) ->
      return @graph.connected([x, y], [xto, yto])

    getMoves: (x, y) ->
      return @graph.connections([x, y])

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
