random =
  random: Math.random
  range: (start, end) ->
    if not end?
      end = start
      start = 0
    return Math.floor(Math.random() * (end - start)) + start
  choice: (l) -> l[Math.floor(Math.random() * l.length)]

supersecret.Game = class PipeGame
  constructor: (container, width, height, opt_renderer, opt_scene, opt_camera) ->
    @renderer = opt_renderer || new supersecret.Renderer(container, width, height)
    @scene = opt_scene || new THREE.Scene()
    @camera = opt_camera || @initCamera(width, height)

    $(document).keydown(((e) ->
      console.log('keydown!' + e.keyCode)
      if e.keyCode == 27
        @handle.pause()
    ).bind(this))

    @size =
      x: 15
      y: 15
      z: 15
    @cellSize = 20
    @grid = (((null for z in [1..@size.z]) for y in [1..@size.y]) for x in [1..@size.x])
    @pipes = []
    @pipes.push(@createPipe())

    @createPipeGeometry()
    @initLights()

    DEBUG.expose('scene', @scene)

    @handle = null
    @person = new supersecret.FirstPerson(container, @camera)
    @person.rotation = 2 * Math.PI
    @person.pitch = 0.033
    @person.updateCamera()
    DEBUG.expose('person', @person)=


  initLights: ->
    @lights = []
    addLight = ((x, y, z) ->
      console.log('Adding light')
      light = new THREE.PointLight(
        random.choice([0xFFFFFF, 0xFF0000, 0x00FF00, 0x0000FF]), 2, 2000)
      light.position.x = x
      light.position.y = y
      light.position.z = z

      @lights.push light
      @scene.add light
    ).bind(this)

    addLight(@camera.position.x, @camera.position.y, @camera.position.z)

    #addLight(-(@size.x / 2 + 2) * @cellSize, 0, 0)
    #addLight( (@size.x / 2 + 2) * @cellSize, 0, 0)
    #addLight(0, -(@size.y / 2 + 2) * @cellSize, 0)
    #addLight(0,  (@size.y / 2 + 2) * @cellSize, 0)
    #addLight(0, 0, -(@size.z / 2 + 2) * @cellSize)
    #addLight(0, 0,  (@size.z / 2 + 2) * @cellSize)

    DEBUG.expose('lights', @lights)


  cellExists: (v) ->
    g = @grid[v.x]
    return false if not g
    g = g[v.y]
    return false if not g
    g = g[v.z]
    return g?

  getCell: (v) ->
    return @cellExists and @grid[v.x][v.y][v.z]

  setCell: (v, content) ->
    #[fromDim, toDim] = content
    #throw 'The opening and closing of a pipe cannot be the same' if fromDim == toDim

  createPipe: ->
    dim = null
    tries = 10
    color = random.choice([
      0x0000FF,
      0x00FF00,
      0x00FFFF,
      0xFF0000,
      0xFF00FF,
      0xFFFF00
    ])
    while (dim == null || @cellExists(dim))
      return null if tries <= 0
      dim =
        x: Math.floor(Math.random() * @size.x)
        y: Math.floor(Math.random() * @size.y)
        z: Math.floor(Math.random() * @size.z)
      tries--
    dim.color = color
    @setPipe(dim, [null, null], color)
    return dim

  initCamera: (width, height) ->
    VIEW_ANGLE = 45
    ASPECT = width / height
    NEAR = 0.1
    FAR = 10000

    camera = new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
    DEBUG.expose('camera', camera)

    @scene.add camera

    camera.position.z = 0
    camera.position.x = -350
    camera.position.y = 0
    return camera

  start: ->
    console.log('Staring render')
    if @handle == null
      @handle = @renderer.start(@update.bind(this))

  update: (delta) ->
    if not @updatedPipeGeometry or new Date().getTime() - @updatedPipeGeometry > 100
      if Math.random() < .1 and @pipes.length < 3
        @pipes.push(@createPipe())
      @createPipeGeometry.bind(this)()
      @updatedPipeGeometry = new Date().getTime()
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)
