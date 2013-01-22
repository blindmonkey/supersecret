require('three/three.min.js')

average = (l) ->
  s = 0
  for i in l
    s += i
  return s / l.length

exports.Renderer = class
  constructor: (container, width, height, opt_viewangle) ->
    @width = width
    @height = height
    VIEW_ANGLE = opt_viewangle or 45
    ASPECT = width / height
    NEAR = 0.1
    FAR = 10000

    @renderer = new THREE.WebGLRenderer({antialias: true})
    #@renderer = new THREE.CanvasRenderer()
    @renderer.sortObjects = false
    @renderer.setClearColorHex( 0x000000, 1 )
    @renderer.setSize(width, height)
    console.log('============================ adding renderer')
    $(container).append(@renderer.domElement)

  resize: (width, height) ->
    @width = width
    @height = height
    @renderer.setSize(width, height)

  start: (tick) ->
    renderer = this
    @stopped = false
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

    f = ->
      now = new Date().getTime()
      tick(now - lastTime)
      frameHistory.push(now - lastTime)
      maybeUpdate()
      lastTime = now
      if not renderer.stopped
        requestAnimationFrame(f)
    f()
    return {
      pause: ->
        renderer.stopped = true
      unpause: ->
        renderer.stopped = false
        lastTime = new Date().getTime()
        f()
    }
