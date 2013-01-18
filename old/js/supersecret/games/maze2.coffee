

class MazeArtist
  constructor: (maze) ->
    @maze = maze

  draw: (context) ->
    context.fillStyle = '#fff'
    context.fillRect(0, 0, context.canvas.width, context.canvas.height)
    line = (p1, p2) ->
      [fx, fy] = p1
      [tx, ty] = p2
      context.beginPath()
      context.moveTo(fx, fy)
      context.lineTo(tx, ty)
      context.closePath()
      context.stroke()
    for x in [0..@maze.size.width - 1]
      for y in [0..@maze.size.height - 1]
        p = [x, y]
        #context.fillStyle = '#000'
        if @maze.graph.exists(p)
          context.fillStyle = '#fff'
        xx = Math.floor(x / @maze.size.width * context.canvas.width)
        yy = Math.floor(y / @maze.size.height * context.canvas.height)
        dx = Math.ceil(1 / @maze.size.width * context.canvas.width)
        dy = Math.ceil(1 / @maze.size.height * context.canvas.height)
        context.fillRect(
          xx,
          yy,
          dx,
          dy)

        context.strokeStyle = '#000'
        if not @maze.graph.connected([x, y], [x - 1, y])
          line([xx, yy], [xx, yy + dy])
        if not @maze.graph.connected([x, y], [x + 1, y])
          line([xx + dx, yy], [xx + dx, yy + dy])
        if not @maze.graph.connected([x, y], [x, y - 1])
          line([xx, yy], [xx + dx, yy])
        if not @maze.graph.connected([x, y], [x, y + 1])
          line([xx, yy + dx], [xx + dx, yy + dy])
        #   context.strokeStyle = '#000'
        #   context.beginPath()
        #   context.moveTo(xx, yy + dy)
        #   context.lineTo(xx + dx, yy + dy)
        #   context.closePath()
        #   context.stroke()

supersecret.Game = class Maze2
  @loaded: false
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
    @maze = new MazeGenerator(20, 20, false)
    @artist = new MazeArtist(@maze)

  render: (delta) ->
    if not @maze.generated()
      @updateDelta += delta
      if @updateDelta > 10
        @updateDelta = 0
        #debugger
        @maze.generateNext()
    @artist.draw(@context)

  start: ->
    lastRender = new Date().getTime()
    r = (->
      now = new Date().getTime()
      @render(now - lastRender)
      lastRender = now
      requestAnimationFrame(r)
    ).bind(this)
    requestAnimationFrame(r)

lib.load('graph', 'set', 'maze', ->
  Maze2.loaded = true
)
