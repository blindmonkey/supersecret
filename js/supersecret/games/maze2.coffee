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
    @grid = new supersecret.Grid(2, [20, 20])
    start =
      x: Math.floor(Math.random() * @grid.size[0])
      y: Math.floor(Math.random() * @grid.size[1])
    @stack = [{from:null, to:[start.x, start.y]}]
    @updateDelta = 0

    @paths = {}

  render: (delta) ->
    findUnvisitedNeighbors = ((x, y) ->
      neighbors = []
      if x > 0 and not @grid.get(x - 1, y)
        neighbors.push([x - 1, y])
      if y > 0 and not @grid.get(x, y - 1)
        neighbors.push([x, y - 1])
      if x < @grid.size[0] - 1 and not @grid.get(x + 1, y)
        neighbors.push([x + 1, y])
      if y < @grid.size[1] - 1 and not @grid.get(x, y + 1)
        neighbors.push([x, y + 1])
      return neighbors
    ).bind(this)

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

    addPath = ((from, to) ->
      fromKey = from.join('/')
      toKey = to.join('/')
      @paths[fromKey + '=' + toKey] = true
      @paths[toKey + '=' + fromKey] = true
    ).bind(this)

    hasPath = ((from, to) ->
      fromKey = from.join('/')
      toKey = to.join('/')
      return !!@paths[fromKey + '=' + toKey]
    ).bind(this)

    if @stack.length > 0
      @updateDelta += delta
      if @updateDelta > 10
        console.log('UPDATE')
        @updateDelta = 0
        done = false
        neighbors = null
        until done or @stack.length == 0
          p = @stack.pop()
          source = p.from
          p = p.to
          continue if @grid.get(p...)
          @grid.set(true, p...)
          if source?
            addPath(source, p)
          neighbors = findUnvisitedNeighbors(p...)
          if neighbors.length > 0
            done = true
        if done
          neighbors = shuffle(neighbors)
          console.log('pushing more')
          for n in neighbors
            @stack.push({from:p, to:n})

    @grid.forEach(((x, y) ->
      cell = @grid.get(x, y)
      if cell
        @context.fillStyle = '#fff'
      else
        @context.fillStyle = '#000'
      xx = x / @grid.size[0] * @context.canvas.width
      yy = y / @grid.size[0] * @context.canvas.height
      dx = 1 / @grid.size[0] * @context.canvas.width
      dy = 1 / @grid.size[0] * @context.canvas.height
      @context.fillRect(
        xx,
        yy,
        dx,
        dy)
      if not hasPath([x, y], [x - 1, y])
        @context.strokeStyle = '#000'
        @context.beginPath()
        @context.moveTo(xx, yy)
        @context.lineTo(xx, yy + dy)
        @context.closePath()
        @context.stroke()
      if not hasPath([x, y], [x + 1, y])
        @context.strokeStyle = '#000'
        @context.beginPath()
        @context.moveTo(xx + dx, yy)
        @context.lineTo(xx + dx, yy + dy)
        @context.closePath()
        @context.stroke()
      if not hasPath([x, y], [x, y - 1])
        @context.strokeStyle = '#000'
        @context.beginPath()
        @context.moveTo(xx, yy)
        @context.lineTo(xx + dx, yy)
        @context.closePath()
        @context.stroke()
      if not hasPath([x, y], [x, y + 1])
        @context.strokeStyle = '#000'
        @context.beginPath()
        @context.moveTo(xx, yy + dy)
        @context.lineTo(xx + dx, yy + dy)
        @context.closePath()
        @context.stroke()
    ).bind(this)) if @grid.hasData()

  start: ->
    lastRender = new Date().getTime()
    r = (->
      now = new Date().getTime()
      @render(now - lastRender)
      lastRender = now
      requestAnimationFrame(r)
    ).bind(this)
    requestAnimationFrame(r)
