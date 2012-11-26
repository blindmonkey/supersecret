newZeroVector = ->
  return {x:0, y:0}

addVectors = (v1, v2) ->
  return {x:v1.x+v2.x, y:v1.y+v2.y}

class Object2
  constructor: (polygon, position, rotation, velocity) ->
    @polygon = polygon
    @position = position or newZeroVector()
    @rotation = rotation or 0
    @velocity = velocity or newZeroVector()

  draw: (context) ->
    context.strokeStyle = '#fff'
    context.beginPath()
    firstPoint = true
    for point in @polygon
      if firstPoint
        firstPoint = false
        context.moveTo(point.x + @position.x, point.y + @position.y)
      else
        context.lineTo(point.x + @position.x, point.y + @position.y)
    context.closePath()
    context.stroke()

  willCollideWith: (other) ->
    for pointIndex in [0..@polygon.length - 1]
      for otherPointIndex in [0..other.polygon.lenth - 1]
        first =
          point: @polygon[pointIndex]
          nextPoint: @polygon[(pointIndex + 1) % @polygon.length]
        first.futurePoint = addVectors(first.point, @velocity)
        first.nextFuturePoint = addVectors(first.nextPoint, @velocity)

        otherPoint = other.polygon[otherPointIndex]
        nextOtherPoint = other.polygon[(otherPointIndex + 1) % other.polygon.length]





supersecret.Game = class LinePhysics
  constructor: (container, width, height, opt_scene, opt_camera) ->
    canvas = $('<canvas width="' + parseInt(width) + '" height="' + parseInt(height) + '" />')
    $(container).append(canvas)
    @objects = []
    @context = canvas[0].getContext('2d')

    MINSTEP = 0.01
    for p in [1..2]
      step = 0.01
      size = 50
      polygon = []
      for r in [0..Math.PI * 2] by step
        break if r >= Math.PI * 2
        step += (Math.random() - .5) / 5 / 2
        step = Math.PI if step > Math.PI
        step = MINSTEP if step < MINSTEP
        polygon.push {
          x: Math.cos(r) * size
          y: Math.sin(r) * size
        }
        size += (Math.random() - .5) * 2 * 10
      @objects.push new Object2(polygon, {x:Math.random() * width, y:Math.random() * height})
    console.log(@objects)

  render: (delta) ->
    @context.fillStyle = '#000'
    @context.fillRect(0, 0, @context.canvas.width, @context.canvas.height)
    for obj in @objects
      obj.draw @context

  start: ->
    lastFrame = new Date().getTime()
    f = (->
      now = new Date().getTime()
      @render(now - lastFrame)
      lastFrame = now
      requestAnimationFrame(f)
    ).bind(this)
    f()