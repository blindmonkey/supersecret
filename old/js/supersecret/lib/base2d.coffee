average = (l) ->
  s = 0
  for i in l
    s += i
  return s / l.length

startRender = (tick) ->
  renderer = this
  stopped = false
  frameHistory = []

  lastTime = new Date().getTime()

  maybeUpdate = ((frequency) ->
    frequency = frequency or 10000

    lastUpdated = new Date().getTime() - frequency
    return ->
      if new Date().getTime() - lastUpdated > frequency
        if frameHistory.length > 100
          frameHistory = frameHistory.splice(frameHistory.length - 100, 100)
        console.log('Render loop: ' + 1000 / average(frameHistory) + ' frames per second')
        lastUpdated = new Date().getTime())(5000)

  handle =
    stopped: false
    pause: ->
      handle.stopped = true
    unpause: ->
      handle.stopped = false
      lastTime = new Date().getTime()
      f()

  f = ->
    now = new Date().getTime()
    tick(now - lastTime)
    frameHistory.push(now - lastTime)
    maybeUpdate()
    lastTime = now
    if not renderer.stopped
      requestAnimationFrame(f)
  f()
  return handle


lib.export('Base2DGame', class Base2DGame
  constructor: (container, width, height) ->
    @preinit and @preinit(container, width, height)

    @container = container
    canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    $(@container).append(canvas)
    @context = canvas.getContext('2d')

    window.addEventListener('resize', =>
      canvas.width = window.innerWidth
      canvas.height = window.innerHeight
    , false);

    $(document).keydown(((e) ->
      if e.keyCode == 27
        if not @renderer.stopped
          @stop()
        else
          @handle.unpause()
    ).bind(this))

    @initGeometry and @initGeometry()
    @initLights and @initLights()

    @postinit and @postinit()

  render: (delta) ->
    @update and @update(delta)

  start: ->
    if not @handle
      @handle = startRender(@render.bind(this))

  stop: ->
    @handle.pause()
)
