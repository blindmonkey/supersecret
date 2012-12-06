lib.load(
  'facemanager',
  'firstperson',
  'grid',
  'marchingcubes',
  'now',
  'set',
  'updater',
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

doAsync = (f, callback) ->
  w = new AsyncWorker(f, {
    ondone: callback
  })
  w.run()
  return w


class World
  constructor: (chunkSize, cubeSize, scene) ->
    @chunkSize = chunkSize
    @cubeSize = cubeSize
    @scene = scene
    @dirty = new Set()
    @geometry = new Grid(3, [Infinity, Infinity, Infinity])
    @chunks = new Grid(3, [Infinity, Infinity, Infinity])
    @dirtyChunks = new Set()
    @updateCache = new Grid(3, [Infinity, Infinity, Infinity])
    @seaLevel = @chunkSize[1] / 2
    @scale = [2, 1, 2]
    @updatingGeometry = false
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
    @updater = new Updater(1000)
    @updater.setFrequency('pulse', 10000)
    @updater.setFrequency('chunkRefresh', 1500)

    @chunkGenerationSet = new Set()
    @generatingChunk = null
    @synchronous = false

    WorkerPool.setPauseTime(10)
    WorkerPool.setCycleTime(300)

    DEBUG.expose('world', this)

  generateChunk: (cx, cy, cz, callback) ->
    @chunkGenerationSet.add [cx, cy, cz]

  addDirty: (position) ->
    @updater.update('addDirty', position)
    [x, y, z] = position
    @dirty.add position
    return
    @updater.update('addDirty/async', 'Doing ' + x + ', ' + y + ', ' + z)
    for dx in [0, 1]
      for dy in [0, 1]
        for dz in [0, 1]
          p = [x - dx, y - dy, z - dz]
          a = @getRelativePosition(p...)
          if a isnt undefined #and @blockNeedsUpdate(p...)
            @dirty.add p

  generateChunkGeometry: (cx, cy, cz) ->
    #throw 'This should not be called anymore'
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
    ).bind(this), ([-1, size] for size in @chunkSize)...)

    geometry.computeFaceNormals()
    console.log('finished adding mesh')
    @lod.add geo.mesh = @createMesh(geometry, cx, cy, cz)
    console.log(geo.mesh.position.x, geo.mesh.position.y, geo.mesh.position.z)

  createMesh: (geometry, cx, cy, cz) ->
    mesh = new THREE.Mesh(
      geometry,
      #new THREE.MeshBasicMaterial({color: 0x00ff00, wireframe: true})
      new THREE.MeshPhongMaterial({ vertexColors: THREE.FaceColors}) # {color: 0x00ff00, ambient: 0x00ff00})
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
    if not @generatingChunk? and @chunkGenerationSet.length > 0
      generationStart = now()
      @generatingChunk = @chunkGenerationSet.pop()
      [cx, cy, cz] = @generatingChunk
      console.log("Starting generation for chunk " + cx + ', ' + cy + ', ' + cz)
      chunk = new Grid(3, @chunkSize)
      mx = @chunkSize[0]-1
      my = @chunkSize[1]-1
      mz = @chunkSize[2]-1
      lastUpdate = now()
      dirtySet = new Set()

      chunk.handleEvent('missing', ((x, y, z) ->
        n = @noise.noise3D(
          (x + cx * @chunkSize[0]) / @scale[0],
          (y + cy * @chunkSize[1]) / @scale[1],
          (z + cz * @chunkSize[2]) / @scale[2]) - (y + cy * @chunkSize[1] - @seaLevel) / 32
        chunk.set(n > 0, x, y, z)
      ).bind(this))

      @chunks.set(chunk, cx, cy, cz)

      stats =
        added: 0
        skipped: 0
      worker = new NestedForWorker([[-1,my+2], [-1,mx+2], [-1,mz+2]], ((y, x, z) ->
        @updater.update('generateChunk.worker', 'Position:' + [x, y, z] + '. Added: ' + stats.added + ', skipped: ' + stats.skipped)
        position = @getAbsolutePosition(x, y, z, cx, cy, cz)
        neighbors = @getNeighbors(position...)
        expected = neighbors[0]
        for n in neighbors
          if n != expected
            stats.added++
            @addDirty position
            return
        stats.skipped++
      ).bind(this), {
        ondone: (->
          console.log('Chunk generated in ' + (now() - generationStart))
          @generatingChunk = null
        ).bind(this)
      })
      worker.synchronous = @synchronous
      worker.run()

    #@updater.update('update/dirtyReport', 'Currently there are ' + @dirty.length + ' dirty blocks')
    @updateGeometry()

  getAllNeighbors: (x, y, z) ->
    neighbors = []
    for dx in [0, 1]
      for dy in [0, 1]
        for dz in [0, 1]
          p = [x - dx, y - dy, z - dz]
          neighbors.push @get(p...)
    return neighbors

  getNeighbors: (x, y, z) ->
    neighbors = []
    for dx in [0..1]
      for dy in [0..1]
        for dz in [0..1]
          p = [x - dx, y - dy, z - dz]
          neighbors.push @get(p...)
    return neighbors

  markClean: (x, y, z) ->
    a = @getRelativePosition(x, y, z)
    return if a.chunk is undefined
    cacheChunk = @updateCache.get(a.cx, a.cy, a.cz)
    if not cacheChunk
      cacheChunk = new Grid(3, @chunkSize)
      @updateCache.set(cacheChunk, a.cx, a.cy, a.cz)
    neighbors = @getNeighbors(x, y, z)
    cacheChunk.set(neighbors, a.x, a.y, a.z)

  blockNeedsUpdate: (x, y, z) ->
    a = @getRelativePosition(x, y, z)
    return false if a.chunk is undefined
    neighbors = @getNeighbors(x, y, z)
    cacheChunk = @updateCache.get(a.cx, a.cy, a.cz)
    return true if not cacheChunk
    cachedNeighbors = cacheChunk.get(a.x, a.y, a.z)
    return true if not cachedNeighbors

    if neighbors.length != cachedNeighbors.length
      throw 'Actual neighbors and cached neighbors are not the same length'

    for i in [0..neighbors.length-1]
      if neighbors[i] != cachedNeighbors[i]
        return true
    return false

  refreshChunkGeometry: (cx, cy, cz) ->
    geo = @geometry.get(cx, cy, cz)
    return if not geo
    g = geo.cubes.getGeometry()
    if !geo.mesh or g != geo.mesh.geometry
      @lod.remove geo.mesh
      console.log( 'updating geometry')
      @lod.add geo.mesh = @createMesh(g, cx, cy, cz)
    console.log('computing face normals for ' + cx + ', ' + cy + ', ' + cz)
    g.computeFaceNormals()
    g.normalsNeedUpdate = true
    console.log('done')


  updateGeometry: ->
    return if @dirty.length == 0 or @updatingGeometry
    t = new Timer()
    #console.log('in updateGeometry', @dirty.length)
    # realDirty = new Set()
    # @dirty.forEachPop(((p) ->
    #   [x, y, z] = p
    #   for dx in [0, 1]
    #     for dy in [0, 1]
    #       for dz in [0, 1]
    #         realDirty.add [x - dx, y - dy, z - dz]
    # ).bind(this))

    t.start('updateGeometry')
    #dirtyChunks = new Set()
    @updatingGeometry = true

    updateStart = now()
    skipCount = 0
    w = @dirty.forEachPopAsync(((p) ->
      if not @blockNeedsUpdate(p...)
        skipCount++
        return
      @markClean(p...)
      @updater.update('dirtyPop', 'Dirty vertices left: ' + @dirty.length + '; skipped: ' + skipCount)
      # doAsync((->
      [x, y, z] = p
      for dx in [0..1]
        for dy in [0..1]
          for dz in [0..1]
            pos = [x - dx, y - dy, z - dz]
            a = @getRelativePosition(pos...)
            if a.chunk isnt undefined #and @blockNeedsUpdate(pos...)
              #@dirty.add p
              #a = @getRelativePosition(x, y, z)
              geo = null
              if not @geometry.exists(a.cx, a.cy, a.cz)
                cubes = new MarchingCubes(@chunkSize, @cubeSize)
                geo =
                  cubes: cubes
                @geometry.set(geo, a.cx, a.cy, a.cz)
              else
                geo = @geometry.get(a.cx, a.cy, a.cz)

              geo.cubes.updateCube(((x, y, z) ->
                return @get(
                  x + a.cx * @chunkSize[0],
                  y + a.cy * @chunkSize[1],
                  z + a.cz * @chunkSize[2])
              ).bind(this), a.x, a.y, a.z)
              @dirtyChunks.add [a.cx, a.cy, a.cz]
      # ).bind(this))
    ).bind(this), (->
      console.log('----- Chunk geometry generation complete in ' + (now() - updateStart))
      @updatingGeometry = false
      @dirtyChunks.forEachPop(((c) ->
        @refreshChunkGeometry(c...)
      ).bind(this))
    ).bind(this))
    w.synchronous = @synchronous
    w.cycle = 500


  set: (data, x, y, z) ->
    a = @getRelativePosition(x, y, z)
    return undefined if a.chunk is undefined
    r = a.chunk.set(data, a.x, a.y, a.z)
    @dirty.add [x, y, z]
    return r

  get: (x, y, z) ->
    a = @getRelativePosition(x, y, z)
    return undefined if a.chunk is undefined
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
    #@world.generateChunk(0, 0, 0)
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
    vpositions = [[0, 0], [m[0], 0], [m[0], m[2]], [0, m[2]]]
    for i in [0..vpositions.length - 1]
      j = (i+1) % vpositions.length
      ii = vpositions[i]
      jj = vpositions[j]
      addVertex(ii[0], 0, ii[1])
      addVertex(jj[0], 0, jj[1])
      addVertex(ii[0], m[1], ii[1])
      addVertex(jj[0], m[1], jj[1])
      addVertex(ii[0], 0, ii[1])
      addVertex(ii[0], m[1], ii[1])

    @selectedMesh = new THREE.Line(geometry, new THREE.LineBasicMaterial({color:0x00ffff}), THREE.LinePieces)
    @scene.add @selectedMesh
    $(document).keydown(((e) ->
      last =
        x: @selectedChunk.x
        y: @selectedChunk.y
        z: @selectedChunk.z
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
          #@world.generateChunkGeometry(@selectedChunk.x, @selectedChunk.y, @selectedChunk.z)
        when 82 # R
          @world.refreshChunkGeometry(@selectedChunk.x, @selectedChunk.y, @selectedChunk.z)
        when 86 # V
          @world.synchronous = not @world.synchronous
      if last.x != @selectedChunk.x or last.y != @selectedChunk.y or last.z != @selectedChunk.z
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
