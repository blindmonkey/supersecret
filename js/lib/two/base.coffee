require('core/params')
require('two/renderer')

exports.BaseGame = class BaseGame
  setClearColor: (hexColor=0, opacity=1) ->
    @renderer.renderer.setClearColorHex(hexColor, opacity)

  constructor: (container, width, height, opt_scene, opt_camera) ->
    intialized = false

    @preinit and @preinit(container, width, height)

    @container = container
    @renderer = new Renderer(container, width, height)
    @context = @renderer.context

    initialized = true

    console.log("Game construction...")
    window.addEventListener('resize', (->
      @renderer.resize(window.innerWidth, window.innerHeight)
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

  render: (delta) ->
    @update and @update(delta)

  start: ->
    if not @handle
      @handle = @renderer.start(@render.bind(this))

  stop: ->
    @handle.pause()
