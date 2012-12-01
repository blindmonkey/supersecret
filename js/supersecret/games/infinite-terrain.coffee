lib.load('firstperson', 'facemanager', 'grid', ->
  supersecret.Game.loaded = true)


class NoiseGenerator
  constructor: (noise, description) ->
    @noise = noise
    @description = description

  noise2D: (x, y) ->
    s = 0
    for layer in @description
      scale = layer.scale or 1
      offset = layer.offset or 0
      multiplier = layer.multiplier or 1
      s += @noise.noise2D(x * scale, y * scale) * multiplier - offset
    return s

  noise3D: (x, y, z) ->
    s = 0
    for layer in @description
      scale = layer.scale or 1
      offset = layer.offset or 0
      multiplier = layer.multiplier or 1
      s += @noise.noise3D(x * scale, y * scale, z * scale) * multiplier - offset
    return s

  noise4D: (x, y, z, w) ->
    s = 0
    for layer in @description
      scale = layer.scale or 1
      offset = layer.offset or 0
      multiplier = layer.multiplier or 1
      s += @noise.noise3D(x * scale, y * scale, z * scale, w * scale) * multiplier - offset
    return s

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false
  constructor: (container, width, height, opt_scene, opt_camera) ->
    params = getQueryParams()
    @viewAngle = parseFloat(params.viewAngle) or 90

    @gridSize = [64, 64]
    @cellSize = 5

    noise = new NoiseGenerator(new SimplexNoise(),[
      { scale:1/256, multiplier: 256 }
      { scale:1/128, multiplier: 128 }
      { scale:1/64, multiplier: 64 }
      { scale:1/32, multiplier: 32 }
      { scale:1/16, multiplier: 16 }
      { scale:1/8, multiplier: 8 }
      { scale:1/4, multiplier: 4 }
      { scale:1/2, multiplier: 2 }
      { scale:1/1, multiplier: 1 }
    ])

    @chunks = new Grid(2, [Infinity, Infinity])
    @chunks.handleEvent('missing', ((coords...) ->
      t = new Date().getTime()
      console.log("Generating chunk" + coords)
      chunk = new Grid(2, @gridSize)
      for x in [0..@gridSize[0] - 1]
        for y in [0..@gridSize[1] - 1]
          n = noise.noise2D(x + coords[0] * (@gridSize[0] - 1), y + coords[1] * (@gridSize[1] - 1))
          if n < 0
           n = 0
          chunk.set(n, x, y)
      data =
        chunk: chunk
      @chunks.set(data, coords...)
      @generateChunkGeometry(coords...)

      console.log('Chunk ' + coords + ' generated in ' + (new Date().getTime() - t))
    ).bind(this))

    @faceManager = new FaceManager()

    super(container, width, height, opt_scene, opt_camera)
    for x in [-1..1]
      for y in [-1..1]
        @chunks.get(x, y)

    @person = new FirstPerson(container, @camera)

  generateChunkGeometry: (coords...) ->
    # if not @chunks.exists(coords...)
    #   return
    t = new Date().getTime()
    console.log('Generating mesh for ' + coords)
    faceManager = new FaceManager()
    [cx, cy] = coords
    data = @chunks.get(coords...)
    chunk = data.chunk

    doGeometryGeneration = (->
      console.log('in set timeout')
      geometry = faceManager.generateGeometry()
      geometry.computeFaceNormals()
      data.mesh = mesh = new THREE.Mesh(geometry,
        new THREE.MeshPhongMaterial({color: 0xff0000}))
      @chunks.set(data, coords...)
      @scene.add mesh
    ).bind(this)

    lastUpdated = new Date().getTime()
    continueX = ((xx) ->
      console.log('Mesh generation for ' + coords + ' in progress -- ' + Math.round(xx / (chunk.size[0] - 2) * 100) + '% done')
      for x in [xx..chunk.size[0] - 2]
        for z in [0..chunk.size[1] - 2]
          xx = cx * (@gridSize[0] - 1) * @cellSize + x * @cellSize
          zz = cy * (@gridSize[1] - 1) * @cellSize + z * @cellSize
          v = chunk.get(x, z)
          vr = chunk.get(x + 1, z)
          vb = chunk.get(x, z + 1)
          vbr = chunk.get(x + 1, z + 1)

          faceManager.addFace(
            [xx, v, zz],
            [xx, vb, zz + @cellSize],
            [xx + @cellSize, vr, zz])
          faceManager.addFace(
            [xx + @cellSize, vr, zz],
            [xx, vb, zz + @cellSize],
            [xx + @cellSize, vbr, zz + @cellSize])
        if new Date().getTime() - lastUpdated > 100 and chunk.size[0] - x > 10
          setTimeout((-> continueX(x + 1)), 100)
          return
      doGeometryGeneration()
    ).bind(this)
    continueX(0)
    if data.mesh
      @scene.remove(data.mesh)
      #new THREE.MeshBasicMaterial({color: 0xff0000, wireframe: true})
      #)
    console.log('Mesh generated for ' + coords + ' in ' + (new Date().getTime() - t))
    console.log('registering settimout')
    #return mesh

  initGeometry: ->
    @scene.add new THREE.Mesh(
      new THREE.SphereGeometry(1, 16, 16),
      new THREE.LineBasicMaterial({color: 0x00ff00})
      )
    # chunk = @chunks.get(0, 0)
    # for x in [0..chunk.size[0] - 2]
    #   for z in [0..chunk.size[1] - 2]

    #     v = chunk.get(x, z)
    #     vr = chunk.get(x + 1, z)
    #     vb = chunk.get(x, z + 1)
    #     vbr = chunk.get(x + 1, z + 1)
    #     faceManager.addFace([x, v, z], [x,     vb, z + 1], [x + 1, vr, z])
    #     faceManager.addFace([x + 1, vr, z], [x, vb, z + 1], [x + 1, vbr, z + 1])
    # geometry = @faceManager.generateGeometry()
    # geometry.computeFaceNormals()
    # @mesh = new THREE.Mesh(geometry,
    #   new THREE.MeshPhongMaterial({color: 0xff0000})
    #   #new THREE.MeshBasicMaterial({color: 0xff0000, wireframe: true})
    #   )
    # @scene.add @mesh

  initLights: ->
    @scene.add new THREE.AmbientLight(0x505050)
    light = new THREE.DirectionalLight(0xffffff, 1)
    light.position.x = 1
    light.position.y = 1
    light.position.z = 0
    light.target.position.x = 0
    light.target.position.y = 0
    light.target.position.z = 0
    @scene.add light

    # light = new THREE.PointLight(0xffffff, 1, 5000)
    # light.position.x = 1
    # light.position.y = 20
    # light.position.z = 0
    # @scene.add light


  render: (delta) ->
    x = Math.floor(@camera.position.x / (@gridSize[0] * @cellSize))
    z = Math.floor(@camera.position.z / (@gridSize[1] * @cellSize))
    if not @chunks.exists(x, z)
      console.log('Get chunk ' + x + ', ' + z)
      @chunks.get(x, z)
      #@initGeometry()
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)
