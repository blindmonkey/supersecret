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

    @gridSize = [20, 20]
    @cellSize = 5

    noise = new NoiseGenerator(new SimplexNoise(),[
      { scale:1/256, multiplier: 256 }
      { scale:1/128, multiplier: 128 }
      { scale:1/64, multiplier: 64 }
      { scale:1/32, multiplier: 32 }
      { scale:1/16, multiplier: 16 }
      { scale:1/8, multiplier: 8 }
    ])
    @chunks = new Grid(2, [Infinity, Infinity])
    @chunks.handleEvent('missing', ((coords...) ->
      console.log("Generating chunk" + coords)
      chunk = new Grid(2, @gridSize)
      for x in [0..@gridSize[0] - 1]
        for y in [0..@gridSize[1] - 1]
          n = noise.noise2D(x + coords[0] * @gridSize[0], y + coords[1] * @gridSize[1])
          if n < 0
           n = 0
          chunk.set(n, x, y)
      @chunks.set(chunk, coords...)
    ).bind(this))

    for x in [-4..4]
      for y in [-4..4]
        @chunks.get(x, y)
    @faceManager = new FaceManager()

    super(container, width, height, opt_scene, opt_camera)

    @person = new FirstPerson(container, @camera)

  initGeometry: ->
    @scene.remove @mesh
    @scene.add new THREE.Mesh(
      new THREE.SphereGeometry(1, 16, 16),
      new THREE.LineBasicMaterial({color: 0x00ff00})
      )

    @chunks.forEach(((coords...) ->
      if not @chunks.exists(coords...)
        return
      [cx, cy] = coords
      chunk = @chunks.get(coords...)
      for x in [0..chunk.size[0] - 1]
        for z in [0..chunk.size[1] - 1]
          xx = cx * @gridSize[0] * @cellSize + x * @cellSize
          zz = cy * @gridSize[1] * @cellSize + z * @cellSize
          v = chunk.get(x, z)
          vr = null
          vb = null
          vbr = null
          if x < chunk.size[0] - 1
            vr = chunk.get(x + 1, z)
          else if @chunks.exists(cx + 1, cy)
            vr = @chunks.get(cx + 1, cy).get(0, z)

          if z < chunk.size[1] - 1
            vb = chunk.get(x, z + 1)
          else if @chunks.exists(cx, cy + 1)
            vb = @chunks.get(cx, cy + 1).get(x, 0)

          if x < chunk.size[0] - 1 and z < chunk.size[1] - 1
            vbr = chunk.get(x + 1, z + 1)
          else if x >= chunk.size[0] - 1 and z >= chunk.size[1] - 1 and @chunks.exists(cx + 1, cy + 1)
            vbr = @chunks.get(cx + 1, cy + 1).get(0, 0)
          else if x < chunk.size[0] - 1 and @chunks.exists(cx, cy + 1)
            vbr = @chunks.get(cx, cy + 1).get(x + 1, 0)
          else if z < chunk.size[1] - 1 and @chunks.exists(cx + 1, cy)
            vbr = @chunks.get(cx + 1, cy).get(0, z + 1)

          if vr? and vb? and vbr?
            @faceManager.addFace(
              [xx, v, zz],
              [xx, vb, zz + @cellSize],
              [xx + @cellSize, vr, zz])
            @faceManager.addFace(
              [xx + @cellSize, vr, zz],
              [xx, vb, zz + @cellSize],
              [xx + @cellSize, vbr, zz + @cellSize])
    ).bind(this))
    # chunk = @chunks.get(0, 0)
    # for x in [0..chunk.size[0] - 2]
    #   for z in [0..chunk.size[1] - 2]

    #     v = chunk.get(x, z)
    #     vr = chunk.get(x + 1, z)
    #     vb = chunk.get(x, z + 1)
    #     vbr = chunk.get(x + 1, z + 1)
    #     faceManager.addFace([x, v, z], [x,     vb, z + 1], [x + 1, vr, z])
    #     faceManager.addFace([x + 1, vr, z], [x, vb, z + 1], [x + 1, vbr, z + 1])
    geometry = @faceManager.generateGeometry()
    geometry.computeFaceNormals()
    @mesh = new THREE.Mesh(geometry,
      new THREE.MeshPhongMaterial({color: 0xff0000})
      #new THREE.MeshBasicMaterial({color: 0xff0000, wireframe: true})
      )
    @scene.add @mesh

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
      @chunks.get(x, z)
      @initGeometry()
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)
