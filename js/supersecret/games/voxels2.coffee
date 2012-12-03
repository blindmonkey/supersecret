lib.load('grid', ->
  supersecret.Game.loaded = true)

shit = true
class LineManager
  constructor: ->
    @vertices = []
    @vertexIndex = {}
    @lines = []
    @lineIndex = {}

  getVertexId: (vertex) ->
    return vertex.x + '/' + vertex.y

  normalizeVertex: (vertex) ->
    if 'x' of vertex and 'y' of vertex
      return vertex
    if vertex instanceof Array
      return {
        x: vertex[0]
        y: vertex[1]
      }
    throw 'Cannot notmalize vertex ' + vertex

  getVertex: (vertex) ->
    vertexId = @getVertexId(vertex)
    return @vertexIndex[vertexId]

  addVertex: (vertex) ->
    vertex = @normalizeVertex(vertex)
    vertexId = @getVertexId(vertex)
    if vertexId not of @vertexIndex
      @vertexIndex[vertexId] = vertex
    return @vertexIndex[vertexId]

  getLineId: (line) ->
    return @getVertexId(line.a) + '|' + @getVertexId(line.b)

  normalizeLine: (line) ->
    va = null
    vb = null
    if 'a' of line and 'b' of line
      va = line.a
      vb = line.b
    else if line instanceof Array
      [va, vb] = line
    if va is null or vb is null
      throw 'Cannot normalize line ' + line
    return {
      a: va
      b: vb
    }

  getLine: (line) ->
    lineId = @getLineId(line)
    return @lineIndex[lineId]

  addLine: (line) ->
    line = @normalizeLine(line)
    lineId = @getLineId(line)
    if lineId not of @lineIndex
      @lineIndex[lineId] = line
    return @lineIndex[lineId]

  drawPath: (context) ->
    null

supersecret.Game = class Voxels2Game
  @loaded: false
  constructor: (container, width, height) ->
    $canvas = $('<canvas>')
    canvas = $canvas[0]
    canvas.width = width
    canvas.height = height
    @context = canvas.getContext('2d')
    $(container).append($canvas)

    @grid = new Grid(2, [Infinity, Infinity])
    noise = new SimplexNoise()

    @generateXY = ((coords...) ->
      #console.log('In for each in range' + coords)
      n = noise.noise2D((c/16 for c in coords)...)
      @grid.set(n > 0, coords...)
    ).bind(this)

    @grid.handleEvent('missing', ((coords...) ->
      @generateXY(coords...)
    ).bind(this))
    #@grid.forEachInRange(((coords...) ->
      #@generateXY(coords...)
    #).bind(this), [-10, 10], [-10, 10])

    @camera =
      x: 0
      y: 0
    @cellSize = 20
    window.addEventListener('resize', (->
      canvas.width = window.innerWidth
      canvas.height = window.innerHeight
    ).bind(this), false);

    mouse =
      down: false
      position: null
    $(container).mousedown(((e) ->
      mouse.down = true
      mouse.position = [e.clientX, e.clientY]
    ).bind(this))
    $(container).mousemove(((e) ->
      if mouse.down
        [lx, ly] = mouse.position
        @camera.x -= e.clientX - lx
        @camera.y -= e.clientY - ly
        mouse.position = [e.clientX, e.clientY]
    ).bind(this))
    $(container).mouseup(((e) ->
      mouse.down = false
      mouse.position = [e.clientX, e.clientY]
    ).bind(this))

  render: (delta) ->
    @context.fillStyle = '#000'
    @context.fillRect(0, 0, @context.canvas.width, @context.canvas.height)

    xstart = Math.floor((@camera.x - @context.canvas.width / 2) / @cellSize)
    xend = Math.ceil((@camera.x + @context.canvas.width / 2) / @cellSize)
    ystart = Math.floor((@camera.y - @context.canvas.height / 2) / @cellSize)
    yend = Math.ceil((@camera.y + @context.canvas.height / 2) / @cellSize)
    if xstart > @grid.limits[0].min
      xstart = @grid.limits[0].min
    if xend < @grid.limits[0].max
      xend = @grid.limits[0].max
    if ystart > @grid.limits[1].min
      ystart = @grid.limits[1].min
    if yend < @grid.limits[1].max
      yend = @grid.limits[1].max

    arraysEq = (a1, a2) ->
      if a1.length != a2.length
        return false
      for i in [0..a1.length - 1]
        if a1[i] != a2[i]
          return false
      return true

    getPath = (cells...) ->
      defs = [
        [[true, false, false, false], [
          [0, 0]
          [0.5, 0]
          [0.5, 0.25]
          [0.25, 0.5]
          [0, 0.5]
        ]]
        [[true, true, false, false], [
          [0, 0]
          [1, 0]
          [1, 0.5]
          [0, 0.5]
        ]]
        [[true, true, true, false], [
          [0, 0]
          [1, 0]
          [1, 0.5]
          [0.5, 0.5]
          [0.5, 1]
          [0, 1]
        ]]
        # [[true, true, true, true], [
        #   [0, 0]
        #   [1, 0]
        #   [1, 1]
        #   [0, 1]
        # ]]
      ]

      indexFromCoord = (x, y) ->
        return y * 2 + x
      coordFromIndex = (index) ->
        x = index % 2
        y = (index - x) / 2
        return {
          x: x
          y: y
        }
      #console.log(coordFromIndex(1), coordFromIndex(2))
      doCoordTransform = (transform, cells...) ->
        newCells = []
        for c in [0..3]
          coord = coordFromIndex(c)
          coord = transform(coord.x, coord.y)
          index = indexFromCoord(coord.x, coord.y)
          newCells[index] = cells[c]
        return newCells

      flipXCoord = (x, y) ->
        return {
          x: 1 - x
          y: y
        }

      flipYCoord = (x, y) ->
        return {
          x: x
          y: 1 - y
        }

      rotate90Right = (x, y) ->
        return {
          x: 1 - y
          y: x
        }
      rotate90Left = (x, y) ->
        return {
          x: y
          y: 1 - x
        }
      rotate180 = (x, y) ->
        return {
          x: 1-x
          y: 1-y
        }

      transforms = [
        [((x, y) -> {x:x, y:y}), ((x, y) -> {x:x, y:y})],
        [flipXCoord, flipXCoord],
        [flipYCoord, flipYCoord],
        #[((x, y) -> {x:1-y,y:x}), ((x, y) -> {x:1-y, y:1-x})]
        [rotate90Left, rotate90Right],
        [rotate90Right, rotate90Left],
        [rotate180, rotate180],
        #[((x, y) -> {x:1-x,y:1-y}), ((x, y) -> {x:1-x, y:1-y})]
      ]
      for [def, path] in defs
        transform = null
        for [t, u] in transforms
          newCells = doCoordTransform(t, cells...)
          if arraysEq(newCells, def)
            transform = u
            break
        if transform?
          newPath = []
          for p in path
            pos = transform(p...)
            newPath.push([pos.x, pos.y])
          return newPath
      return null

    drawPath = ((context, path, offset) ->
      [ox, oy] = offset
      firstPoint = true
      context.beginPath()
      for [x, y] in path
        if firstPoint
          context.moveTo(x * @cellSize + ox, y * @cellSize + oy)
          firstPoint = false
        else
          context.lineTo(x * @cellSize + ox, y * @cellSize + oy)
      context.closePath()
      context.strokeStyle = '#f00'
      context.stroke()
    ).bind(this)




    if shit
      debugger
      p = getPath(false, false, false, true)
      shit = false


    #debugger
    for x in [xstart-2..xend+2]
      for y in [ystart-2..yend+2]
        cell = @grid.get(x, y) or false
        rightCell = @grid.get(x + 1, y) or false
        bottomCell = @grid.get(x, y + 1) or false
        bottomRightCell = @grid.get(x + 1, y + 1) or false
        @context.fillStyle = if cell then '#fff' else '#0f0'
        if cell and false
          @context.fillRect(
            x * @cellSize - @camera.x + @context.canvas.width / 2,
            y * @cellSize - @camera.y + @context.canvas.height / 2,
            @cellSize, @cellSize)
        xp = x * @cellSize - @camera.x + @context.canvas.width / 2
        yp = y * @cellSize - @camera.y + @context.canvas.height / 2
        if cell
          @context.fillStyle = '#0f0'
          @context.beginPath()
          @context.arc(xp, yp, @cellSize / 4, 0, 2 * Math.PI)
          @context.closePath()
          @context.fill()

        path = getPath(cell, rightCell, bottomCell, bottomRightCell)
        if path?
          drawPath(@context, path, [xp, yp])

        # if cell and not rightCell and not bottomCell and not bottomRightCell
        #   @context.beginPath()
        #   @context.moveTo(xp, yp)
        #   @context.lineTo(xp + @cellSize / 2, yp)
        #   @context.lineTo(xp + @cellSize / 2, yp + @cellSize / 4)
        #   @context.lineTo(xp + @cellSize / 4, yp + @cellSize / 2)
        #   @context.lineTo(xp, yp + @cellSize / 2)
        #   @context.closePath()
        #   @context.stroke()

        # if not cell and rightCell and not bottomCell and not bottomRightCell
        #   @context.beginPath()
        #   @context.moveTo(xp + @cellSize, yp)
        #   @context.lineTo(xp + @cellSize / 2, yp)
        #   @context.lineTo(xp + @cellSize / 2, yp + @cellSize / 4)
        #   @context.lineTo(xp + @cellSize / 4, yp + @cellSize / 2)
        #   @context.lineTo(xp, yp + @cellSize / 2)
        #   @context.closePath()
        #   @context.stroke()
    return null



  start: ->
    lastUpdate = new Date().getTime()
    f = (->
      now = new Date().getTime()
      @render(now - lastUpdate)
      lastUpdate = now
      requestAnimationFrame(f)
    ).bind(this)
    f()
