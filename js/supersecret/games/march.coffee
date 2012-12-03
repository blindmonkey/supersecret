lib.load('firstperson', 'grid', 'facemanager', ->
  supersecret.Game.loaded = true)

generateMarchingCubesGeometry = (grid, scale) ->
  scale = scale or 5
  getCoordFromIndex = (index) ->
    z = index % 2
    y = (index - z) / 2 % 2
    x = ((index - z) / 2 - y) / 2 % 2
    return [x, y, z]

  getIndexFromCoord = (x, y, z) ->
    return x * 4 + y * 2 + z

  flipX = ((x, y, z) ->
    return [1 - x, y, z]
  ).bind(this)

  flipY = ((x, y, z) ->
    return [x, 1 - y, z]
  ).bind(this)

  flipZ = ((x, y, z) ->
    return [x, y, 1 - z]
  ).bind(this)

  rotateRightX = ((x, y, z) ->
    return [x, 1-z, y]
  ).bind(this)

  rotateLeftX = ((x, y, z) ->
    return [x, z, 1-y]
  ).bind(this)

  rotateRightY = ((x, y, z) ->
    return [1-z, y, x]
  ).bind(this)

  rotateLeftY = ((x, y, z) ->
    return [z, y, 1-x]
  ).bind(this)

  rotateRightZ = ((x, y, z) ->
    return [1-y, x, z]
  ).bind(this)

  rotateLeftZ = ((x, y, z) ->
    return [y, 1-x, z]
  ).bind(this)


  arraysEq = (a1, a2) ->
    return JSON.stringify(a1) == JSON.stringify(a2)

  getCornerArray = (coords...) ->
    [x, y, z] = coords
    return [
      grid.get(x, y, z)
      grid.get(x, y, z + 1)
      grid.get(x, y + 1, z)
      grid.get(x, y + 1, z + 1)
      grid.get(x + 1, y, z)
      grid.get(x + 1, y, z + 1)
      grid.get(x + 1, y + 1, z)
      grid.get(x + 1, y + 1, z + 1)
    ]

  # Array index help
  # 0: 0, 0, 0
  # 1: 0, 0, 1
  # 2: 0, 1, 0
  # 3: 0, 1, 1
  # 4: 1, 0, 0
  # 5: 1, 0, 1
  # 6: 1, 1, 0
  # 7: 1, 1, 1

  # 0.5, 1, 0
  # 1, 0.5, 0
  # 1, 0, 0.5
  # 0.5, 0, 1
  # 0, 0.5, 1
  # 0, 1, 0.5

  definitions = [
    [[true, false, false, false, false, false, false, false], [
      [[[0.5, 0, 0], [0, 0.5, 0], [0, 0, 0.5]]]
    ]]
    [[true, true, true, true, false, false, false, false], [
      [[[0.5, 0, 0], [0.5, 1, 0], [0.5, 1, 1]],
       [[0.5, 0, 0], [0.5, 1, 1], [0.5, 0, 1]]]
    ]]
    [[true, true, false, false, false, false, false, false], [
      [[[0.5, 0, 0], [0, 0.5, 1], [0.5, 0, 1]],
       [[0.5, 0, 0], [0, 0.5, 0], [0, 0.5, 1]]]
    ]]
    [[false, false, true, true, true, true, true, true], [
      [[[0.5, 0, 0], [0.5, 0, 1], [0, 0.5, 1]],
       [[0.5, 0, 0], [0, 0.5, 1], [0, 0.5, 0]]]
    ]]
    [[true, true, true, false, true, false, false, false], [
      [[[0.5, 1, 0], [1, 0, 0.5], [1, 0.5, 0]]
       [[0.5, 1, 0], [0.5, 0, 1], [1, 0, 0.5]]
       [[0.5, 1, 0], [0, 0.5, 1], [0.5, 0, 1]]
       [[0.5, 1, 0], [0, 1, 0.5], [0, 0.5, 1]]
      ]
    ]]
  ]

  getTransformedFace = (transform, face, offset) ->
    [ox, oy, oz] = offset
    newFace = []
    for [x, y, z] in face
      [nx, ny, nz] = transform(x, y, z)
      newFace.push [nx * scale + ox, ny * scale + oy, nz * scale + oz]
    return newFace

  transformCorners = (transform, corners) ->
    newCorners = []
    for i in [0..corners.length - 1]
      coord = getCoordFromIndex(i)
      coord = transform(coord...)
      index = getIndexFromCoord(coord...)
      newCorners[index] = corners[i]
    return newCorners

  combineTransforms = (transforms...) ->
    return (x, y, z) ->
      for transform in transforms
        [x, y, z] = transform(x, y, z)
      return [x, y, z]

  transforms = [
    [rotateLeftX, rotateRightX]
    [rotateRightX, rotateLeftX]
    [rotateLeftY, rotateRightY]
    [rotateRightY, rotateLeftY]
    [rotateLeftZ, rotateRightZ]
    [rotateRightZ, rotateLeftZ]
  ]
  newTransforms = (t for t in transforms)
  for i in [0..transforms.length - 1]
    [it, iu] = transforms[i]
    newTransforms.push([it, iu])
    for j in [0..transforms.length - 1]
      [jt, ju] = transforms[j]
      newTransforms.push [combineTransforms(it, jt), combineTransforms(ju, iu)]
      # for k in [0..transforms.length - 1]
      #   [kt, ku] = transforms[k]
      #   newTransforms.push [combineTransforms(it, jt, kt), combineTransforms(ju, iu, ku)]
  transforms = newTransforms
  # transforms = []
  #transforms.push [combineTransforms(rotateRightX, rotateRightY, rotateRightY, rotateRightZ), combineTransforms(rotateLeftZ, rotateLeftY, rotateLeftY, rotateLeftX)]
  #transforms.push [combineTransforms(rotateRightX, rotateRightY, rotateRightZ), combineTransforms(rotateLeftZ, rotateLeftY, rotateLeftX)]
  # transforms.push [combineTransforms(rotateLeftX), combineTransforms(rotateRightX)]
  #transforms.push [combineTransforms(rotateRightX, rotateRightX, rotateRightY), combineTransforms(rotateLeftX, rotateLeftX, rotateLeftY, rotateLeftY)]
  # transforms.push [((x, y, z) -> [x, y, z]), ((x, y, z) -> [x, y, z])]
  transforms.push [combineTransforms(rotateRightX, rotateRightY, rotateRightY)]
  #transforms.push [((x, y, z) -> [1 - x, 1 - y, 1 - z]), ((x, y, z) -> [1 - x, 1 - y, 1 - z])]

  arrayToNumber = (a) ->
    # [true, false, true] -> 5
    n = 0
    for i in [0..a.length - 1]
      if a[i]
        e = a.length - i - 1
        n += Math.pow(2, e)
    return n
  numberToArray = (n) ->
    a = []
    while n > 0
      r = n % 2
      v = false
      if r > 0
        n -= r
        v = true
      a.splice(0, 0, v)
      n /= 2
    return a
  console.log(arrayToNumber(numberToArray(5)))

  # Precompute the transforms
  table = {}
  # for i in [0..255]
  #   a = numberToArray(i)
  c = 0
  for [definition, polygons] in definitions
    #n = arrayToNumber(definition)
    for transform in transforms
      corners = transformCorners(transform[0], definition)
      n = arrayToNumber(corners)
      table[n] = [polygons, transform[0]]
      c++
  console.log(c + 'definitions')







  #geometry = new THREE.Geometry()
  faceManager = new FaceManager()
  console.log('generating geometry')
  for x in [0..grid.size[0]-2]
    console.log(x / grid.size[0] * 100)
    for y in [0..grid.size[1]-2]
      for z in [0..grid.size[2]-2]
        originalCorners = getCornerArray(x, y, z)
        polygons = null
        transform = null
        n = arrayToNumber(originalCorners)
        if n of table
          [polygons, transform] = table[n]
        # for [definition, polys] in definitions
        #   for [t, u] in transforms
        #     corners = transformCorners(t, originalCorners)
        #     if arraysEq(definition, corners)
        #       polygons = polys
        #       transform = u
        #       break
        #   if polygons?
        #     break
        if polygons?
          #console.log('yeah')
          for polygon in polygons
            #console.log(polygon)
            for face in polygon
              transformedFace = getTransformedFace(transform, face, [x * scale, y * scale, z * scale])
              #console.log(transformedFace)
              faceManager.addFace(transformedFace...)
  console.log 'faces computed'
  g = faceManager.generateGeometry()
  console.log 'geometry generated'
  return g





supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false
  constructor: (container, width, height, opt_scene, opt_camera) ->
    params = getQueryParams()
    @viewAngle = parseFloat(params.viewAngle) or 90

    @noise = new SimplexNoise()
    if true
      @grid = new Grid(3, [6, 6, 6])
      for x in [0..@grid.size[0] - 1]
        for y in [0..@grid.size[1] - 1]
          for z in [0..@grid.size[1] - 1]
            @grid.set(false, x, y, z)
      @grid.set(true, 1, 1, 1)
      @grid.set(true, 2, 1, 1)
      @grid.set(true, 1, 2, 1)
      @grid.set(true, 1, 1, 2)
      @grid.set(true, 3, 3, 3)
      @grid.set(true, 4, 3, 3)
      @grid.set(true, 3, 4, 3)
      @grid.set(true, 3, 3, 4)
    else if false
      @grid = new Grid(3, [32, 32, 32])
      for x in [0..@grid.size[0] - 1]
        for y in [0..@grid.size[1] - 1]
          for z in [0..@grid.size[2] - 1]
            n = @noise.noise3D(x / 64, y / 64, z / 64) + @noise.noise3D(x / 32, y / 32, z / 32) / 2 + @noise.noise3D(x / 16, y / 16, z / 16) / 4
            @grid.set(n > 0, x, y, z)
      console.log('generation complete')
    else if true
      @grid = new Grid(3, [5, 5, 5])
      for x in [0..@grid.size[0] - 1]
        for y in [0..@grid.size[1] - 1]
          for z in [0..@grid.size[1] - 1]
            @grid.set(false, x, y, z)
      f = ((coords...) ->
        @grid.set(true, coords...)
      ).bind(this)
      @grid.set(true, 2, 2, 2)
      @grid.set(true, 1, 2, 2)
      @grid.set(true, 2, 1, 2)
      @grid.set(true, 2, 2, 1)
      @grid.set(true, 3, 2, 2)
      @grid.set(true, 2, 3, 2)
      @grid.set(true, 2, 2, 3)
    else
      @grid = new Grid(3, [8, 8, 8])
      for x in [0..@grid.size[0] - 1]
        for y in [0..@grid.size[1] - 1]
          for z in [0..@grid.size[1] - 1]
            @grid.set(false, x, y, z)
      f = ((coords...) ->
        @grid.set(true, coords...)
      ).bind(this)
      @grid.forEachInRange(f, [3, 4], [3, 4], [3, 4])
      @grid.forEachInRange(f, [1, 2], [3, 4], [3, 4])
      @grid.forEachInRange(f, [3, 4], [1, 2], [3, 4])
      @grid.forEachInRange(f, [3, 4], [3, 4], [1, 2])
      @grid.forEachInRange(f, [5, 6], [3, 4], [3, 4])
      @grid.forEachInRange(f, [3, 4], [5, 6], [3, 4])
      @grid.forEachInRange(f, [3, 4], [3, 4], [5, 6])


    super(container, width, height, opt_scene, opt_camera)
    @person = new FirstPerson(container, @camera)


  initGeometry: ->
    @scene.add m =new THREE.Mesh(
      new THREE.SphereGeometry(1, 16, 16),
      new THREE.LineBasicMaterial({color: 0xff0000})
      )
    m.position.x = 5
    m.position.y = 5
    m.position.z = 5
    # @grid.forEach(((coords...) ->
    #   if @grid.get(coords...)
    #     @scene.add m = new THREE.Mesh(
    #       new THREE.CubeGeometry(1, 1, 1),
    #       #new THREE.MeshBasicMaterial({color: 0x00ff00, wireframe:true})
    #       new THREE.MeshLambertMaterial({color: 0x00ff00})
    #       )
    #     m.position.x = coords[0]
    #     m.position.y = coords[1]
    #     m.position.z = coords[2]
    # ).bind(this))
    if true
        @grid.forEach(((coords...) ->
          cell = @grid.get(coords...)
          if cell
            mesh = new THREE.Mesh(new THREE.SphereGeometry(.5, 3, 3), new THREE.LineBasicMaterial({color: 0xffff00}))
            [mesh.position.x, mesh.position.y, mesh.position.z] = (c * 5 for c in coords)
            @scene.add mesh
        ).bind(this))
    geometry = generateMarchingCubesGeometry(@grid)
    console.log('computing face normals')
    geometry.computeFaceNormals()
    console.log('finished adding mesh')
    @scene.add new THREE.Mesh(
      geometry,
      #new THREE.MeshBasicMaterial({color: 0x00ff00})
    new THREE.MeshLambertMaterial({color: 0x00ff00})
    )
    console.log('complete')

  initLights: ->
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
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)
