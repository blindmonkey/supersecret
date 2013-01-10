average = (l) ->
  s = 0
  for i in l
    s += i
  return s / l.length

class Renderer
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

supersecret.BaseGame = class BaseGame
  setClearColor: (hexColor=0, opacity=1) ->
    @renderer.renderer.setClearColorHex(hexColor, opacity)

  constructor: (container, width, height, opt_scene, opt_camera) ->
    @transforms =
      fov: (v) -> parseFloat(v)
      cnear: (v) -> parseFloat(v)
      cfar: (v) -> parseFloat(v)

    @watchedHandlers =
      fov: [(v) =>
        console.log('FOV UPDATE!')
        @camera.fov = v
        @camera.updateProjectionMatrix()]
      cnear: [(v) =>
        @camera.near = v
        @camera.updateProjectionMatrix()]
      cfar: [(v) =>
        @camera.far = v
        @camera.updateProjectionMatrix()]

    intialized = false
    doWatchedUpdate = (params) =>
      console.log('UPDATE!', params)
      for param of params
        value = params[param]
        value = @transforms[param](value) if @transforms[param]
        oldValue = @watched[param]
        if oldValue != value
          console.log("#{param} has changed from #{oldValue} to #{value}")
          @watched[param] = value
          handlers = @watchedHandlers[param]
          if initialized and handlers
            for handler in handlers
              handler(value)

    @watched = {}
    doWatchedUpdate(getQueryParams())
    window.onhashchange = =>
      hash = window.location.hash.substr(1)
      params = getQueryParams(hash)
      doWatchedUpdate(params)
    window.onhashchange()

    @preinit and @preinit(container, width, height)

    @container = container
    @renderer = new Renderer(container, width, height)
    @scene = opt_scene or new THREE.Scene()
    @camera = opt_camera or @initCamera(width, height)

    initialized = true

    console.log("Game construction...")
    window.addEventListener('resize', (->
      @renderer.resize(window.innerWidth, window.innerHeight)
      @camera.aspect = window.innerWidth / window.innerHeight
      @camera.updateProjectionMatrix()
    ).bind(this), false);

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

  setTransform: (property, transform) ->
    @transforms[property] = transform
    window.onhashchange()

  watch: (property, handler) ->
    if property not of @watchedHandlers
      @watchedHandlers[property] = []
    @watchedHandlers[property].push handler
    handler(@watched[property])

  initCamera: (width, height) ->
    VIEW_ANGLE = @watched.fov or 45
    ASPECT = width / height
    NEAR = @watched.cnear or 0.1
    FAR = @watched.cfar or 10000

    camera = new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
    DEBUG.expose('camera', camera)

    @scene.add camera

    return camera

  render: (delta) ->
    @update and @update(delta)
    @renderer.renderer.render(@scene, @camera)

  start: ->
    if not @handle
      @handle = @renderer.start(@render.bind(this))

  stop: ->
    @handle.pause()

#p.provide('BaseGame', BaseGame)
