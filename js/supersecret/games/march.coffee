lib.load(
  'facemanager',
  'firstperson',
  'grid',
  'marchingcubes',
  'now',
  'set',
   -> supersecret.Game.loaded = true)

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


class World
  constructor: (chunkSize, cubeSize, scene) ->
    @chunkSize = chunkSize
    @cubeSize = cubeSize
    @scene = scene
    @dirty = new Set()
    @geometry = new Grid(3, [Infinity, Infinity, Infinity])
    @chunks = new Grid(3, [Infinity, Infinity, Infinity])
    @seaLevel = @chunkSize[1] / 2
    @scale = [2, 1, 2]
    @noise = new NoiseGenerator(new SimplexNoise(), [{
        scale: 1 / 32
      }, {
        scale: 1 / 64
        multiplier: 1 / 2
      }, {
        scale: 1 / 128
        multiplier: 1 / 3
      }, {
        scale: 1 / 256
        multiplier: 1 / 4
        }])
    @lod = new THREE.LOD()
    @scene.add @lod

    DEBUG.expose('world', this)

  generateChunk: (cx, cy, cz, callback) ->
    leftNeighbor = @chunks.exists(cx - 1, cy, cz)
    rightNeighbor = @chunks.exists(cx + 1, cy, cz)
    upNeighbor = @chunks.exists(cx, cy + 1, cz)
    downNeighbor = @chunks.exists(cx, cy - 1, cz)
    frontNeighbor = @chunks.exists(cx, cy, cz+1)
    backNeighbor = @chunks.exists(cx, cy, cz-1)
    chunk = new Grid(3, @chunkSize)
    @chunks.set(chunk, cx, cy, cz)
    mx = @chunkSize[0]-1
    my = @chunkSize[1]-1
    mz = @chunkSize[2]-1
    lastUpdate = now()
    continueY = ((start) ->
      console.log('continueY: (' + cx + ', ' + cy + ', ' + cz + ') ' + start + '-' + my)
      for y in [start..my]
        for x in [0..mx]
          for z in [0..mz]
            n = @noise.noise3D(
              (x + cx * @chunkSize[0]) / @scale[0],
              (y + cy * @chunkSize[1]) / @scale[1],
              (z + cz * @chunkSize[2]) / @scale[2]) - (y + cy * @chunkSize[1] - @seaLevel) / 32
            chunk.set(n > 0, x, y, z)
            @dirty.add @getAbsolutePosition(x, y, z, cx, cy, cz)
            if x == 0 and leftNeighbor
              @dirty.add(@getAbsolutePosition(mx, y, z, cx - 1, cy, cz))
            else if x == mx and rightNeighbor
              @dirty.add(@getAbsolutePosition(0, y, z, cx + 1, cy, cz))
            if z == 0 and backNeighbor
              @dirty.add(@getAbsolutePosition(x, y, mz, cx, cy, cz - 1))
            else if z == mz and frontNeighbor
              @dirty.add(@getAbsolutePosition(x, y, 0, cx, cy, cz + 1))
        if y < my and now() - lastUpdate > 100
          setTimeout((-> continueY(y + 1)), 100)
          return
      callback and callback()
    ).bind(this)
    continueY(0)

  generateChunkGeometry: (cx, cy, cz) ->
    throw 'This should not be called anymore'
    chunk = @chunks.get(cx, cy, cz)
    #cubes = null
    geo = null
    if not @geometry.exists(cx, cy, cz)
      cubes = new MarchingCubes(@cubeSize)
      geo =
        cubes: cubes
      @geometry.set(geo, cx, cy, cz)
    else
      geo = @geometry.get(cx, cy, cz)
    geometry = geo.cubes.generateGeometry(((x, y, z) ->
      return @get(
        x + cx * @chunkSize[0],
        y + cy * @chunkSize[1],
        z + cz * @chunkSize[2])
    ).bind(this), ([0, size-1] for size in @chunkSize)...)

    geometry.computeFaceNormals()
    console.log('finished adding mesh')
    @lod.add geo.mesh = @createMesh(geometry, cx, cy, cz)
    console.log(geo.mesh.position.x, geo.mesh.position.y, geo.mesh.position.z)

  createMesh: (geometry, cx, cy, cz) ->
    mesh = new THREE.Mesh(
      geometry,
      new THREE.MeshBasicMaterial({color: 0x00ff00, wireframe: true})
      #new THREE.MeshPhongMaterial({color: 0x00ff00, ambient: 0x00ff00})
    )
    mesh.position.x = cx * @cubeSize * (@chunkSize[0])
    mesh.position.y = cy * @cubeSize * (@chunkSize[1])
    mesh.position.z = cz * @cubeSize * (@chunkSize[2])
    return mesh

  getAbsolutePosition: (x, y, z, cx, cy, cz) ->
    return [
      cx * @chunkSize[0] + x
      cy * @chunkSize[1] + y
      cz * @chunkSize[2] + z
    ]


  getRelativePosition: (x, y, z) ->
    cx = Math.floor(x / @chunkSize[0])
    cy = Math.floor(y / @chunkSize[1])
    cz = Math.floor(z / @chunkSize[2])
    chunk = @chunks.get(cx, cy, cz)
    if chunk is undefined
      return undefined
    if cx >= 0
      x -= cx * @chunkSize[0]
    else
      x += @chunkSize[0] * -cx
    if cy >= 0
      y -= cy * @chunkSize[1]
    else
      y += @chunkSize[1] * -cy
    if cz >= 0
      z -= cz * @chunkSize[2]
    else
      z += @chunkSize[2] * -cz
    return {
      chunk: chunk
      cx: cx
      cy: cy
      cz: cz
      x: x
      y: y
      z: z
    }

  update: (delta) ->
    @updateGeometry()

  updateGeometry: ->
    return if @dirty.length == 0
    console.log('in updateGeometry', @dirty.length)
    realDirty = new Set()
    @dirty.forEachPop(((p) ->
      [x, y, z] = p
      for dx in [0, 1]
        for dy in [0, 1]
          for dz in [0, 1]
            realDirty.add [x - dx, y - dy, z - dz]
    ).bind(this))
    console.log('After popping: ', @dirty.length)

    dirtyChunks = new Set()

    realDirty.forEach(((p) ->
      [x, y, z] = p
      a = @getRelativePosition(x, y, z)
      return if a is undefined
      geo = null
      if not @geometry.exists(a.cx, a.cy, a.cz)
        cubes = new MarchingCubes(@chunkSize, @cubeSize)
        geo =
          cubes: cubes
        @geometry.set(geo, a.cx, a.cy, a.cz)
      else
        geo = @geometry.get(a.cx, a.cy, a.cz)
      #geo = @geometry.get(a.cx, a.cy, a.cz)
      #cubes = geo.cubes
      #mesh = geo.mesh
      #cubes.updateCube(@get.bind(this), x, y, z)
      geo.cubes.updateCube(((x, y, z) ->
        return @get(
          x + a.cx * @chunkSize[0],
          y + a.cy * @chunkSize[1],
          z + a.cz * @chunkSize[2])
      ).bind(this), a.x, a.y, a.z)
      dirtyChunks.add [a.cx, a.cy, a.cz]
    ).bind(this))

    dirtyChunks.forEach(((c) ->
      [cx, cy, cz] = c
      geo = @geometry.get(cx, cy, cz)
      g = geo.cubes.getGeometry()
      if !geo.mesh or g != geo.mesh.geometry
        @lod.remove geo.mesh
        console.log( 'updating geometry')
        @lod.add geo.mesh = @createMesh(g, cx, cy, cz)
      console.log('computing face normals...')
      g.computeFaceNormals()
      g.normalsNeedUpdate = true
      console.log('done')
    ).bind(this))

  set: (data, x, y, z) ->
    a = @getRelativePosition(x, y, z)
    return undefined if a is undefined
    r = a.chunk.set(data, a.x, a.y, a.z)
    @dirty.add [x, y, z]
    return r

  get: (x, y, z) ->
    a = @getRelativePosition(x, y, z)
    return undefined if a is undefined
    return a.chunk.get(a.x, a.y, a.z)


supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false
  constructor: (container, width, height, opt_scene, opt_camera) ->
    params = getQueryParams()
    @viewAngle = parseFloat(params.viewAngle) or 90

    noise = new SimplexNoise()
    @noise = new NoiseGenerator(noise, [{
        scale: 1 / 32
      }, {
        scale: 1 / 64
        multiplier: 1 / 2
      }, {
        scale: 1 / 128
        multiplier: 1 / 3
      }, {
        scale: 1 / 256
        multiplier: 1 / 4
        }])
    @chunkSize = [32, 128, 32]
    horizontalScale = 2
    verticalScale = 1
    @cubeSize = 4
    seaLevel = @chunkSize[1] / 2


    #@chunks = new Grid(3, [Infinity, Infinity, Infinity])
    super(container, width, height, opt_scene, opt_camera)
    @person = new FirstPerson(container, @camera)

    @world = new World(@chunkSize, @cubeSize, @scene)
    @world.generateChunk(0, 0, 0)
    #@world.generateChunkGeometry(0, 0, 0)
    #@world.generateChunk(1, 0, 0)
    #@world.generateChunkGeometry(1, 0, 0)

    @selectedChunk =
      x: 0
      y: 0
      z: 0

    geometry = new THREE.Geometry()
    m = (@chunkSize[i] * @cubeSize for i in [0..2])
    addVertex = (x, y, z) ->
      geometry.vertices.push new THREE.Vector3(x, y, z)
    addVertex(0, 0, 0)
    addVertex(m[0], 0, 0)
    addVertex(m[0], 0, 0)
    addVertex(m[0], 0, m[2])
    addVertex(m[0], 0, m[2])
    addVertex(0, 0, m[2])
    addVertex(0, 0, 0)
    addVertex(0, m[1], 0)
    addVertex(m[0], m[1], 0)
    addVertex(m[0], m[1], 0)
    addVertex(m[0], m[1], m[2])
    addVertex(m[0], m[1], m[2])
    addVertex(0, m[1], m[2])
    addVertex(0, m[1], 0)

    @selectedMesh = new THREE.Line(geometry, new THREE.LineBasicMaterial({color:0x0000ff}), THREE.Lines)
    @scene.add @selectedMesh
    $(document).keydown(((e) ->
      switch e.keyCode
        when 74 # J
          @selectedChunk.x -= 1
        when 76 # L
          @selectedChunk.x += 1
        when 73 # I
          @selectedChunk.z -= 1
        when 75 # K
          @selectedChunk.z += 1
        when 85 # U
          @selectedChunk.y -= 1
        when 79 # O
          @selectedChunk.y += 1
        when 71 # G
          @world.generateChunk(@selectedChunk.x, @selectedChunk.y, @selectedChunk.z)
          @world.generateChunkGeometry(@selectedChunk.x, @selectedChunk.y, @selectedChunk.z)
      @selectedMesh.position.x = @selectedChunk.x * @cubeSize * @chunkSize[0]
      @selectedMesh.position.y = @selectedChunk.y * @cubeSize * @chunkSize[1]
      @selectedMesh.position.z = @selectedChunk.z * @cubeSize * @chunkSize[2]
      console.log(@selectedChunk.x + ', ' + @selectedChunk.y + ', ' + @selectedChunk.z)
    ).bind(this))


  initGeometry: ->
    @scene.add m = new THREE.Mesh(
      new THREE.SphereGeometry(1, 16, 16),
      new THREE.LineBasicMaterial({color: 0xff0000})
      )
    m.position.x = 5
    m.position.y = 5
    m.position.z = 5

  initLights: ->
    @scene.add new THREE.AmbientLight(0x505050)
    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.x = 1
    light.position.y = 1
    light.position.z = 1
    @scene.add light
    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.x = -1
    light.position.y = 1
    light.position.z = -1
    @scene.add light
    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.x = -1
    light.position.y = -1
    light.position.z = -1
    @scene.add light
    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.x = 1
    light.position.y = -1
    light.position.z = 1
    @scene.add light

  render: (delta) ->
    @world.update(delta)
    @world.lod.update(@camera)
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)
