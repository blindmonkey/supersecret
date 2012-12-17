lib.load(
  'events'
  'firstperson'
  'grid'
  'set'
  'worker'
  'voxel/coords'
  'voxel/voxel-renderer'
  'voxel/renderers/cube'
  'voxel/renderers/march'
  'voxel/worldgenerator'
  ->
    supersecret.Game.loaded = true
    mainRenderer = MarchingCubes
    createChunkGeometryClass()
    createVoxelUI()
)

ChunkGeometry = null
createChunkGeometryClass = ->
  ChunkGeometry = class ChunkGeometry extends EventManagedObject
    constructor: (getter, chunkSize, cubeSize) ->
      super()
      @chunkSize = chunkSize
      @cubeSize = cubeSize
      @getter = getter
      @geometry = null
      @voxelRenderer = new VoxelRenderer(
        (x, y, z) =>
          return getter(x, y, z)?
        ,
        chunkSize,
        cubeSize, undefined)
      @dirty = new Set()

    update: (delta) ->
      return if @dirty.length == 0
      console.log('UPDATE')
      @dirty.forEachPop(([x, y, z, properties]) =>
        voxel = @getter(x, y, z)
        if not voxel?
          voxel = undefined
        else
          console.log(voxel)
        @voxelRenderer.updateVoxel(x, y, z, MarchingCubes, properties)
      )
      newGeometry = @voxelRenderer.geometry()
      newGeometry.computeFaceNormals()
      newGeometry.computeBoundingBox()
      newGeometry.computeBoundingSphere()
      newGeometry.verticesNeedUpdate = true
      newGeometry.normalsNeedUpdate = true
      newGeometry.facesNeedUpdate = true
      newGeometry.colorsNeedUpdate = true
      if @geometry != newGeometry
        @fireEvent('geometry-update', @geometry = newGeometry)

    updateVoxel: (x, y, z, properties) ->
      @dirty.add([x, y, z, properties])

class World
  constructor: (chunkSize, cubeSize, scene) ->
    @chunkSize = chunkSize
    @cubeSize = cubeSize
    @meshes = new Grid(3, [Infinity, Infinity, Infinity])
    @chunks = new Grid(3, [Infinity, Infinity, Infinity])
    @generator = new WorldGenerator(chunkSize)
    @geometry = new Grid(3, [Infinity, Infinity, Infinity])
    @scene = scene
    @geometries = []

  createMesh: (geometry, chunkX, chunkY, chunkZ) ->
    mesh = new THREE.Mesh(
          geometry
          # new THREE.MeshFaceMaterial()
          # new THREE.MeshNormalMaterial()
          # new THREE.MeshLambertMaterial({color: 0xff0000})
          new THREE.MeshLambertMaterial({vertexColors: THREE.FaceColors})
          # new THREE.LineBasicMaterial({vertexColors: THREE.FaceColors})
          )
    mesh.position.x = chunkX * @chunkSize[0] * @cubeSize
    mesh.position.y = chunkY * @chunkSize[1] * @cubeSize
    mesh.position.z = chunkZ * @chunkSize[2] * @cubeSize
    return mesh

  initChunk: (chunkX, chunkY, chunkZ) ->
    console.log('maybe initializing #{ chunkX }, #{ chunkY }, #{ chunkZ }')
    return if @chunks.exists(chunkX, chunkY, chunkZ)
    chunk = new Grid(3, @chunkSize)
    @chunks.set(chunk, chunkX, chunkY, chunkZ)
    geometry = new ChunkGeometry((x, y, z) =>
        worldCoords = getWorldCoords(@chunkSize, x, y, z, chunkX, chunkY, chunkZ)
        return @get(worldCoords...)
      , @chunkSize, @cubeSize)
    @geometries.push geometry
    geometry.handleEvent('geometry-update', (geometry) =>
      mesh = @meshes.get(chunkX, chunkY, chunkZ)
      if not mesh or mesh.geometry != geometry
        console.log('updating geometry')
        if mesh
          @scene.remove mesh
        mesh = @createMesh(geometry, chunkX, chunkY, chunkZ)
        @meshes.set(mesh, chunkX, chunkY, chunkZ)
        @scene.add mesh
      )
    @geometry.set(geometry, chunkX, chunkY, chunkZ)
    return chunk


  generateVoxel: (x, y, z) ->
    @set(@generator.getVoxel(x, y, z), x, y, z)

  updateVoxel: (x, y, z, properties) ->
    console.log('Update requested for ' + x + ', ' + y + ', ' + z)
    [cx, cy, cz, lx, ly, lz] = getAllCoords(@chunkSize, x, y, z)
    console.log('Update for ' + x + ', ' + y + ', ' + z + '; in chunk ' + cx + ', ' + cy + ', ' + cz + ' with local coords ' + lx + ', ' + ly + ', ' + lz)
    geometry = @geometry.get(cx, cy, cz)
    geometry.updateVoxel(lx, ly, lz, properties) if geometry

  exists: (x, y, z) ->
    [cx, cy, cz, lx, ly, lz] = getAllCoords(@chunkSize, x, y, z)
    chunk = @chunks.get(cx, cy, cz)
    return undefined if not chunk
    return chunk.exists(lx, ly, lz)

  get: (x, y, z) ->
    [cx, cy, cz, lx, ly, lz] = getAllCoords(@chunkSize, x, y, z)
    chunk = @chunks.get(cx, cy, cz)
    return undefined if not chunk
    return chunk.get(lx, ly, lz)

  set_: (obj, x, y, z) ->
    [cx, cy, cz, lx, ly, lz] = getAllCoords(@chunkSize, x, y, z)
    chunk = @chunks.get(cx, cy, cz)
    chunk = @initChunk(cx, cy, cz) if not chunk
    v = chunk.set(obj, lx, ly, lz)
    return v

  set: (obj, x, y, z) ->
    #console.log('set')
    [cx, cy, cz, lx, ly, lz] = getAllCoords(@chunkSize, x, y, z)
    v = @set_(obj, x, y, z)
    for dx in [0..1]
      for dy in [0..1]
        for dz in [0..1]
          nx = x-dx
          ny = y-dy
          nz = z-dz
          if not @exists(nx, ny, nz)
            @set_(null, nx, ny, nz)
    # geometry = @geometry.get(cx, cy, cz)
    # geometry.updateVoxel(lx, ly, lz, obj)
    for dx in [0..1]
      for dy in [0..1]
        for dz in [0..1]
          @updateVoxel(x-dx, y-dy, z-dz, obj)
    return v

  update: (delta) ->
    for geometry in @geometries
      geometry.update(delta)



mainRenderer = null

VoxelUI = null
createVoxelUI = ->
  VoxelUI = class VoxelUI extends EventManagedObject
    constructor: (game) ->
      super()
      @game = game
      @keymap =
        SELECTION_LEFT: 74 # J
        SELECTION_RIGHT: 76 # L
        SELECTION_UP: 79 # O
        SELECTION_DOWN: 85 # U
        SELECTION_FORWARD: 73 # I
        SELECTION_BACK: 75 # K
        SET_SELECTION: 186 # ;
        DELETE_SELECTION: 80 # P
        REFRESH_SELECTION: 82 # R
        GENERATE_SELECTION: 71 # G
        COLOR1: 49 # 1
        COLOR2: 50 # 2
        COLOR3: 51 # 3
        COLOR4: 52 # 4
        COLOR5: 53 # 5
        COLOR6: 54 # 6
        COLOR7: 55 # 7
        COLOR8: 56 # 8
        COLOR9: 57 # 9

      @selStart =
        x: 0
        y: 0
        z: 0
      @selEnd = null

      getSelectionObject = =>
        return @selEnd if @selEnd?
        return @selStart

      @backreference = {}
      for id of @keymap
        @backreference[@keymap[id]] = id

      @down = new Set()
      $(document).keydown((e) =>
        if e.keyCode of @backreference
          @fireEvent(@backreference[e.keyCode])
      )

      currentColor = 0xffffff
      @handleEvent('COLOR1', =>
        currentColor = 0xffffff
      )
      @handleEvent('COLOR2', =>
        currentColor = 0xffff00
      )
      @handleEvent('GENERATE_SELECTION', =>
        # pass
      )


      @sphere =  new THREE.Mesh(
        new THREE.SphereGeometry(1, 16, 16),
        new THREE.LineBasicMaterial({color: 0xff0000, wireframe:true}))
      @selectionMesh = null
      @game.scene.add @sphere

      createSelectionMesh = ->
        @game.scene.remove @selectionMesh if @selectionMesh?
        return if not @selEnd?
        geometry = new THREE.Geometry()


      refreshUI = =>
        console.log('refresh')
        @sphere.position.x = getSelectionObject().x * @game.cubeSize
        @sphere.position.y = getSelectionObject().y * @game.cubeSize
        @sphere.position.z = getSelectionObject().z * @game.cubeSize
        createSelectionMesh()


      doDirection = (direction) =>
        modifiedDirection = direction - @game.person.rotation - Math.PI / 2
        console.log(Math.cos(modifiedDirection), Math.sin(modifiedDirection))
        getSelectionObject().x -= Math.round(Math.cos(modifiedDirection))
        getSelectionObject().z += Math.round(Math.sin(modifiedDirection))

      @handleEvent 'SELECTION_LEFT', =>
        doDirection(0)
        refreshUI()
      @handleEvent 'SELECTION_RIGHT', =>
        doDirection(Math.PI)
        refreshUI()
      @handleEvent 'SELECTION_FORWARD', =>
        doDirection(Math.PI / 2 * 3)
        refreshUI()
      @handleEvent 'SELECTION_BACK', =>
        doDirection(Math.PI / 2)
        refreshUI()
      @handleEvent 'SELECTION_UP', =>
        getSelectionObject().y++
        refreshUI()
      @handleEvent 'SELECTION_DOWN', =>
        getSelectionObject().y--
        refreshUI()
      @handleEvent 'REFRESH_SELECTION', =>
        for dx in [0..1]
          for dy in [0..1]
            for dz in [0..1]
              @world.updateVoxel(@selStart.x - dx, @selStart.y - dy, @selStart.z - dz)
      @handleEvent 'SET_SELECTION', =>
        @game.world.set({color: currentColor}, @selStart.x, @selStart.y, @selStart.z)
      @handleEvent 'DELETE_SELECTION', =>
        @game.world.set(null, @selStart.x, @selStart.y, @selStart.z)


supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    console.log('near plane: ' + @camera.near)
    mainRenderer = MarchingCubes
    @person = new FirstPerson(container, @camera)

    @chunkSize = [16, 64, 16]
    @cubeSize = 5
    @world = new World(@chunkSize, @cubeSize, @scene)

    DEBUG.expose('game', this)

    @ui = new VoxelUI(this)

    generated = false
    doGenerate = =>
      return if generated
      noise = new SimplexNoise()
      worker = new NestedForWorker([[1, @chunkSize[1]-2], [1, @chunkSize[0]-2], [1, @chunkSize[2]-2]], (y, x, z) =>
        # console.log(x,y,z)
        @world.generateVoxel(x, y, z)
      )
      worker.cycle = 50
      worker.run()

    # @sphere =  new THREE.Mesh(
    #   new THREE.SphereGeometry(1, 16, 16),
    #   new THREE.LineBasicMaterial({color: 0xff0000, wireframe:true}))
    # @scene.add @sphere
    # @sel =
    #   x: 0
    #   y: 0
    #   z: 0
    @updater = new Updater(1000)
    currentColor = 0xff0000
    DEBUG.expose('sphere', @sphere)


    # $(document).keydown((e) =>
    #   switch e.keyCode
    #     when 49 # 1
    #       currentColor = 0xff0000
    #     when 50 # 2
    #       currentColor = 0x00ff00
    #     when 51 # 3
    #       currentColor = 0xffff00
    #     when 52 # 4
    #       currentColor = 0x0000ff
    #     when 53 # 5
    #       currentColor = 0xff00ff
    #     when 54 # 6
    #       currentColor = 0x00ffff
    #     when 55 # 7
    #       currentColor = 0xffffff
    #     when 71 # G
    #       doGenerate()
    #     when 74 # J
    #       # @sel.x++
    #       doDirection(0)
    #     when 76 # L
    #       # @sel.x--
    #       doDirection(Math.PI)
    #     when 75 # K
    #       # @sel.z--
    #       doDirection(Math.PI / 2)
    #     when 73 # I
    #       # @sel.z++
    #       doDirection(Math.PI / 2 * 3)
    #     when 85 # U
    #       @sel.y--
    #     when 79 # O
    #       @sel.y++
    #     when 82 # R
    #       for dx in [0..1]
    #         for dy in [0..1]
    #           for dz in [0..1]
    #             @world.updateVoxel(@sel.x - dx, @sel.y - dy, @sel.z - dz)
    #     when 84 # T
    #       #@voxelRenderer.updateVoxel(@sel.x, @sel.y, @sel.z, CubeRenderer)
    #       mainRenderer = CubeRenderer
    #     when 89 # Y
    #       mainRenderer = MarchingCubes
    #     when 186 # ;
    #       @world.set({color: currentColor}, @sel.x, @sel.y, @sel.z)
    #       # @grid.set(true, @sel.x, @sel.y, @sel.z)
    #     when 80 # P
    #       @world.set(null, @sel.x, @sel.y, @sel.z)
    #   console.log('Current color: ' + currentColor.toString(16))
    #   @sphere.position.x = @sel.x * @cubeSize
    #   @sphere.position.y = @sel.y * @cubeSize
    #   @sphere.position.z = @sel.z * @cubeSize
    #   console.log(@sel.x, @sel.y, @sel.z)
    #   # if 0 <= @sel.x < @grid.size[0] and 0 <= @sel.y < @grid.size[1] and 0 <= @sel.z < @grid.size[2]
    #   voxel = @world.get(@sel.x, @sel.y, @sel.z)
    #   if voxel is undefined
    #     @sphere.material.color = new THREE.Color(0xffffff)
    #   else if voxel
    #     @sphere.material.color = new THREE.Color(0x00ff00)
    #   else
    #     @sphere.material.color = new THREE.Color(0xff0000)
    # )

  initLights: ->
    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.y = Math.random()
    light.position.x = Math.random()
    light.position.z = Math.random()
    @scene.add light

    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.y = Math.random()
    light.position.x = -Math.random()
    light.position.z = -Math.random()
    @scene.add light
    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.y = -Math.random()
    light.position.x = Math.random()
    light.position.z = Math.random()
    @scene.add light

  update: (delta) ->
    @updater.update('Camera',
      ((@camera.rotation.x + 2*Math.PI) % (Math.PI * 2)) / Math.PI * 180,
      ((@camera.rotation.y + 2*Math.PI) % (Math.PI * 2)) / Math.PI * 180,
      ((@camera.rotation.z + 2*Math.PI) % (Math.PI * 2)) / Math.PI * 180)
    @world.update(delta)
    @person.update(delta)
