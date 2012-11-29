lib.load('maze', 'facemanager', 'grid', 'random', ->
  Amaze.loaded = true)

class MazeTraverser
  constructor: (maze, start) ->
    if not start
      x = null
      y = null
      limit = null
      r = Math.random()
      if r < 1/4
        x = 0
      else if r < 2/4
        x = maze.size.width - 1
      else if r < 3/4
        y = 0
      else
        y = maze.size.height - 1
      if x isnt null
        y = Math.floor(Math.random() * maze.size.height)
      else
        x = Math.floor(Math.random() * maze.size.width)
      @position = [x, y]
    else
      @position = (i for i in start)
    console.log(@position)
    @maze = maze

  canmove: (pfrom, pto) ->
    if not pto
      pto = @getDirection(pfrom)
      pfrom = @position
    console.log(pfrom, pto)
    return @maze.graph.connected(pfrom, pto)

  getDirection: (direction, opt_position) ->
    position = opt_position or @position
    v = switch direction
      when 'n' then  [position[0],     position[1] - 1]
      #when 'ne' then [position[0] + 1, position[1] - 1]
      when 'e' then  [position[0] + 1, position[1]]
      #se: [position[0] + 1, position[1] + 1]
      when 's' then  [position[0],     position[1] + 1]
      #when 'sw' then [position[0] - 1, position[1] + 1]
      when 'w' then  [position[0] - 1, position[1]]
      else undefined
    return v

  move: (direction) ->
    newPosition = @getDirection(direction)
    if not newPosition
      throw "Invalid direction"
    if not @canmove(@position, newPosition)
      throw "You can't go there"
    return newPosition

  move: (newPosition) ->
    #newPosition = @getDirection(direction)
    if not newPosition
      throw "Invalid direction"
    if not @canmove(@position, newPosition)
      throw "You can't go there"
    return newPosition

class MazeTraveller
  constructor: (maze, start) ->
    @grid = new Grid(2, [maze.size.width, maze.size.height])
    #@traverser = new MazeTraverser(maze, start)
    @maze = maze
    @stack = [start]
    @position = start.concat([])
    @path = []

  move: ->
    @grid.set(true, @position[0], @position[1])
    moves = []
    for move in @maze.getMoves(@position[0], @position[1])
      if not @grid.get(move...)
        moves.push move
    if moves.length == 0
      return @position = @path.pop()
    @path.push @position.concat([])
    return @position = random.choice(moves)

mod = (n, m) ->
  while n < 0
    n += m
  while n >= m
    n -= m
  return n


angleDifference = (r1, r2) ->
  PI2 = Math.PI * 2
  r1 = mod(r1, PI2)
  r2 = mod(r2, PI2)

  multiplier = 1
  if r1 > r2
    diff = r1 - r2
  else
    diff = r2 - r1
    multiplier = -1
  if diff > Math.PI
    diff = Math.PI * 2 - diff
  return diff * multiplier

  r = null
  if Math.abs(r2 - r1) < Math.PI
    return -(r2 - r1)

  return r1 - r2


  r1 =

  l = []

  l.push Math.abs(r1 - r2)
  l.push Math.abs((r1 + PI2) - r2)
  l.push Math.abs((r1 - PI2) - r2)
  min = Infinity
  for i in l
    if Math.abs(i) < Math.abs(min)
      min = i
  return min



supersecret.Game = class Amaze extends supersecret.BaseGame
  @loaded: false
  constructor: (container, width, height, opt_scene, opt_camera) ->
    @maze = new MazeGenerator(20, 20)

    super(container, width, height, opt_scene, opt_camera)

    @person = new supersecret.FirstPerson(container, @camera)
    @traveller = new MazeTraveller(@maze, [0,0])

    @rotationAnimation = null
    @moveAnimation = null
    @direction = 0.0
    @position = @traveller.position.concat([])
    @destination = null
    @updateSpherePosition(@position)

  updateSpherePosition: (position) ->
    #@sphere.position.x = position[0] + .5
    #@sphere.position.z = position[1] + .5
    #@sphere.position.y = 0.5
    @camera.position.x = position[0] + .5
    @camera.position.z = position[1] + .5
    @camera.position.y = 0.5
    @light.position = @camera.position

  initGeometry: ->
    @sphere = new THREE.Mesh(new THREE.SphereGeometry(.4, 8, 8), new THREE.LineBasicMaterial({color: 0xff0000}))
    @scene.add @sphere

    # geometry = new THREE.Geometry()
    # for x in [0..@maze.size.width - 1]
    #   for y in [0..@maze.size.height - 1]
    #     if x == 0 or @maze.graph.connected([x, y], [x - 1, y])
    #       geometry.vertices.push new THREE.Vector3(x, 0, y)
    #       geometry.vertices.push new THREE.Vector3(x, 0, y + 1)
    #     if x == @maze.size.width - 1
    #       geometry.vertices.push new THREE.Vector3(x + 1, 0, y)
    #       geometry.vertices.push new THREE.Vector3(x + 1, 0, y + 1)
    #     if y == 0 or @maze.graph.connected([x, y], [x, y - 1])
    #       geometry.vertices.push new THREE.Vector3(x, 0, y)
    #       geometry.vertices.push new THREE.Vector3(x + 1, 0, y)
    #     if y == @maze.size.height - 1
    #       geometry.vertices.push new THREE.Vector3(x, 0, y + 1)
    #       geometry.vertices.push new THREE.Vector3(x + 1, 0, y + 1)
    # @scene.add new THREE.Line(geometry, new THREE.LineBasicMaterial({color: 0x00ff00}), THREE.LinePieces)
    # return

    faceManager = new FaceManager()
    for x in [0..@maze.size.width - 1]
      for y in [0..@maze.size.height - 1]
        faceManager.addFace(
          new THREE.Vector3(x, 0, y),
          new THREE.Vector3(x, 0, y + 1),
          new THREE.Vector3(x + 1, 0, y)
          )
        faceManager.addFace(
          new THREE.Vector3(x + 1, 0, y),
          new THREE.Vector3(x, 0, y + 1),
          new THREE.Vector3(x + 1, 0, y + 1)
          )
        if x == 0 or not @maze.graph.connected([x, y], [x - 1, y])
          faceManager.addFace(
            new THREE.Vector3(x, 0, y),
            new THREE.Vector3(x, 0, y + 1),
            new THREE.Vector3(x, 1, y + 1), true
            )
          faceManager.addFace(
            new THREE.Vector3(x, 0, y),
            new THREE.Vector3(x, 1, y + 1),
            new THREE.Vector3(x, 1, y), true
            )
        if x == @maze.size.width - 1 #or @maze.graph.connected([x, y], [x + 1, y])
          faceManager.addFace(
            new THREE.Vector3(x + 1, 0, y),
            new THREE.Vector3(x + 1, 0, y + 1),
            new THREE.Vector3(x + 1, 1, y + 1), true
            )
          faceManager.addFace(
            new THREE.Vector3(x + 1, 0, y),
            new THREE.Vector3(x + 1, 1, y + 1),
            new THREE.Vector3(x + 1, 1, y), true
            )
        if y == 0 or not @maze.graph.connected([x, y], [x, y - 1])
          faceManager.addFace(
            new THREE.Vector3(x, 0, y),
            new THREE.Vector3(x + 1, 0, y),
            new THREE.Vector3(x + 1, 1, y), true
            )
          faceManager.addFace(
            new THREE.Vector3(x, 0, y),
            new THREE.Vector3(x + 1, 1, y),
            new THREE.Vector3(x, 1, y), true
            )
        if y == @maze.size.height - 1 #or @maze.graph.connected([x, y], [x + 1, y])
          faceManager.addFace(
            new THREE.Vector3(x, 0, y + 1),
            new THREE.Vector3(x + 1, 0, y + 1),
            new THREE.Vector3(x + 1, 1, y + 1), true
            )
          faceManager.addFace(
            new THREE.Vector3(x, 0, y + 1),
            new THREE.Vector3(x + 1, 1, y + 1),
            new THREE.Vector3(x, 1, y + 1), true
            )
    geometry = faceManager.generateGeometry()
    geometry.computeFaceNormals()
    @scene.add new THREE.Mesh(geometry,
      new THREE.MeshPhongMaterial({color: 0x00ff00}))
      #new THREE.LineBasicMaterial({color: 0x00ff00}))


  initLights: ->
    console.log('initializing lights!')
    #@scene.add new THREE.AmbientLight(0xffffff)
    @light = light = new THREE.PointLight(0xffffff, .9, 5)
    light.position.x = 0
    light.position.y = 10
    light.position.z = 0
    DEBUG.expose('light', light)
    @scene.add light

    # light = new THREE.PointLight(0xffffff, .6, 20)
    # light.position.x = @maze.size.width / 2
    # light.position.z = @maze.size.height / 2
    # light.position.y = 1.5
    # @scene.add light

    # light = new THREE.PointLight(0xffffff, .6, 20)
    # light.position.x = 0
    # light.position.z = 0
    # light.position.y = 1.5
    # @scene.add light

    # light = new THREE.PointLight(0xffffff, .6, 20)
    # light.position.x = @maze.size.width
    # light.position.z = @maze.size.height
    # light.position.y = 1.5
    # @scene.add light

    # dlight = new THREE.DirectionalLight(0xffffff, .6)
    # dlight.position.set(1, 1, 1)
    # @scene.add dlight
    # dlight = new THREE.DirectionalLight(0xffffff, .6)
    # dlight.position.set(-1, 1, -1)
    # @scene.add dlight

  render: (delta) ->
    if @rotationAnimation?
      o = {}
      angle = angleDifference(@newDirection, @direction, o)
      @rotationAnimation += .01 / (Math.abs(angle) / (Math.PI * 2))
      @person.rotation = mod(angle * @rotationAnimation + @direction, Math.PI * 2)
      @person.updateCamera()
      if @rotationAnimation >= 1
        #4.71238898038469 0 -1.5707963267948966
        console.log angleDifference(@newDirection, @direction), @direction, @newDirection
        @moveAnimation = 0
        @rotationAnimation = null
        #@person.rotation = Math.atan2(@destination[1] - @position[1], @destination[0] - @position[0]) # @newDirection
        @person.rotation = @newDirection
        @person.updateCamera()
        @direction = @newDirection
    else if @moveAnimation?
      @moveAnimation += .05
      newp = [(@destination[0] - @position[0]) * @moveAnimation + @position[0],
              (@destination[1] - @position[1]) * @moveAnimation + @position[1]]
      @updateSpherePosition newp
      if @moveAnimation >= 1
        @moveAnimation = null
        @position = @destination
    else
      @destination = @traveller.move()
      @newDirection = mod(Math.atan2(@destination[1] - @position[1], @destination[0] - @position[0]), Math.PI * 2)
      #@person.rotation = @direction
      #@person.updateCamera()
      #@moveAnimation = 0
      if @newDirection == @direction #or true
        @moveAnimation = 0
      else
        @rotationAnimation = 0

    #@person.update(delta)
    @renderer.renderer.render(@scene, @camera)
