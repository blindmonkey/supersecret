Renderer = p.require('Renderer')
FirstPerson = p.require('FirstPerson')

random =
  random: Math.random
  range: (start, end) ->
    if not end?
      end = start
      start = 0
    return Math.floor(Math.random() * (end - start)) + start
  choice: (l) -> l[Math.floor(Math.random() * l.length)]

class PipeGame
  constructor: (container, width, height, opt_renderer, opt_scene, opt_camera) ->
    @renderer = opt_renderer || new Renderer(container, width, height)
    @scene = opt_scene || new THREE.Scene()
    @camera = opt_camera || @initCamera(width, height)

    @size =
      x: 10
      y: 10
      z: 10
    @cellSize = 20
    @grid = (((null for z in [1..@size.z]) for y in [1..@size.y]) for x in [1..@size.x])
    @pipes = []
    @pipes.push(@createPipe())

    @createPipeGeometry()
    @initLights()

    DEBUG.expose('scene', @scene)

    @handle = null
    @person = new FirstPerson(container, @camera)
    @person.rotation = 2 * Math.PI
    @person.pitch = 0.033
    @person.updateCamera()
    DEBUG.expose('person', @person)

  setPipe: (position, from, to) ->
    @grid[position.x][position.y][position.z] = true

  createPipeGeometry: ->
    createSphere = ((x, y, z) ->
      geometry = new THREE.SphereGeometry(@cellSize * .2, 8, 8)
      material = new THREE.MeshPhongMaterial({color: 0xff0000, emissive: 0x400000})
      #material = new THREE.LineBasicMaterial({color: 0xff0000})
      mesh = new THREE.Mesh(geometry, material)
      mesh.position.x = (x - @size.x / 2) * @cellSize
      mesh.position.y = (y - @size.y / 2) * @cellSize
      mesh.position.z = (z - @size.z / 2) * @cellSize
      @scene.add(mesh)
    ).bind(this)
    # for x in [0..@size.x-1]
    #   for y in [0..@size.y-1]
    #     for z in [0..@size.z-1]
    #       createSphere(x, y, z)

    calculateNextPosition = (current, axis) ->
      next =
        x: current.x
        y: current.y
        z: current.z
      if axis.length != 2 or (axis[0] != '-' and axis[0] != '+') or (
        axis[1] != 'x' and axis[1] != 'y' and axis[1] != 'z')
        throw 'ERROR'
      modifier = 1
      if axis[0] == '-'
        modifier = -1
      next[axis[1]] += modifier
      return next

    isGoodPosition = ((position) ->
      return (0 <= position.x < @size.x and
        0 <= position.y < @size.y and
        0 <= position.z < @size.z and not @cellExists(position))
    ).bind(this)

    nextPipeState = []
    pipeIndex = 0
    for pipe in @pipes
      createSphere(pipe.x, pipe.y, pipe.z)
      nextPosition = null
      possibilities = ['-x', '-y', '-z', '+x', '+y', '+z']
      while not nextPosition?
        if possibilities.length == 0
          console.log('Pipe ' + pipeIndex + ' was destroyed')
          break
        p = random.range(possibilities.length)
        possibility = possibilities[p]
        nextPosition = calculateNextPosition(pipe, possibility)
        if not isGoodPosition(nextPosition)
          nextPosition = null
          possibilities.splice(p, 1)
      if not nextPosition?
        continue
      @setPipe(nextPosition)
      nextPipeState.push(nextPosition)
      pipeIndex++
      #pipe[axis] += modify(1)
    @pipes = nextPipeState

    setTimeout(@createPipeGeometry.bind(this), 500)


  initLights: ->
    @lights = []
    addLight = ((x, y, z) ->
      light = new THREE.PointLight(0xFFFFFF, 2, 200)
      light.position.x = x
      light.position.y = y
      light.position.z = z

      @lights.push light
      @scene.add light
    ).bind(this)

    addLight(-(@size.x / 2 + 2) * @cellSize, 0, 0)
    addLight( (@size.x / 2 + 2) * @cellSize, 0, 0)
    addLight(0, -(@size.y / 2 + 2) * @cellSize, 0)
    addLight(0,  (@size.y / 2 + 2) * @cellSize, 0)
    addLight(0, 0, -(@size.z / 2 + 2) * @cellSize)
    addLight(0, 0,  (@size.z / 2 + 2) * @cellSize)

    DEBUG.expose('lights', @lights)


  cellExists: (v) ->
    g = @grid[v.x]
    return false if not g
    g = g[v.y]
    return false if not g
    g = g[v.z]
    return g?

  setCell: (v, content) ->
    #[fromDim, toDim] = content
    #throw 'The opening and closing of a pipe cannot be the same' if fromDim == toDim

  createPipe: ->
    dim = null
    tries = 10
    while (dim == null || @cellExists(dim))
      return null if tries <= 0
      dim =
        x: Math.floor(Math.random() * @size.x)
        y: Math.floor(Math.random() * @size.y)
        z: Math.floor(Math.random() * @size.z)
      tries--
    @setPipe(dim)
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
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)



p.provide('PipeGame', PipeGame)
