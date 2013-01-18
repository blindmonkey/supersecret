lib.load(
  'emitter'
  'facemanager'
  'firstperson'
  'grid'
  'polygons'
  'set'
  -> supersecret.Game.loaded = true)

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  preinit: ->
    size = @watched.size or 64
    @gridSize = [size, size]
    @boxWidth = @watched.width or 100
    @boxHeight = @watched.height or 300
    @heightmap = new Grid(2, @gridSize)
    noise = new SimplexNoise()
    noise2 = new SimplexNoise()
    n = (x, y, d, m) ->
      return noise.noise2D(x / d, y / d) * m
    @heightmap.handleEvent('missing', (x, y) =>
      v = (n(x, y, 16, 1) +
        n(x, y, 10, 0.7) +
        n(x, y, 6, 0.4) +
        n(x, y, 3, 0.2))
      @heightmap.set(v, x, y))


  postinit: ->
    @person = new FirstPerson(container, @camera)
    @setTransform('speed', parseFloat)
    @watch 'speed', (v) =>
      @person.speed = v

    @setTransform('freq', parseInt)
    @emitter = new Emitter(=>
        return [Math.random() * @boxWidth - @boxWidth / 2, @boxHeight / 4 * Math.random() + @boxHeight, Math.random() * @boxWidth - @boxWidth / 2]
      , 50, new THREE.LineBasicMaterial({color: 0xffffff}), 5000)
    @watch('freq', (v) =>
      @emitter.frequency = v)

    @setTransform('impact', parseFloat)
    @scene.add @emitter.particles
    @emitter.handleEvent('create', (vertex, data) ->
      data.velocity =
        x: (Math.random() - 0.5) * 2
        z: (Math.random() - 0.5) * 2
        y: -Math.random() * 4 - 1
    )
    @emitter.handleEvent('update', (delta, vertex, data) ->
      delta = delta / 1000
      data.velocity.y -= 0.05
      data.velocity.x += (Math.random() - 0.5) / 4
      data.velocity.z += (Math.random() - 0.5) / 4
      vertex.x += data.velocity.x * delta
      vertex.y += data.velocity.y * delta
      vertex.z += data.velocity.z * delta
    )

    @dirtyVertices = new Set()
    @emitter.handleEvent('update', (delta, vertex, data) =>
      if vertex.y < 0 or vertex.y > @boxHeight * 2 or vertex.x < -@boxWidth / 2 or vertex.x > @boxWidth / 2 or vertex.z < -@boxWidth / 2 or vertex.z > @boxWidth / 2
        console.log('killed', vertex.x, vertex.y, vertex.z)
        data.kill = true
        if -@boxWidth / 2 < vertex.x < @boxWidth / 2 and -@boxWidth / 2 < vertex.z < @boxWidth / 2 and vertex.y < 0
          x = Math.floor(((vertex.x + @boxWidth / 2) + 0.5) / @boxWidth * @gridSize[0])
          y = Math.floor(((vertex.z + @boxWidth / 2) + 0.5) / @boxWidth * @gridSize[1])
          debugger if isNaN(x) or isNaN(y)
          @dirtyVertices.add [x, y]
          @dirtyVertices.add [x-1, y]
          @dirtyVertices.add [x, y-1]
          @dirtyVertices.add [x-1, y-1]
          if @dirtyVertices.contains([null, null])
            debugger
          #@updateVertex(vertex.x, vertex.z, @watched.impact or 0.05)
    )

  updateVertex: (x, y, h) ->
    #x = Math.floor(((x + @boxWidth / 2) + 0.5) / @boxWidth * @gridSize[0])
    #y = Math.floor(((y + @boxWidth / 2) + 0.5) / @boxWidth * @gridSize[1])
    return if not @heightmap.isValid(x, y) # TODO: This is stupid to just exit if it's an invalid coord. Make sure coords are never invalid
    v = @heightmap.get(x, y)
    @heightmap.set(v + h, x, y)
    for dx in [-1, 0]
      for dy in [-1, 0]
        if @gridFaces.isValid(x + dx, y + dy)
          @faces.removeFaces(@gridFaces.get(x + dx, y + dy)...)
          @addFaces(x + dx, y + dy)
    #@updateMesh()


  updateMesh: ->
    geometry = @faces.generateGeometry()
    geometry.computeFaceNormals()
    geometry.normalsNeedUpdate = true
    if not @mesh or @mesh.geometry != geometry
      @scene.remove @mesh
      @mesh = new THREE.Mesh(
        geometry
        #new THREE.MeshNormalMaterial({color: 0xffffff})
        new THREE.MeshLambertMaterial({color: 0xffffff})
      )
      @scene.add @mesh

  getPosition: (x, y) ->
    return [
      x / (@gridSize[0] - 1) * @boxWidth - @boxWidth / 2
      y / (@gridSize[1] - 1) * @boxWidth - @boxWidth / 2
    ]

  addFaces: (x, y) ->
    ch = @heightmap.get(x, y)
    chnx = @heightmap.get(x + 1, y)
    chny = @heightmap.get(x, y + 1)
    chnxy = @heightmap.get(x + 1, y + 1)
    pc = @getPosition(x, y)
    pnx = @getPosition(x + 1, y)
    pny = @getPosition(x, y + 1)
    pnxy = @getPosition(x + 1, y + 1)
    faces = @faces.addFace4(
      [pny[0], chny, pny[1]]
      [pnxy[0], chnxy, pnxy[1]]
      [pnx[0], chnx, pnx[1]]
      [pc[0], ch, pc[1]]
    )
    @gridFaces.set(faces, x, y)

  initGeometry: ->
    @gridFaces = new Grid(2, [@gridSize[0] - 1, @gridSize[1] - 1])
    @faces = new FaceManager(500)
    for x in [0..@gridSize[0]-2]
      for y in [0..@gridSize[1]-2]
        @addFaces(x, y)
    @updateMesh()

    @scene.add new THREE.Mesh(
      new THREE.SphereGeometry(0.01, 4, 4)
      )

  updateGeometry: ->
    @dirtyVertices.forEachPop(([x, y]) =>
      return if x == null
      @updateVertex(x, y, @watched.impact or 0.5)
    )
    #@dirtyVertices = new Set()
    @updateMesh()


  initLights: ->
    @scene.add @light = new THREE.DirectionalLight(0xffffff, .8)
    @light.position.y = 1
    @light.position.z = 1
    @light.position.x = 1


  update: (delta) ->
    @emitter.update(delta)
    @updateGeometry()
    @person.update(delta)
