require('three/renderer')
require('three/three.min.js')
require('core/params')

Params.transform 'fov', parseFloat
Params.transform 'cnear', parseFloat
Params.transform 'cfar', parseFloat

exports.BaseGame = class BaseGame
  setClearColor: (hexColor=0, opacity=1) ->
    @renderer.renderer.setClearColorHex(hexColor, opacity)

  constructor: (container, width, height, opt_scene, opt_camera) ->
    intialized = false

    Params.watch 'fov', (v) =>
      if @camera and v
        @camera.fov = v
        @camera.updateProjectionMatrix()
    Params.watch 'cnear', (v) =>
      if @camera and v
        @camera.near = v
        @camera.updateProjectionMatrix()
    Params.watch 'cfar', (v) =>
      if @camera and v
        @camera.far = v
        @camera.updateProjectionMatrix()

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

  initCamera: (width, height) ->
    VIEW_ANGLE = Params.get('fov') or 45
    ASPECT = width / height
    NEAR = Params.get('cnear') or 0.1
    FAR = Params.get('cfar') or 10000

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
