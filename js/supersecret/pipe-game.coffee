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
      x: 25
      y: 25
      z: 25
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

  setPipe: (position, direction) ->
    prevData = @grid[position.x][position.y][position.z]
    prevFrom = null
    prevTo = null
    objects = []
    if prevData?
      [prevFrom, prevTo] = prevData.direction
      objects = prevData.objects

    [from, to] = direction
    from = prevFrom if from is undefined
    to = prevTo if to is undefined

    if from and from == to
      throw 'A pipe cannot go in the same direction it starts'

    if not @grid[position.x][position.y][position.z]
      @grid[position.x][position.y][position.z] = {}
    cell = @grid[position.x][position.y][position.z]

    cell.direction = [from, to]
    cell.objects = objects

  createPipeGeometry: ->
    getRealPosition = ((x, y, z) ->
      p =
        x: (x - @size.x / 2) * @cellSize
        y: (y - @size.y / 2) * @cellSize
        z: (z - @size.z / 2) * @cellSize
      return p
    ).bind(this)

    createSphere = ((x, y, z) ->
      geometry = new THREE.SphereGeometry(@cellSize * .2, 8, 8)
      material = new THREE.MeshPhongMaterial({color: 0xff0000, emissive: 0x400000})
      #material = new THREE.LineBasicMaterial({color: 0xff0000})
      mesh = new THREE.Mesh(geometry, material)
      pos = getRealPosition(x, y, z)
      mesh.position.x = pos.x
      mesh.position.y = pos.y
      mesh.position.z = pos.z
      return mesh
    ).bind(this)

    createCylinder = ((x, y, z, optHalfSize) ->
      h = @cellSize
      if optHalfSize
        h /= 2
      r = @cellSize * .2
      geometry = new THREE.CylinderGeometry(r, r, h, 8, 8, false)
      material = new THREE.MeshPhongMaterial({color: 0xff0000, emissive: 0x400000, specular: 0xff9090})
      #material = new THREE.LineBasicMaterial({color: 0xff0000})
      mesh = new THREE.Mesh(geometry, material)
      pos = getRealPosition(x, y, z)
      mesh.position.x = pos.x
      mesh.position.y = pos.y
      mesh.position.z = pos.z
      return mesh
    ).bind(this)

    drawPipe = ((x, y, z) ->
      pipe = @getCell({x:x,y:y,z:z})
      [from, to] = pipe.direction

      for obj in pipe.objects
        @scene.remove(obj)

      pipe.objects = []

      if from == null and to == null
        pipe.objects.push(createSphere(x, y, z))
      else if from and to and from[1] == to[1]
        cyl = createCylinder(x, y, z)
        r = if from[1] == 'x' then 'z' else if from[1] == 'z' then 'x' else null
        if r
          cyl.rotation[r] = Math.PI / 2
        pipe.objects.push(cyl)
      else
        sphere = createSphere(x, y, z)

        if from
          cyl1 = createCylinder(x, y, z, true)
          fromMultiplier = if from[0] == '-' then -1 else 1
          cyl1.position[from[1]] += @cellSize / 4 * fromMultiplier
          rFrom = if from[1] == 'x' then 'z' else if from[1] == 'z' then 'x' else null
          if rFrom
            cyl1.rotation[rFrom] = Math.PI / 2
          pipe.objects.push(cyl1)

        if to
          cyl2 = createCylinder(x, y, z, true)

          toMultiplier = if to[0] == '-' then -1 else 1
          cyl2.position[to[1]] += @cellSize / 4 * toMultiplier

          rTo = if to[1] == 'x' then 'z' else if to[1] == 'z' then 'x' else null

          if rTo
            cyl2.rotation[rTo] = Math.PI / 2
          pipe.objects.push(cyl2)

        pipe.objects.push(sphere)

      for obj in pipe.objects
        @scene.add(obj)
    ).bind(this)

    # for x in [0..@size.x-1]
    #   for y in [0..@size.y-1]
    #     for z in [0..@size.z-1]
    #       createSphere(x, y, z)

    reverseDirection = (direction) ->
      d0 = direction[0]
      return (if d0 == '-' then '+' else '-') + direction[1]

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

    #debugger
    nextPipeState = []
    pipeIndex = 0
    for pipe in @pipes
      drawPipe(pipe.x, pipe.y, pipe.z)
      nextPosition = null
      direction = null
      possibilities = ['-x', '-y', '-z', '+x', '+y', '+z']
      while not nextPosition?
        if possibilities.length == 0
          console.log('Pipe ' + pipeIndex + ' was destroyed')
          break
        p = random.range(possibilities.length)
        direction = possibilities[p]
        nextPosition = calculateNextPosition(pipe, direction)
        if not isGoodPosition(nextPosition)
          nextPosition = null
          possibilities.splice(p, 1)
      if not nextPosition?
        continue
      @setPipe(pipe, [undefined, direction])
      @setPipe(nextPosition, [reverseDirection(direction), null])
      drawPipe(pipe.x, pipe.y, pipe.z)
      drawPipe(nextPosition.x, nextPosition.y, nextPosition.z)
      nextPipeState.push(nextPosition)
      pipeIndex++
      #pipe[axis] += modify(1)
    @pipes = nextPipeState

    #setTimeout(, 500)


  initLights: ->
    @lights = []
    addLight = ((x, y, z) ->
      light = new THREE.PointLight(
        random.choice([0xFFFFFF, 0xFF0000, 0x00FF00, 0x0000FF]), 2, 2000)
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

  getCell: (v) ->
    return @cellExists and @grid[v.x][v.y][v.z]

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
    @setPipe(dim, [null, null])
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
      if Math.random() < .1
        @pipes.push(@createPipe())
      @createPipeGeometry.bind(this)()
      @updatedPipeGeometry = new Date().getTime()
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)



p.provide('PipeGame', PipeGame)
