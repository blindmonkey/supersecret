lib.load(
  'maze'
  'facemanager'
  'grid'
  'random'
  ->
    Amaze.loaded = true
)

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
    diff = -(Math.PI * 2 - diff)
  return diff * multiplier

lerp = (l1, l2, p) ->
  throw 'Invalid sizes' if l1.length != l2.length
  o = []
  for i in [0..l1.length - 1]
    o.push((l2[i] - l1[i]) * p + l1[i])
  return o

class MazeTraveller
  constructor: (maze, start) ->
    @grid = new Grid(maze.size.length, maze.size)
    @maze = maze
    @stack = [start]
    @position = start.concat([])
    @path = []

  move: ->
    @grid.set(true, @position...)
    moves = []
    for move in @maze.getMoves(@position)
      if not @grid.get(move...)
        moves.push move
    if moves.length == 0
      if @path.length == 0
        return @position
      return @position = @path.pop()
    @path.push @position.concat([])
    return @position = random.choice(moves)


supersecret.Game = class Amaze extends supersecret.BaseGame
  @loaded: false
  preinit: ->
    @maze = new MazeGenerator3([20, 20, 10])
  
  postinit: -> # (container, width, height, opt_scene, opt_camera) ->
    #super(container, width, height, opt_scene, opt_camera)
    @setTransform('distance', parseFloat)
    @setTransform('rotation', parseFloat)
    @setTransform('move', parseFloat)
    @watch('distance', (v) =>
      @light.distance = v)

    @person = new supersecret.FirstPerson(container, @camera)
    @setTransform('interactive', (v) ->
      v = v.toLowerCase()
      if v == 'true' or v == 'yes' or v == '1'
        return true
      return false
    )
    @watch('interactive', (v) =>
      console.log('Setting interactive to ', v)
      @person.interactive = v)
    @traveller = new MazeTraveller(@maze, [0,0, 0])

    @rotationAnimation = null
    @moveAnimation = null
    @direction = 0.0
    @position = @traveller.position.concat([])
    @destination = null
    @updateSpherePosition(@position)
    @shouldUpdateCamera = true

  updateSpherePosition: (position) ->
    if @shouldUpdateCamera
      @camera.position.x = position[0] + .5
      @camera.position.z = position[1] + .5
      @camera.position.y = position[2] + 0.25
    @light.position = @camera.position

  initGeometry: ->
    faceManager = new FaceManager()
    for z in [0..@maze.size[2] - 1]
      for x in [0..@maze.size[0] - 1]
        for y in [0..@maze.size[1] - 1]
          if z == 0 or not @maze.graph.connected([x, y, z], [x, y, z - 1])
            faceManager.addFace4(
              [x, z, y]
              [x, z, y + 1]
              [x + 1, z, y + 1]
              [x + 1, z, y]
              undefined
              true)
          if x == 0 or not @maze.graph.connected([x, y, z], [x - 1, y, z])
            faceManager.addFace4(
              [x, z, y]
              [x, z, y + 1]
              [x, z + 1, y + 1]
              [x, z + 1, y]
              undefined
              true)
          if x == @maze.size[0] - 1
            faceManager.addFace4(
              [x + 1, z, y]
              [x + 1, z, y + 1]
              [x + 1, z + 1, y + 1]
              [x + 1, z + 1, y]
              undefined
              true)
          if y == 0 or not @maze.graph.connected([x, y, z], [x, y - 1, z])
            faceManager.addFace4(
              [x, z, y]
              [x + 1, z, y]
              [x + 1, z + 1, y]
              [x, z + 1, y]
              undefined
              true)
          if y == @maze.size[1] - 1
            faceManager.addFace4(
              [x, z, y + 1]
              [x + 1, z, y + 1]
              [x + 1, z + 1, y + 1]
              [x, z + 1, y + 1]
              undefined
              true)
    geometry = faceManager.generateGeometry()
    geometry.computeFaceNormals()
    @scene.add new THREE.Mesh(geometry
      new THREE.MeshPhongMaterial({color: 0x00ff00})
      #new THREE.LineBasicMaterial({color: 0x00ff00})
    )


  initLights: ->
    console.log('initializing lights!')
    #@scene.add new THREE.AmbientLight(0xffffff)
    @light = light = new THREE.PointLight(0xffffff, .9, @watched.distance or 5)
    light.position.x = 0
    light.position.y = 10
    light.position.z = 0
    DEBUG.expose('light', light)
    @scene.add light

  render: (delta) ->
    maybeUpdateCamera = ((rotation)->
      if @shouldUpdateCamera
        @person.rotation = rotation
        @person.updateCamera()
    ).bind(this)
    rotationSpeed = @watched.rotation or 0.01
    moveSpeed = @watched.move or 0.05
    if not @person.interactive
      if @rotationAnimation?
        o = {}
        angle = angleDifference(@newDirection, @direction, o)
        @rotationAnimation += rotationSpeed / (Math.abs(angle) / (Math.PI * 2))
        maybeUpdateCamera mod(angle * @rotationAnimation + @direction, Math.PI * 2)
        if @rotationAnimation >= 1
          console.log angleDifference(@newDirection, @direction), @direction, @newDirection
          @moveAnimation = 0
          @rotationAnimation = null
          maybeUpdateCamera @newDirection
          @direction = @newDirection
      else if @moveAnimation?
        @moveAnimation += moveSpeed
        newp = lerp(@position, @destination, @moveAnimation)
        @updateSpherePosition newp
        if @moveAnimation >= 1
          @moveAnimation = null
          @position = @destination
      else
        @destination = @traveller.move()
        if @destination
          @newDirection = mod(Math.atan2(@destination[1] - @position[1], @destination[0] - @position[0]), Math.PI * 2)
          if @newDirection == @direction or @destination[2] != @position[2]
  
            @moveAnimation = 0
          else
            maybeUpdateCamera @direction
            @rotationAnimation = 0

    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)
