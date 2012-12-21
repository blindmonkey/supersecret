#Renderer = p.require('Renderer')

supersecret.BaseGame = class BaseGame
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

    @preinit and @preinit(container, width, height)

    @container = container
    @renderer = new supersecret.Renderer(container, width, height)
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
