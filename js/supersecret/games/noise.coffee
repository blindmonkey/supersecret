lib.load(
  'facemanager'
  'firstperson'
  'grid'
  'noisegenerator'
  'polygons'
  -> supersecret.Game.loaded = true)

class WorldGeometry
  constructor: (chunkSize, tileSize) ->
    @chunkSize = chunkSize
    @tileSize = tileSize

  generateGeometry: (chunk, callback) ->
    faces = new FaceManager(chunk.size[0] * chunk.size[1])
    for x in [1..chunk.size[0]-1]
      for y in [1..chunk.size[1] - 1]
        h = chunk.get(x, y)
        hl = chunk.get(x - 1, y)
        hlu = chunk.get(x - 1, y - 1)
        hu = chunk.get(x, y - 1)
        faces.addFace4(
          [((x-1) * @tileSize), (hl * @tileSize), (y * @tileSize)]
          [( x    * @tileSize), (h * @tileSize), (y * @tileSize)]
          [( x    * @tileSize), (hu * @tileSize), ((y-1) * @tileSize)]
          [((x-1) * @tileSize), (hlu * @tileSize), ((y-1) * @tileSize)]
        )
    callback(faces.generateGeometry())
aaa = false

class World
  constructor: (scene, chunkSize=[16, 16], tileSize=4) ->
    @chunks = new Grid(2, [Infinity, Infinity])
    @chunks.handleEvent('missing', @generateChunk.bind(this))
    @chunkSize = chunkSize
    @tileSize = tileSize
    @geometry = new WorldGeometry(chunkSize, tileSize)
    @scene = scene
    @scale = 8
    @generator = new NoiseGenerator(new SimplexNoise(), [{
      scale: 0.05
      multiplier: 4
    }, {
      scale: 0.1
      multiplier: 2
    }, {
      scale: 0.2
      multiplier: 1.8
    }, {
      scale: 0.4
      multiplier: 1.5
    }, {
      scale: 0.8
      multiplier: .5
    }, {
      scale: 1.5
      multiplier: .25
    }, {
      scale: 0.01
      op: (a, b) -> a * ((b + 1) / 2)
    }

    ])

  maybeGenerateChunk: (x, y) ->
    cx = Math.floor(x / @chunkSize[0])
    cy = Math.floor(y / @chunkSize[1])
    e = @chunks.exists(cx, cy)
    if not e
      console.log('Generating chunk ' , cx, cy)
      @generateChunk(cx, cy)

  generateChunk: (cx, cy) ->
    chunk = new Grid(2, @chunkSize)
    for x in [0..@chunkSize[0]-1]
      for y in [0..@chunkSize[1]-1]
        chunk.set(@generator.noise2D((x + cx * (@chunkSize[0] - 1)) / @scale, (y + cy * (@chunkSize[1] - 1)) / @scale) * @scale, x, y)
    @chunks.set(chunk, cx, cy)
    @geometry.generateGeometry(chunk, (geometry) =>
      geometry.computeFaceNormals()
      mesh = new THREE.Mesh(geometry, new THREE.MeshLambertMaterial({color: 0xff0000}))
      mesh.position.x = cx * (@chunkSize[0] - 1) * @tileSize
      mesh.position.z = cy * (@chunkSize[1] - 1) * @tileSize
      @scene.add mesh
    )

  get: (x, y) ->
    cx = Math.floor(x / @chunkSize[0])
    cy = Math.floor(y / @chunkSize[1])
    lx = x - cx * @chunkSize[0]
    ly = y - cy * @chunkSize[1]
    chunk = @chunks.get(cx, cy)
    return chunk.get(lx, ly)

  set: (v, x, y) ->
    cx = Math.floor(x / @chunkSize[0])
    cy = Math.floor(y / @chunkSize[1])
    lx = x - cx * @chunkSize[0]
    ly = y - cy * @chunkSize[1]
    chunk = @chunks.get(cx, cy)
    return chunk.set(v, lx, ly)




supersecret.Game = class NoiseGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)
    @chunkSize = [16, 16]
    @tileSize = 8
    @world = new World(@scene, @chunkSize, @tileSize)
    @world.generateChunk(0, 0)

  initLights: ->
    @scene.add @light = new THREE.DirectionalLight(0xffffff, 1)
    @light.position.y = Math.random() * .5
    @light.position.z = Math.random() - 0.5
    @light.position.x = Math.random() - 0.5

  update: (delta) ->
    for x in [-2..2]
      for y in [-2..2]
        @world.maybeGenerateChunk(@camera.position.x / @tileSize + x * @chunkSize[0], @camera.position.z / @tileSize + y * @chunkSize[1])
    @world.maybeGenerateChunk(@camera.position.x / @tileSize, @camera.position.z / @tileSize)
    @person.update(delta)
