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


booleanGetter = (getter) ->
  return (x, y, z) ->
    v = getter(x, y, z)
    return undefined if v is undefined
    return !!v


localGetter = (getter, chunkSize, chunkX, chunkY, chunkZ) ->
  return (x, y, z) ->
    return getter(
      chunkX * chunkSize[0] + x,
      chunkY * chunkSize[1] + y,
      chunkZ * chunkSize[2] + z)


WorldGeometry = null
lib.load('events', ->
  class WorldGeometry extends EventManagedObject
    constructor: (chunkSize, cubeSize, materials) ->
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
      [cx, cy, cz] = getChunkCoords(@chunkSize, worldX, worldY, worldZ)
      [x, y, z] = getLocalCoords(@chunkSize, worldX, worldY, worldZ)
      @dirty.remove [worldX, worldY, worldZ]
      cacheChunk = @cache.get(cx, cy, cz)
      return if not cacheChunk
      cacheChunk.set(now(), x, y, z)
      #@dirty.put([worldX, worldY, worldZ], now())

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
      neighbors = []
      for dx in [-1..1]
        for dy in [-1..1]
          for dz in [-1..1]
            p = [worldX - dx, worldY - dy, worldZ - dz]
            neighbors.push(getter(p...))
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
      #console.log('hasDifferentNeighbors', worldX, worldY, worldZ, JSON.stringify(neighbors))
      if not neighborChunk
        expected = neighbors[0]
        for n in neighbors
          if expected != n
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
    generateChunk: (getter, chunkX, chunkY, chunkZ, callback) ->
      if @geometry.exists(chunkX, chunkY, chunkZ)
        console.log format('Skipping generation for chunk %d, %d, %d because the geometry exists', chunkX, chunkY, chunkZ)
        return
      # debugger
      geometry =
        cubes: new MarchingCubes(@chunkSize, @cubeSize, @materials)
      console.log format('Setting geometry for chunk %d, %d, %d', chunkX, chunkY, chunkZ)
      @geometry.set(geometry, chunkX, chunkY, chunkZ)

      cacheChunk = new Grid(3, @chunkSize)
      @cache.set(cacheChunk, chunkX, chunkY, chunkZ)

      @forceGenerateChunk(getter, chunkX, chunkY, chunkZ, callback)
      return true

    forceGenerateChunk: (getter, chunkX, chunkY, chunkZ, callback) ->
      console.log('IN forceGenerateChunk')
      worker = new NestedForWorker([
        [-1,@chunkSize[1]],
        [-1,@chunkSize[0]],
        [-1,@chunkSize[2]]], ((y, x, z) ->
          #console.log(x, y, z)
          [wx, wy, wz] = getWorldCoords(@chunkSize, x, y, z, chunkX, chunkY, chunkZ)
          # @generateVoxelGeometry(getter, wx, wy, wz)
          if @hasDifferentNeighbors(getter, wx, wy, wz)
            @setDirty(wx, wy, wz)
      ).bind(this), {
        ondone: (->
          console.log(format('Generation of chunk %d, %d, %d is complete with %d dirty blocks', chunkX, chunkY, chunkZ, @dirty.size))
          callback and callback()
        ).bind(this)
      })
      #worker.synchronous = true
      worker.run()
      console.log(@dirty.size + ' dirty pieces')
      #@refreshChunkGeometry(chunkX, chunkY, chunkZ)

    update: (getter) ->
      #@updater.update('WorldGeometry.update', 'Method entered. There are ' + @dirty.size + ' dirty things')
      # return
      return if not @hasDirty() or @updating
      console.log('An update has begun')
      @updating = true
      @dirty.forEach(((worldCoords) ->
        dirty = @isDirty(worldCoords...)
        @setClean(worldCoords...)
        return if not dirty
        if @hasDifferentNeighbors(booleanGetter(getter), worldCoords...)
          @generateVoxelGeometry(getter, worldCoords...)
      ).bind(this))
      @dirtyChunks.forEach(((chunkCoords) ->
        @dirtyChunks.remove chunkCoords
        @refreshChunkGeometry(chunkCoords...)
      ).bind(this))
      @updating = false
      console.log('the update is complete. Dirty size: ' + @dirty.size + ' dirty chunk size: ' + @dirtyChunks.length)



    generateVoxelGeometry: (getter, worldX, worldY, worldZ) ->
      [cx, cy, cz] = getChunkCoords(@chunkSize, worldX, worldY, worldZ)
      [x, y, z] = getLocalCoords(@chunkSize, worldX, worldY, worldZ)
      geometryChunk = @geometry.get(cx, cy, cz)
      if not geometryChunk
        throw format('No geometry chunk for %d, %d, %d', worldX, worldY, worldZ)
      #geometry = geometryChunk.get(x, y, z)
      # geometryChunk.cubes.updateCube(((x, y, z) ->
      #   [wx, wy, wz] = getWorldCoords(@chunkSize, x, y, z, cx, cy, cz)
      #   getter(wx, wy, wz)
      # ).bind(this), x, y, z)
      ps = getter(worldX, worldY, worldZ)
      properties = undefined
        #color: if ps and ps.color then new THREE.Color(ps.color) else undefined
      geometryChunk.cubes.updateCube(
        localGetter(booleanGetter(getter), @chunkSize, cx, cy, cz),
        x, y, z, properties)
      @dirtyChunks.add [cx, cy, cz]


    refreshChunkGeometry: (chunkX, chunkY, chunkZ) ->
      #geometry = geo.cubes.generateGeometry(, ([-1, size] for size in @chunkSize)...)
      # debugger
      console.log format('refreshing geometry for %d, %d, %d', chunkX, chunkY, chunkZ)
      @dirtyChunks.remove([chunkX, chunkY, chunkZ])
      geometry = @geometry.get(chunkX, chunkY, chunkZ)
      maybeNewGeometry = geometry.cubes.getGeometry()
      maybeNewGeometry.computeCentroids()
      maybeNewGeometry.computeFaceNormals()
      maybeNewGeometry.normalsNeedUpdate = true
      if maybeNewGeometry != geometry.geometry
        console.log('New geometry!')
        geometry.geometry = maybeNewGeometry
        # oldMesh = geometry.mesh
        # geometry.mesh = @createMesh(geometry.geometry, chunkX, chunkY, chunkZ)
        @fireEvent('geometry-update', maybeNewGeometry, chunkX, chunkY, chunkZ)
)



####################################################################################################
#  #########  #####    #####      ###  #######      ################################################
#   #######   ###   ##   ###  ###  ##  #######  ###  ###############################################
##  ### ###  ###  ######  ##  ###  ##  #######  ####  ##############################################
##   #   #   ###  ######  ##      ###  #######  ####  ##############################################
###         ####  ######  ##  #  ####  #######  ####  ##############################################
###   ###   #####   ##   ###  ##  ###  #######  ###  ###############################################
#### ##### ########    #####  ###  ##       ##      ################################################
####################################################################################################



class World
  constructor: (chunkSize, cubeSize, scene) ->
    @chunkSize = chunkSize
    @cubeSize = cubeSize
    @scene = scene
    @meshes = new Grid(3, [Infinity, Infinity, Infinity])

    # @dirty = new Set()
    # @geometry = new Grid(3, [Infinity, Infinity, Infinity])

    @materials = [
      new THREE.MeshNormalMaterial( { shading: THREE.SmoothShading } ),
      new THREE.MeshDepthMaterial(),
      new THREE.MeshBasicMaterial( { color: 0x0066ff, blending: THREE.AdditiveBlending, transparent: true, depthWrite: false } ),
      #new THREE.MeshBasicMaterial( { color: 0xffaa00, wireframe: true } ),
      new THREE.MeshLambertMaterial( { color: 0xdddddd, shading: THREE.FlatShading } ),
      new THREE.MeshLambertMaterial( { color: 0xdddddd, shading: THREE.SmoothShading } ),
      new THREE.MeshPhongMaterial( { ambient: 0x030303, color: 0xdddddd, specular: 0x009900, shininess: 30, shading: THREE.FlatShading } ),
      new THREE.MeshPhongMaterial( { ambient: 0x030303, color: 0xdddddd, specular: 0x009900, shininess: 30, shading: THREE.SmoothShading } )
    ]

    @geometry = new WorldGeometry(@chunkSize, @cubeSize, @materials)
    @geometry.handleEvent('geometry-update', ((geometry, chunkX, chunkY, chunkZ) ->
      mesh = @meshes.get(chunkX, chunkY, chunkZ)
      @scene.remove mesh if mesh
      console.log('Got geometry update for ', chunkX, chunkY, chunkZ)
      mesh = @createMesh(geometry, chunkX, chunkY, chunkZ)
      @scene.add mesh
    ).bind(this))

    @chunks = new Grid(3, [Infinity, Infinity, Infinity])
    @generator = new WorldGenerator(@chunkSize, scene)
    # @updatingGeometry = false
    # @lod = new THREE.LOD()
    # @scene.add @lod
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

  getter: (wx, wy, wz) ->
    v = @get(wx, wy, wz)
    return undefined if v == undefined
    return v != null

  generateChunkGeometry: (cx, cy, cz, callback) ->
    r = @geometry.generateChunk(@getter.bind(this), cx, cy, cz, callback)
    if not r
      console.log("FORCING CHUNK GENERATION!")
      @geometry.forceGenerateChunk(@getter.bind(this), cx, cy, cz, callback)

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

      console.log(getWorldCoords(@chunkSize, 0,0,0, 0,0,0))
      console.log(getWorldCoords(@chunkSize, 0,0,0, 1,0,0))

      chunk.handleEvent('missing', ((x, y, z) ->
        worldCoords = getWorldCoords(@chunkSize, x, y, z, cx, cy, cz)
        voxel = @generator.getVoxel(worldCoords...)
        chunk.set(voxel, x, y, z)
      ).bind(this))

      @chunks.set(chunk, cx, cy, cz)
      @generateChunkGeometry(cx, cy, cz, (->
        @generatingChunk = null
      ).bind(this))

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
    @geometry.refreshChunkGeometry(cx, cy, cz)

  createMesh: (geometry, cx, cy, cz) ->
    mesh = new THREE.Mesh(
      geometry,
      #new THREE.MeshFaceMaterial()
      #new THREE.MeshBasicMaterial({vertexColors: THREE.FaceColors, wireframe: true})
      new THREE.MeshPhongMaterial({ vertexColors: THREE.FaceColors})
      #new THREE.MeshNormalMaterial({color: 0xff0000})
      #new THREE.MeshBasicMaterial({wireframe: true})
      #new THREE.MeshPhongMaterial({color: 0x00ff00, ambient: 0x0000ff}) # {color: 0x00ff00, ambient: 0x00ff00})
    )
    mesh.position.x = cx * @cubeSize * (@chunkSize[0])
    mesh.position.y = cy * @cubeSize * (@chunkSize[1])
    mesh.position.z = cz * @cubeSize * (@chunkSize[2])
    mesh.frustumCulled = false
    console.log('Mesh has ' + mesh.geometry.faces.length)
    # @scene.add mesh
    return mesh


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


####################################################################################################
#####    #######  ######## ##### #####        ######################################################
###   ##   ####    ######   ###   ####  ############################################################
##  ##########      #####    #    ####  ############################################################
##  ##########  ##  ####  ##   ##  ###      ########################################################
##  ###    ##        ###  ### ###  ###  ############################################################
###   ##   ##  ####  ##  #########  ##  ############################################################
#####      ##  ####  ##  #########  ##        ######################################################
####################################################################################################

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
    @person.updateCamera()

    chunks = []
    @world = new World(@chunkSize, @cubeSize, @scene)
    for x in [-32..32]
      for z in [-32..32]
        chunks.push [x, 0, z]
    #@world.generateChunkGeometry(0, 0, 0)
    #@world.generateChunk(1, 0, 0)
    #@world.generateChunkGeometry(1, 0, 0)

    distance3 = (x, y, z) ->
      return Math.sqrt(x*x + y*y + z*z)

    chunks.sort((a, b) ->
        return distance3(a...) - distance3(b...)
    )
    console.log(chunks)
    (@world.generateChunk(c...) for c in chunks)

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

    #@scene.add @selectionSphere
    @selectedCoord =
      x: 0
      y: 0
      z: 0

    copyPosition = (p) ->
      return {
        x: p.x
        y: p.y
        z: p.z
      }
    positionsEqual = (p1, p2) ->
      return p1.x == p2.x and p1.y == p2.y and p1.z == p2.z

    @selectedMesh = new THREE.Line(geometry, new THREE.LineBasicMaterial({color:0xffff00}), THREE.LinePieces)
    @scene.add @selectedMesh
    doDebug = false
    $(document).keydown(((e) ->
      lastChunk = copyPosition(@selectedChunk)
      lastCoord = copyPosition(@selectedCoord)
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
        when 104 # Num8
          @selectedCoord.z -= 1
        when 98  # Num2
          @selectedCoord.z += 1
        when 100 # Num4
          @selectedCoord.x -= 1
        when 102 # Num6
          @selectedCoord.x += 1
        when 187 # Num+
          @selectedCoord.y += 1
        when 189 # Num-
          @selectedCoord.y -= 1
        when 96  # Num0
          doDebug = not doDebug
          if doDebug
            console.log format('Debug mode %s', if doDebug then 'enabled' else 'disabled')
        when 101 # Num5
          debugger if doDebug
          @world.geometry.generateVoxelGeometry(@world.getter.bind(@world), @selectedCoord.x, @selectedCoord.y, @selectedCoord.z)
          [cx, cy, cz] = getChunkCoords(@chunkSize, @selectedCoord.x, @selectedCoord.y, @selectedCoord.z)
          @world.geometry.refreshChunkGeometry(cx, cy, cz)

      if not positionsEqual(lastChunk, @selectedChunk)
        @selectedMesh.position.x = @selectedChunk.x * @cubeSize * @chunkSize[0]
        @selectedMesh.position.y = @selectedChunk.y * @cubeSize * @chunkSize[1]
        @selectedMesh.position.z = @selectedChunk.z * @cubeSize * @chunkSize[2]
        console.log format('Selected chunk: %d, %d, %d: %s', @selectedChunk.x, @selectedChunk.y, @selectedChunk.z, @world.chunks.exists(@selectedChunk.x, @selectedChunk.y, @selectedChunk.z))

      if not positionsEqual(lastCoord, @selectedCoord)
        @selectionSphere.position.x = @selectedCoord.x * @cubeSize
        @selectionSphere.position.y = @selectedCoord.y * @cubeSize
        @selectionSphere.position.z = @selectedCoord.z * @cubeSize
        [cx, cy, cz] = getChunkCoords(@chunkSize, @selectedCoord.x, @selectedCoord.y, @selectedCoord.z)
        [lx, ly, lz] = getLocalCoords(@chunkSize, @selectedCoord.x, @selectedCoord.y, @selectedCoord.z)
        chunk = @world.chunks.get(cx, cy, cz)
        str = 'N/A'
        if not chunk
          str = 'Chunk does not exist'
        else
          str = JSON.stringify(chunk.get(lx, ly, lz))
        console.log format('Selected position: %d, %d, %d (chunk: %d, %d, %d; local: %d, %d, %d): %s',
          @selectedCoord.x, @selectedCoord.y, @selectedCoord.z, cx, cy, cz, lx, ly, lz, str)
    ).bind(this))


  initGeometry: ->
    @scene.add m = new THREE.Mesh(
      new THREE.SphereGeometry(1, 16, 16),
      #new THREE.LineBasicMaterial({color: 0xff0000})
      new THREE.MeshPhongMaterial({color: 0xff0000})
      )
    m.position.x = 5
    m.position.y = 5
    m.position.z = 5
    @selectionSphere = m

  initLights: ->
    @scene.add new THREE.AmbientLight(0x505050)
    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.x = 0
    light.position.y = 50
    light.position.z = 0
    @scene.add light
    @scene.add new THREE.DirectionalLightHelper(light, 1, 5)
    DEBUG.expose('dlight1', light)
    # @scene.add light
    # light = new THREE.DirectionalLight(0xffffff, .6)
    # light.position.x = -1
    # light.position.y = 1
    # light.position.z = -1
    # @scene.add light
    # light = new THREE.DirectionalLight(0xffffff, .6)
    # light.position.x = -1
    # light.position.y = -1
    # light.position.z = -1
    # @scene.add light
    # light = new THREE.DirectionalLight(0xffffff, .6)
    # light.position.x = 1
    # light.position.y = -1
    # light.position.z = 1
    # @scene.add light

  render: (delta) ->
    @world.update(delta)
    #@world.lod.update(@camera)
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)
