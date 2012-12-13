lib.load(
  'firstperson'
  'grid'
  'voxel/voxel-renderer'
  'voxel/renderers/cube'
  'voxel/renderers/march'
  ->
    supersecret.Game.loaded = true
    mainRenderer = MarchingCubes
)


mainRenderer = null


supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)
    @grid = new Grid(3, [64, 64, 64])
    scale = 5
    @grid.handleEvent('missing', (x, y, z) =>
      @grid.set_(false, x, y, z)
    )

    @voxelRenderer = new VoxelRenderer(
      (x, y, z) =>
        if 0 <= x < @grid.size[0] and 0 <= y < @grid.size[1] and 0 <= z < @grid.size[2]
          return @grid.get(x, y, z)
        return undefined
      ,
      @grid.size,
      scale, [])

    @mesh = null
    updateMesh = =>
      geom = @voxelRenderer.geometry()
      geom.computeFaceNormals()
      geom.normalsNeedUpdate = true
      if not @mesh or @mesh.geometry != geom
        console.log('updating geometry')
        if @mesh
          @scene.remove @mesh
        @mesh = new THREE.Mesh(
          geom
          # new THREE.MeshNormalMaterial()
          # new THREE.MeshLambertMaterial({color: 0xff0000})
          )
        DEBUG.expose('mesh', @mesh)
        @scene.add @mesh

    @grid.handleEvent('set', (prev, data, x, y, z) =>
      for dx in [0..1]
        for dy in [0..1]
          for dz in [0..1]
            @voxelRenderer.updateVoxel(x-dx, y-dy, z-dz, mainRenderer)
      updateMesh()
    )

    @sphere =  new THREE.Mesh(
      new THREE.SphereGeometry(1, 16, 16),
      new THREE.LineBasicMaterial({color: 0xff0000, wireframe:true}))
    @scene.add @sphere
    @sel =
      x: 0
      y: 0
      z: 0
    DEBUG.expose('sphere', @sphere)
    $(document).keydown((e) =>
      switch e.keyCode
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
        when 13
          @grid.set(true, @sel.x, @sel.y, @sel.z)
      @sphere.position.x = @sel.x * scale
      @sphere.position.y = @sel.y * scale
      @sphere.position.z = @sel.z * scale
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
    @person.update(delta)
