#Renderer = p.require('Renderer')

supersecret.BaseGame = class BaseGame
  constructor: (container, width, height, opt_scene, opt_camera) ->
    @renderer = new supersecret.Renderer(container, width, height)
    @scene = opt_scene or new THREE.Scene()
    @camera = opt_camera or @initCamera(width, height)

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

  initCamera: (width, height) ->
    VIEW_ANGLE = @viewAngle or 45
    ASPECT = width / height
    NEAR = 0.1
    FAR = 10000

    camera = new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
    DEBUG.expose('camera', camera)

    @scene.add camera

    return camera

  start: ->
    if not @handle
      @handle = @renderer.start(@render.bind(this))

  stop: ->
    @handle.pause()

#p.provide('BaseGame', BaseGame)
