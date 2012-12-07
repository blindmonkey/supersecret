lib.load(
  'facemanager',
  'firstperson',
  'format',
  'grid',
  'id',
  'marchingcubes',
  'map',
  'noisegenerator',
  'now',
  'set',
  'updater',

  'voxels/coords',
  'voxels/worldgenerator',
   -> supersecret.Game.loaded = true)


doAsync = (f, callback) ->
  w = new AsyncWorker(f, {
    ondone: callback
  })
  w.run()
  return w




WorldGeometry = null
lib.load('events', ->
  class WorldGeometry extends EventManagedObject
    constructor: (chunkSize, cubeSize, scene) ->
      super()
      @chunkSize = chunkSize
      @cubeSize = cubeSize
      @geometry = new Grid(3, [Infinity, Infinity, Infinity])
      @cache = new Grid(3, [Infinity, Infinity, Infinity])
      @neighborCache = new Grid(3, [Infinity, Infinity, Infinity])
      @dirty = new Map()
      @updating = false
      @dirtyChunks = new Set()
      @updater = new Updater(1000)

    hasDirty: ->
      return @dirty.size > 0

    setDirty: (worldX, worldY, worldZ) ->
      [cx, cy, cz] = getChunkCoords(@chunkSize, worldX, worldY, worldZ)
      [x, y, z] = getLocalCoords(@chunkSize, worldX, worldY, worldZ)
      #cacheChunk = @cache.get(cx, cy, cz)
      #return if not cacheChunk
      #cacheChunk.set(null, x, y, z)
      if not @dirty.contains([worldX, worldY, worldZ])
        @dirty.put([worldX, worldY, worldZ], now())

    setClean: (worldX, worldY, worldZ) ->
      cacheChunk = @cache.get(cx, cy, cz)
      return if not cacheChunk
      cacheChunk.set(now(), x, y, z)
      #@dirty.put([worldX, worldY, worldZ], now())
      @dirty.remove [worldX, worldY, worldZ]

    isDirty: (worldX, worldY, worldZ) ->
      [cx, cy, cz] = getChunkCoords(@chunkSize, worldX, worldY, worldZ)
      [x, y, z] = getLocalCoords(@chunkSize, worldX, worldY, worldZ)
      cacheChunk = @cache.get(cx, cy, cz)
      return false if not cacheChunk
      lastUpdated = cacheChunk.get(x, y, z)
      return true if not lastUpdated
      lastRequestedUpdate = @dirty.get([worldX, worldY, worldZ])
      return lastUpdated < lastRequestedUpdate

    getNeighbors: (getter, worldX, worldY, worldZ) ->
      if not @dfkjdskfj
        debugger
        @dfkjdskfj = true
      neighbors = []
      for dx in [0,1]
        for dy in [0,1]
          for dz in [0,1]
            p = [worldX - dx, worldY - dy, worldZ - dz]
            neighbors.push(getter(worldX, worldY, worldZ))
      return neighbors

    wasUpdatedAfter: (a, b) ->
      # Was 'a' updated after 'b'
      chunkCoordsA = getChunkCoords(@chunkSize, a...)
      chunkCoordsB = getChunkCoords(@chunkSize, b...)
      localCoordsA = getLocalCoords(@chunkSize, a...)
      localCoordsB = getLocalCoords(@chunkSize, b...)

      cacheChunkA = @cache.get(cacheChunkA...)
      cacheChunkB = @cache.get(cacheChunkB...)
      return false if not cacheChunkA and cacheChunkB
      return true if cacheChunkA and not cacheChunkB
      return false if not cacheChunkA and not cacheChunkB
      lastUpdatedA = cacheChunkA.get(localCoordsA...)
      lastUpdatedB = cacheChunkB.get(localCoordsB...)

      return lastUpdatedA > lastUpdatedB

    hasDifferentNeighbors: (getter, worldX, worldY, worldZ) ->
      [cx, cy, cz] = getChunkCoords(@chunkSize, worldX, worldY, worldZ)
      [x, y, z] = getLocalCoords(@chunkSize, worldX, worldY, worldZ)
      neighborChunk = @neighborCache.get(cx, cy, cz)
      neighbors = @getNeighbors(getter, worldX, worldY, worldZ)
      if not neighborChunk
        expected = neighbors[0]
        @updater.update('neighbors', neighbors)
        for n in neighbors
          if expected != n
            debugger
            return true
      else
        cachedNeighbors = neighborChunk.get(x, y, z)
        if not cachedNeighbors.length == neighbors.length
          return true
        for i in [0..neighbors.length-1]
          if cachedNeighbors[i] != neighbors[i]
            return true
      return false

    # Generates the chunk geometry for a given chunk at the given chunk coordinates.
    generateChunk: (getter, chunkX, chunkY, chunkZ) ->
      return if @geometry.exists(chunkX, chunkY, chunkZ)
      geometry =
        cubes: new MarchingCubes(@cubeSize)
      @geometry.set(geometry, chunkZ, chunkY, chunkZ)

      cacheChunk = new Grid(3, @chunkSize)
      @cache.set(cacheChunk, chunkX, chunkY, chunkZ)

      @forceGenerateChunk(getter, chunkX, chunkY, chunkZ)
      return true

    forceGenerateChunk: (getter, chunkX, chunkY, chunkZ) ->
      worker = new NestedForWorker([
        [0,@chunkSize[1]-1],
        [0,@chunkSize[0]-1],
        [0,@chunkSize[2]-1]], ((y, x, z) ->
          @updater.update('forceGenerateChunk', format('Generation of chunk %d, %d, %d is currently evaluating %d, %d, %d', chunkX, chunkY, chunkZ, x, y, z))
          [wx, wy, wz] = getWorldCoords(@chunkSize, x, y, z, chunkX, chunkY, chunkZ)
          if @hasDifferentNeighbors(getter, wx, wy, wz)
            console.log(wx, wy, wz)
            @setDirty(wx, wy, wz)
      ).bind(this), {
        ondone: (->
          console.log(format('Generation of chunk %d, %d, %d is complete with %d dirty blocks', chunkX, chunkY, chunkZ, @dirty.size))
        ).bind(this)
      })
      worker.synchronous = true
      worker.run()
      console.log(@dirty.size + ' dirty pieces')

    update: (getter) ->
      @updater.update('WorldGeometry.update', 'Method entered. There are ' + @dirty.size + ' dirty things')
      return if not @hasDirty() or @updating
      console.log('An update has begun')
      @updating = true
      @dirty.forEach(((worldCoords) ->
        dirty = @isDirty(worldCoords...)
        @setClean(worldCoords...)
        return if not dirty
        if hasDifferentNeighbors(getter, worldX, worldY, worldZ)
          @generateVoxelGeometry(getter, worldX, worldY, worldZ)
      ).bind(this))
      @dirtyChunks.forEach(((chunkCoords) ->
        @dirtyChunks.remove chunkCoords
        @refreshChunkGeometry(chunkCoords...)
      ).bind(this))

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



    generateVoxelGeometry: (getter, worldX, worldY, worldZ) ->
      [cx, cy, cz] = getChunkCoords(@chunkSize, worldX, worldY, worldZ)
      [x, y, z] = getLocalCoords(@chunkSize, worldX, worldY, worldZ)
      geometryChunk = @geometry.get(cx, cy, cz)
      if not geometryChunk
        throw format('No geometry chunk for %d, %d, %d', worldX, worldY, worldZ)
      geometry = geometryChunk.get(x, y, z)
      geometry.cubes.updateCube(((x, y, z) ->
        v = getter(getWorldCoords(@chunkSize, x, y, z, cx, cy, cz))
        return undefined if v == undefined
        return !!v
      ).bind(this), x, y, z)
      @dirtyChunks.add [cx, cy, cz]


    refreshChunkGeometry: (chunkX, chunkY, chunkZ) ->
      #geometry = geo.cubes.generateGeometry(, ([-1, size] for size in @chunkSize)...)
      @dirtyChunks.remove([chunkX, chunkY, chunkZ])
      geometry = @geometry.get(chunkX, chunkY, chunkZ)
      maybeNewGeometry = geometry.cubes.getGeometry()
      maybeNewGeometry.computeFaceNormals()
      if maybeNewGeometry != geometry.geometry
        geometry.geometry = maybeNewGeometry
        if not geometry.mesh
          geometry.mesh = @createMesh(geometry.geometry, chunkX, chunkY, chunkZ)
        else
          geometry.mesh.geometry = geometry.geometry
        @fireEvent('geometry-update',  maybeNewGeometry, chunkX, chunkY, chunkZ)
)




class World
  constructor: (chunkSize, cubeSize, scene) ->
    @chunkSize = chunkSize
    @cubeSize = cubeSize
    @scene = scene

    # @dirty = new Set()
    # @geometry = new Grid(3, [Infinity, Infinity, Infinity])

    @geometry = new WorldGeometry(@chunkSize, @cubeSize)
    @geometry.handleEvent('geometry-update', ((geometry, chunkX, chunkY, chunkSize) ->

    ).bind(this))

    @chunks = new Grid(3, [Infinity, Infinity, Infinity])
    @generator = new WorldGenerator(@chunkSize, scene)
    # @updatingGeometry = false
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

  generateChunkGeometry: (cx, cy, cz) ->
    r = @geometry.generateChunk(@get.bind(this), cx, cy, cz)
    if not r
      @geometry.forceGenerateChunk(@get.bind(this).cx, cy, cz)

    # chunk = @chunks.get(cx, cy, cz)
    # #cubes = null
    # geo = null
    # if not @geometry.exists(cx, cy, cz)
    #   cubes = new MarchingCubes(@cubeSize)
    #   geo =
    #     cubes: cubes
    #   @geometry.set(geo, cx, cy, cz)
    # else
    #   geo = @geometry.get(cx, cy, cz)
    # geometry = geo.cubes.generateGeometry(((x, y, z) ->
    #   return @get(
    #     x + cx * @chunkSize[0],
    #     y + cy * @chunkSize[1],
    #     z + cz * @chunkSize[2])
    # ).bind(this), ([-1, size] for size in @chunkSize)...)

    # geometry.computeFaceNormals()
    # console.log('finished adding mesh')
    # @lod.add geo.mesh = @createMesh(geometry, cx, cy, cz)
    # console.log(geo.mesh.position.x, geo.mesh.position.y, geo.mesh.position.z)

  # createMesh: (geometry, cx, cy, cz) ->
  #   mesh = new THREE.Mesh(
  #     geometry,
  #     #new THREE.MeshBasicMaterial({color: 0x00ff00, wireframe: true})
  #     new THREE.MeshPhongMaterial({ vertexColors: THREE.FaceColors}) # {color: 0x00ff00, ambient: 0x00ff00})
  #   )
  #   mesh.position.x = cx * @cubeSize * (@chunkSize[0])
  #   mesh.position.y = cy * @cubeSize * (@chunkSize[1])
  #   mesh.position.z = cz * @cubeSize * (@chunkSize[2])
  #   return mesh

  # getAbsolutePosition: (x, y, z, cx, cy, cz) ->
  #   return [
  #     cx * @chunkSize[0] + x
  #     cy * @chunkSize[1] + y
  #     cz * @chunkSize[2] + z
  #   ]


  # getRelativePosition: (x, y, z) ->
  #   cx = Math.floor(x / @chunkSize[0])
  #   cy = Math.floor(y / @chunkSize[1])
  #   cz = Math.floor(z / @chunkSize[2])
  #   chunk = @chunks.get(cx, cy, cz)
  #   return {
  #     chunk: chunk
  #     cx: cx
  #     cy: cy
  #     cz: cz
  #     x: x - cx * @chunkSize[0]
  #     y: y - cy * @chunkSize[1]
  #     z: z - cz * @chunkSize[2]
  #   }

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
        voxel = @generator.getVoxel(getWorldCoords(@chunkSize, x, y, z, cx, cy, cz)...)
        chunk.set(voxel, x, y, z)
      ).bind(this))

      @chunks.set(chunk, cx, cy, cz)
      @generateChunkGeometry(cx, cy, cz)
      #if false
        # cubes = new MarchingCubes(@chunkSize, @cubeSize)
        # geo = cubes: cubes
        # @geometry.set(geo, cx, cy, cz)

        # stats =
        #   added: 0
        #   skipped: 0
        # worker = new NestedForWorker([[-1,my+2], [-1,mx+2], [-1,mz+2]], ((y, x, z) ->
        #   @updater.update('generateChunk.worker', 'Position:' + [x, y, z] + '. Added: ' + stats.added + ', skipped: ' + stats.skipped)
        #   position = @getAbsolutePosition(x, y, z, cx, cy, cz)
        #   neighbors = @getNeighbors(position...)
        #   expected = neighbors[0]
        #   for n in neighbors
        #     if n != expected
        #       stats.added++
        #       @addDirty position
        #       return
        #       if x < 0 or y < 0 or z < 0 or x > mx or y > my or z > mz
        #         @addDirty position
        #       else
        #         geo.cubes.updateCube(((x, y, z) ->
        #           return @get(
        #             x + cx * @chunkSize[0],
        #             y + cy * @chunkSize[1],
        #             z + cz * @chunkSize[2]) != null
        #         ).bind(this), x, y, z)
        #         @dirtyChunks.add [cx, cy, cz]
        #         return
        #   stats.skipped++
        # ).bind(this), {
        #   ondone: (->
        #     console.log('Chunk generated in ' + (now() - generationStart))
        #     @generatingChunk = null
        #   ).bind(this)
        # })
        # worker.synchronous = @synchronous
        # worker.run()

    #@updater.update('update/dirtyReport', 'Currently there are ' + @dirty.length + ' dirty blocks')
    #@updateGeometry()
    @geometry.update(@get.bind(this))

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

  refreshChunkGeometry: (cx, cy, cz) ->
    #throw "don't call me"
    @geometry.refreshChunkGeometry(cx, cy, cz)
    return

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

    return
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
    # THIS WILL NOT WORK
    a = @getRelativePosition(x, y, z)
    return undefined if a.chunk is undefined
    r = a.chunk.set(data, a.x, a.y, a.z)
    #@dirty.add [x, y, z]
    return r

  get: (x, y, z) ->
    #a = @getRelativePosition(x, y, z)
    [cx, cy, cz] = getChunkCoords(@chunkSize, x, y, z)
    [lx, ly, lz] = getLocalCoords(@chunkSize, x, y, z)
    chunk = @chunks.get(cx, cy, cz)
    return undefined if not chunk
    return chunk.get(lx, ly, lz)


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
    @chunkSize = [16, 64, 16]
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

    @selectedMesh = new THREE.Line(geometry, new THREE.LineBasicMaterial({color:0xffff00}), THREE.LinePieces)
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
