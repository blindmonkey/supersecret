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
  ->
    supersecret.Game.loaded = true
    mainRenderer = MarchingCubes
    createWorldGeometryClass()
)

WorldGeometry = null
createWorldGeometryClass = ->
  WorldGeometry = class WorldGeometry extends EventManagedObject
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
      newGeometry.normalsNeedUpdate = true
      newGeometry.facesNeedUpdate = true
      newGeometry.colorsNeedUpdate = true
      if @geometry != newGeometry
        @fireEvent('geometry-update', @geometry = newGeometry)

    updateVoxel: (x, y, z, properties) ->
      @dirty.add([x, y, z, properties])


mainRenderer = null


supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    console.log('near plane: ' + @camera.near)
    mainRenderer = MarchingCubes
    @person = new FirstPerson(container, @camera)

    @chunkSize = [16, 64, 16]
    @cubeSize = 5
    @grid = new Grid(3, @chunkSize)
    @grid.handleEvent('missing', (x, y, z) =>
      @grid.set_(null, x, y, z)
    )

    DEBUG.expose('game', this)

    getter = (x, y, z) =>
      if 0 <= x < @grid.size[0] and 0 <= y < @grid.size[1] and 0 <= z < @grid.size[2]
        return @grid.get(x, y, z)
      return undefined


    @geometry = new WorldGeometry(getter, @chunkSize, @cubeSize)

    @grid.handleEvent('set', (prev, data, x, y, z) =>
      v = @grid.get(x, y, z)
      for dx in [0..1]
        for dy in [0..1]
          for dz in [0..1]
            @geometry.updateVoxel(x-dx, y-dy, z-dz, v)
    )

    @mesh = null
    @geometry.handleEvent('geometry-update', (newGeometry) =>
      geom = newGeometry
      if not @mesh or @mesh.geometry != geom
        console.log('updating geometry')
        if @mesh
          @scene.remove @mesh
        @mesh = new THREE.Mesh(
          geom
          # new THREE.MeshFaceMaterial()
          # new THREE.MeshNormalMaterial()
          # new THREE.MeshLambertMaterial({color: 0xff0000})
          new THREE.MeshLambertMaterial({vertexColors: THREE.FaceColors})
          # new THREE.LineBasicMaterial({vertexColors: THREE.FaceColors})
          )
        DEBUG.expose('mesh', @mesh)
        @scene.add @mesh
    )

    generated = false
    doGenerate = =>
      return if generated
      noise = new SimplexNoise()
      worker = new NestedForWorker([[1, @chunkSize[1]-2], [1, @chunkSize[0]-2], [1, @chunkSize[2]-2]], (y, x, z) =>
        n = noise.noise3D(x / 32, y / 32, z / 32)
        v = null
        if n > .8
          v = {color: 0xff0000}
        else if n > .6
          v = {color: 0x00ff00}
        else if n > .4
          v = {color: 0x0000ff}
        else if n > .2
          v = {color: 0xff00ff}
        else if n > 0
          v = {color: 0xffff00}
        @grid.set(v, x, y, z)
      )
      worker.cycle = 50
      worker.run()

    @sphere =  new THREE.Mesh(
      new THREE.SphereGeometry(1, 16, 16),
      new THREE.LineBasicMaterial({color: 0xff0000, wireframe:true}))
    @scene.add @sphere
    @sel =
      x: 0
      y: 0
      z: 0
    currentColor = 0xff0000
    DEBUG.expose('sphere', @sphere)
    $(document).keydown((e) =>
      switch e.keyCode
        when 49 # 1
          currentColor = 0xff0000
        when 50 # 2
          currentColor = 0x00ff00
        when 51 # 3
          currentColor = 0xffff00
        when 52 # 4
          currentColor = 0x0000ff
        when 53 # 5
          currentColor = 0xff00ff
        when 54 # 6
          currentColor = 0x00ffff
        when 55 # 7
          currentColor = 0xffffff
        when 71 # G
          doGenerate()
        when 74 # J
          @sel.x--
        when 76 # L
          @sel.x++
        when 75 # K
          @sel.z++
        when 73 # I
          @sel.z--
        when 85 # U
          @sel.y--
        when 79 # O
          @sel.y++
        when 82 # R
          @voxelRenderer.updateVoxel(@sel.x, @sel.y, @sel.z, mainRenderer)
        when 84 # T
          #@voxelRenderer.updateVoxel(@sel.x, @sel.y, @sel.z, CubeRenderer)
          mainRenderer = CubeRenderer
        when 89 # Y
          mainRenderer = MarchingCubes
        when 186 # ;
          @grid.set({color: currentColor}, @sel.x, @sel.y, @sel.z)
          # @grid.set(true, @sel.x, @sel.y, @sel.z)
        when 80 # P
          @grid.set(null, @sel.x, @sel.y, @sel.z)
      console.log('Current color: ' + currentColor.toString(16))
      @sphere.position.x = @sel.x * @cubeSize
      @sphere.position.y = @sel.y * @cubeSize
      @sphere.position.z = @sel.z * @cubeSize
      console.log(@sel.x, @sel.y, @sel.z)
      if 0 <= @sel.x < @grid.size[0] and 0 <= @sel.y < @grid.size[1] and 0 <= @sel.z < @grid.size[2]
        voxel = @grid.get(@sel.x, @sel.y, @sel.z)
      if voxel is undefined
        @sphere.material.color = new THREE.Color(0xffffff)
      else if voxel
        @sphere.material.color = new THREE.Color(0x00ff00)
      else
        @sphere.material.color = new THREE.Color(0xff0000)
    )

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
    @geometry.update(delta)
    @person.update(delta)
