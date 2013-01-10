lib.load(
  'facemanager'
  'firstperson'
  'grid'
  'noisegenerator'
  'polygons'
  'set'
  'worker'
  -> supersecret.Game.loaded = true)

blendColors = (c1, c2, p) ->
  c1 = new THREE.Color(c1)
  c2 = new THREE.Color(c2)
  c = new THREE.Color(0)
  r = (c2.r - c1.r) * p + c1.r
  g = (c2.g - c1.g) * p + c1.g
  b = (c2.b - c1.b) * p + c1.b
  c.setRGB(r, g, b)
  return c.getHex()

colors = [[0, 0x0000ff], [Infinity, 0xff0000]]
getColorFromHeight = (h) ->
  for i in [0..colors.length - 1]
    [mh, color] = colors[i]
    if h <= mh
      if i > 1 and mh < Infinity
        [pmh, pcolor] = colors[i - 1]
        return blendColors(pcolor, color, (h - pmh) / (mh - pmh))
      return color
  return 0xffffff


class WorldGeometry
  constructor: (chunkSize, tileSize) ->
    @chunkSize = chunkSize
    @tileSize = tileSize
    @noise = new SimplexNoise()
    @noiseScale = 16
    @noiseMultiplier = 10
  
  getNoise: (v, x, y, cx, cy) ->
    [cw, ch] = @chunkSize
    return v if v <= 0
    n = @noise.noise3D((x + cx * (cw - 1)) / @noiseScale, (y + cy * (ch - 1)) / @noiseScale, v / @noiseScale) * @noiseMultiplier
    newv = v + n
    if newv <= 0
      return v
    return newv

  generateGeometry: (chunk, [cx, cy], callback) ->
    [cw, ch] = chunk.size
    faces = new FaceManager(cw * ch)
    for x in [1..chunk.size[0]-1]
      for y in [1..chunk.size[1] - 1]
        h = chunk.get(x, y)
        hl = chunk.get(x - 1, y)
        hlu = chunk.get(x - 1, y - 1)
        hu = chunk.get(x, y - 1)
        hc = getColorFromHeight(@getNoise(h, x, y, cx, cy))
        hlc = getColorFromHeight(@getNoise(hl, x-1, y, cx, cy))
        hluc = getColorFromHeight(@getNoise(hlu, x-1, y-1, cx, cy))
        huc = getColorFromHeight(@getNoise(hu, x, y-1, cx, cy))
        faces.addComplexFace4(
          [((x-1) * @tileSize), (hl * @tileSize), (y * @tileSize)]
          [( x    * @tileSize), (h * @tileSize), (y * @tileSize)]
          [( x    * @tileSize), (hu * @tileSize), ((y-1) * @tileSize)]
          [((x-1) * @tileSize), (hlu * @tileSize), ((y-1) * @tileSize)], {
            vertexColors: [new THREE.Color(hlc), new THREE.Color(hc), new THREE.Color(huc), new THREE.Color(hluc)]
          }
        )
    callback(faces.generateGeometry())
aaa = false

class World
  constructor: (scene, chunkSize=[16, 16], tileSize=4, scale=8) ->
    @initChunks()
    @chunkSize = chunkSize
    @tileSize = tileSize
    @geometry = new WorldGeometry(chunkSize, tileSize)
    @scene = scene
    @scale = scale
    @dirtyChunks = new Set()
    @generatingChunk = null
    @replaceNoiseGenerator([{
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
    @meshes = []

  replaceNoiseGenerator: (description) ->
    @generator = new NoiseGenerator(new SimplexNoise(Math.random), description)

  initChunks: ->
    @chunks = new Grid(2, [Infinity, Infinity])
    @chunks.handleEvent('missing', @generateChunk.bind(this))

  maybeGenerateChunk: (x, y) ->
    cx = Math.floor(x / @chunkSize[0])
    cy = Math.floor(y / @chunkSize[1])
    e = @chunks.exists(cx, cy)
    if not e and not @dirtyChunks.contains([cx, cy])
      console.log('Generating chunk ' , cx, cy)
      @generateChunk(cx, cy)

  generateChunk: (cx, cy) ->
    @dirtyChunks.add [cx, cy]

  unloadMeshes: ->
    for mesh in @meshes
      @scene.remove mesh
    @meshes = []

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

  update: (delta) ->
    return if @dirtyChunks.length == 0 or @generatingChunk?
    [cx, cy] = @dirtyChunks.pop()
    return if @chunks.exists(cx, cy)
    @generatingChunk = [cx, cy]
    chunk = new Grid(2, @chunkSize)
    self = this
    worker = new NestedForWorker([[0, self.chunkSize[0]], [0, self.chunkSize[1]]], ((x, y) =>
      for x in [0..self.chunkSize[0]-1]
        for y in [0..self.chunkSize[1]-1]
          chunk.set(self.generator.noise2D((x + cx * (self.chunkSize[0] - 1)) / self.scale, (y + cy * (self.chunkSize[1] - 1)) / self.scale) * self.scale, x, y)
      ), {
        ondone: =>
          self.generatingChunk = null
          self.chunks.set(chunk, cx, cy)
          self.geometry.generateGeometry(chunk, [cx, cy], (geometry) =>
            geometry.computeFaceNormals()
            mesh = new THREE.Mesh(geometry, new THREE.MeshLambertMaterial({
              vertexColors: THREE.VertexColors}))
            mesh.position.x = cx * (self.chunkSize[0] - 1) * self.tileSize
            mesh.position.z = cy * (self.chunkSize[1] - 1) * self.tileSize
            self.meshes.push mesh
            console.log('Adding to scene', self.scene)
            self.scene.add mesh
          )
      })
    worker.run()




supersecret.Game = class NoiseGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @scene.fog = new THREE.FogExp2( 0x333333, 0.00008 );
    @person = new FirstPerson(container, @camera)
    @setTransform('speed', parseFloat)

    @chunkSize = [16, 16]
    @tileSize = 32
    @world = new World(@scene, @chunkSize, @tileSize)
    #@world.generateChunk(0, 0)
    seed = null
    recreateWorld = (description) =>
      Math.seedrandom(seed)
      @world.replaceNoiseGenerator(description or @world.generator.description)
      @world.initChunks()
      @world.unloadMeshes()
    
    background =
      color: 0
      opacity: 1
    setBackground = =>
      @setClearColor(background.color, background.opacity)
    
    @setTransform('bg', (n) -> parseInt(n, 16))
    @watch('bg', (v) =>
      background.color = v
      setBackground())
    @setTransform('bgo', parseFloat)
    @watch('bgo', (v) =>
      background.opacity = v
      setBackground())
    @setTransform('scale', parseFloat)
    @watch('scale', (v) =>
      @world.scale = v
      recreateWorld()
    )
    @setTransform('chunksize', parseInt)
    @watch('chunksize', (v) =>
      return if not v?
      for i in [0..@chunkSize.length-1]
        @chunkSize[i] = v
      recreateWorld()
    )
    @watch('speed', (v) =>
      return if not v?
      @person.speed = v)
    @watch('seed', (v) =>
      seed = v
      recreateWorld()
    )
    @watch('colors', (v) =>
      return if not v
      colorpairs = v.split(':')
      colors = []
      for pair in colorpairs
        pair = pair.split(',')
        i = 0
        mh = null
        if pair.length > 1
          mh = parseInt(pair[i++])
        c = parseInt(pair[i], 16)
        if not mh?
          mh = Infinity
        colors.push([mh, c])
      recreateWorld()
    )
    @watch('noise', (v) =>
      return if not v
      # The format is as follows:
      # +#.#,#.#+#.#,#.#
      layers = []
      currentLayer = null
      currentNumber = null
      for char in v
        switch char
          when '+', '*'
            if currentNumber?
              currentLayer.multiplier = parseFloat(currentNumber)
              currentNumber = null
            if currentLayer
              layers.push currentLayer
            currentLayer = {}
            if char == '*'
              currentLayer.op = (a, b) -> a*((b+1)/2)
          when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.'
            if not currentNumber
              currentNumber = ''
            currentNumber += char
          when ','
            if currentNumber?
              currentLayer.scale = parseFloat(currentNumber)
              currentNumber = null
      if currentNumber?
        currentLayer.multiplier = parseFloat(currentNumber)
      layers.push currentLayer
      recreateWorld(layers)

    )

  initLights: ->
    @scene.add @light = new THREE.AmbientLight(0x333333)
    @scene.add @light = new THREE.DirectionalLight(0xffffff, 1)
    @light.position.y = Math.random() * .5 + 0.25
    @light.position.z = Math.random() - 0.5
    @light.position.x = Math.random() - 0.5
    @scene.add @light = new THREE.DirectionalLight(0xffffff, 1)
    @light.position.y = Math.random() * .5 + 0.25
    @light.position.z = Math.random() - 0.5
    @light.position.x = Math.random() - 0.5

  update: (delta) ->
    for x in [-5..5]
      for y in [-5..5]
        @world.maybeGenerateChunk(@camera.position.x / @tileSize + x * @chunkSize[0], @camera.position.z / @tileSize + y * @chunkSize[1])
    @world.maybeGenerateChunk(@camera.position.x / @tileSize, @camera.position.z / @tileSize)
    @world.update(delta)
    @person.update(delta)
