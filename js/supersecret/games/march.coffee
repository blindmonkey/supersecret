lib.load('firstperson', 'grid', 'facemanager', 'marchingcubes', ->
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

  definitions = [
    [[true, true, true, true, true, true, true, true], []]
    [[false, false, false, false, false, false, false, false], []]
    [[true, false, false, false, false, false, false, false], [
      [[0.5, 0, 0], [0, 0.5, 0], [0, 0, 0.5]]
    ]]
    [[true, true, true, true, false, false, false, false], [
      [[0.5, 0, 0], [0.5, 1, 0], [0.5, 1, 1]]
      [[0.5, 0, 0], [0.5, 1, 1], [0.5, 0, 1]]
    ]]
    [[true, true, false, false, false, false, false, false], [
      [[0.5, 0, 0], [0, 0.5, 1], [0.5, 0, 1]]
      [[0.5, 0, 0], [0, 0.5, 0], [0, 0.5, 1]]
    ]]
    [[false, false, true, true, true, true, true, true], [
      [[0.5, 0, 0], [0.5, 0, 1], [0, 0.5, 1]]
      [[0.5, 0, 0], [0, 0.5, 1], [0, 0.5, 0]]
    ]]
    [[true, true, true, false, true, false, false, false], [
      [[0.5, 1, 0], [1, 0, 0.5], [1, 0.5, 0]]
      [[0.5, 1, 0], [0.5, 0, 1], [1, 0, 0.5]]
      [[0.5, 1, 0], [0, 0.5, 1], [0.5, 0, 1]]
      [[0.5, 1, 0], [0, 1, 0.5], [0, 0.5, 1]]
    ]]
    [[true, true, true, false, false, false, false, false], [
     [[0.5, 0, 0], [0.5, 1, 0], [0.5, 0, 1]]
     [[0.5, 0, 1], [0, 1, 0.5], [0, 0.5, 1]]
     [[0.5, 0, 1], [0.5, 1, 0], [0, 1, 0.5]]
    ]]
    [[true, true, false, false, false, false, true, true], [
      [[0, 0.5, 0], [0, 0.5, 1], [0.5, 1, 1]]
      [[0, 0.5, 0], [0.5, 1, 1], [0.5, 1, 0]]
      [[0.5, 0, 0], [1, 0.5, 1], [0.5, 0, 1]]
      [[0.5, 0, 0], [1, 0.5, 0], [1, 0.5, 1]]
    ]]
    [[true, false, false, false, false, false, true, false], [
      [[0, 0, 0.5], [1, 1, 0.5], [0.5, 1, 0]]
      [[0, 0, 0.5], [0.5, 1, 0], [0, 0.5, 0]]
      [[0, 0, 0.5], [0.5, 0, 0], [1, 0.5, 0]]
      [[0, 0, 0.5], [1, 0.5, 0], [1, 1, 0.5]]
    ]]
    [[false, false, false, true, false, true, true, false], [
      [[0.5, 1, 1], [1, 0.5, 1], [1, 1, 0.5]]
      [[0, 1, 0.5], [0.5, 0, 1], [0, 0.5, 1]]
      [[0, 1, 0.5], [1, 0, 0.5], [0.5, 0, 1]]
      [[0, 1, 0.5], [1, 0.5, 0], [1, 0, 0.5]]
      [[0, 1, 0.5], [0.5, 1, 0], [1, 0.5, 0]]
    ]]
    [[true, false, false, false, false, false, false, true], [
      [[0, 0, 0.5], [1, 0.5, 1], [0.5, 1, 1]]
      [[0, 0, 0.5], [0.5, 1, 1], [0, 0.5, 0]]
      [[0, 0.5, 0], [0.5, 1, 1], [1, 1, 0.5]]
      [[0, 0.5, 0], [1, 1, 0.5], [0.5, 0, 0]]
      [[0.5, 0, 0], [1, 1, 0.5], [1, 0.5, 1]]
      [[0.5, 0, 0], [1, 0.5, 1], [0, 0, 0.5]]
    ]]
    [[true, true, false, false, false, false, true, false], [
      [[0, 0.5, 0], [1, 1, 0.5], [0.5, 1, 0]]
      [[0, 0.5, 0], [0, 0.5, 1], [1, 1, 0.5]]
      [[0, 0.5, 1], [0.5, 0, 1], [1, 1, 0.5]]
      [[0.5, 0, 1], [0.5, 0, 0], [1, 0.5, 0]]
      [[0.5, 0, 1], [1, 0.5, 0], [1, 1, 0.5]]
    ]]
    [[true, false, false, false, false, true, true, true], [
      [[1, 0.5, 0], [1, 0, 0.5], [0.5, 0, 0]]
      [[0, 0.5, 0], [0, 0, 0.5], [0.5, 0, 1]]
      [[0, 0.5, 0], [0.5, 0, 1], [0.5, 1, 1]]
      [[0, 0.5, 0], [0.5, 1, 1], [0.5, 1, 0]]
    ]]
    [[true, false, false, false, true, true, false, true], [
      [[1, 0.5, 0], [0, 0.5, 0], [0, 0, 0.5]]
      [[1, 0.5, 0], [0, 0, 0.5], [0.5, 0, 1]]
      [[1, 0.5, 0], [0.5, 0, 1], [0.5, 1, 1]]
      [[1, 0.5, 0], [0.5, 1, 1], [1, 1, 0.5]]
    ]]
    [[true, false, false, false, true, false, true, true], [
      [[0, 0, 0.5], [1, 0, 0.5], [0, 0.5, 0]]
      [[0, 0.5, 0], [1, 0, 0.5], [0.5, 1, 0]]
      [[0.5, 1, 0], [1, 0, 0.5], [0.5, 1, 1]]
      [[1, 0, 0.5], [1, 0.5, 1], [0.5, 1, 1]]
    ]]
    [[true, true, true, true, true, false, false, false], [
      [[0.5, 1, 1], [0.5, 0, 1], [1, 0, 0.5]]
      [[0.5, 1, 1], [1, 0, 0.5], [1, 0.5, 0]]
      [[0.5, 1, 1], [1, 0.5, 0], [0.5, 1, 0]]
    ]]
    [[true, false, true, true, true, true, false, false], [
      [[0, 0.5, 1], [0, 0, 0.5], [0.5, 0, 1]]
      [[0.5, 1, 1], [1, 0.5, 1], [1, 0.5, 0]]
      [[0.5, 1, 1], [1, 0.5, 0], [0.5, 1, 0]]
    ]]
    [[true, false, false, true, false, true, true, false], [
      [[0.5, 1, 1], [1, 0.5, 1], [1, 1, 0.5]]
      [[0, 1, 0.5], [0.5, 1, 0], [0, 0.5, 0]]
      [[0, 0.5, 1], [0, 0, 0.5], [0.5, 0, 1]]
      [[1, 0, 0.5], [0.5, 0, 0], [1, 0.5, 0]]
    ]]
    [[true, false, false, true, false, true, true, true], [
      [[0, 1, 0.5], [0.5, 1, 0], [0, 0.5, 0]]
      [[1, 0.5, 0], [1, 0, 0.5], [0.5, 0, 0]]
      [[0, 0.5, 1], [0, 0, 0.5], [0.5, 0, 1]]
    ]]
    [[true, false, false, true, true, true, true, true], [
      [[0, 0.5, 1], [0, 0, 0.5], [0.5, 0, 1]]
      [[0, 1, 0.5], [0.5, 1, 0], [0, 0.5, 0]]
    ]]
    [[true, false, true, true, true, true, false, true], [
      [[0, 0.5, 1], [0, 0, 0.5], [0.5, 0, 1]]
      [[0.5, 1, 0], [1, 1, 0.5], [1, 0.5, 0]]
    ]]
    [[true, true, true, true, true, true, true, false], [
      [[0.5, 1, 1], [1, 0.5, 1], [1, 1, 0.5]]
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
      for k in [0..transforms.length - 1]
        [kt, ku] = transforms[k]
        newTransforms.push [combineTransforms(it, jt, kt), combineTransforms(ju, iu, ku)]
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
    while a.length < 8
      a.splice(0, 0, false)
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
      if n not of table
        c++
        table[n] = [polygons, transform[0]]
  for i in [0..255]
    a = numberToArray(i)
    if i not of table
      console.log(a)

  console.log(c + 'definitions')

  identified = 0
  remaining = 0
  #geometry = new THREE.Geometry()
  faceManager = new FaceManager()
  console.log('generating geometry')
  for x in [0..grid.size[0]-2]
    console.log(x / grid.size[0] * 100)
    for y in [0..grid.size[1]-2]
      for z in [0..grid.size[2]-2]
        originalCorners = getCornerArray(x, y, z)
        doNext = false
        for c in originalCorners
          if c is undefined
            doNext = true
            break
        continue if doNext

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
          identified++
          #console.log('yeah')
          #for polygon in polygons
          #console.log(polygon)
          for face in polygons
            transformedFace = getTransformedFace(transform, face, [x * scale, y * scale, z * scale])
            #console.log(transformedFace)
            faceManager.addFace(transformedFace...)
        else
          remaining++
  console.log 'faces computed ' + identified + '/' + remaining
  g = faceManager.generateGeometry()
  console.log 'geometry generated'
  return g



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
    @dirty = true
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

  generateChunk: (cx, cy, cz) ->
    chunk = new Grid(3, @chunkSize)
    for x in [0..@chunkSize[0]-2]
      for y in [0..@chunkSize[1]-2]
        for z in [0..@chunkSize[2]-2]
          n = @noise.noise3D(
            (x + cx * @chunkSize[0]) / @scale[0],
            (y + cy * @chunkSize[1]) / @scale[1],
            (z + cz * @chunkSize[2]) / @scale[2]) - (y + cy * @chunkSize[1] - @seaLevel) / 32
          chunk.set(n > 0, x, y, z)
    @chunks.set(chunk, cx, cy, cz)

  updateGeometry: ->


  get: (x, y, z) ->
    cx = Math.floor(x / @chunkSize[0])
    cy = Math.floor(y / @chunkSize[1])
    cz = Math.floor(z / @chunkSize[2])
    chunk = @chunks.get(cx, cy, cz)
    if chunk is undefined
      return undefined
    if cx >= 0
      x -= cx
    else
      x += @chunkSize[0] * -cx
    if cy >= 0
      y -= cy
    else
      y += @chunkSize[1] * -cy
    if cz >= 0
      z -= cz
    else
      z += @chunkSize[2] * -cz
    return chunk.get(x, y, z)


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


    @chunks = new Grid(3, [Infinity, Infinity, Infinity])
    super(container, width, height, opt_scene, opt_camera)
    @person = new FirstPerson(container, @camera)

    generateChunk = ((cx, cy, cz) ->
      chunk = new Grid(3, @chunkSize)
      for x in [0..@chunkSize[0]-1]
        for y in [0..@chunkSize[1]-1]
          for z in [0..@chunkSize[2]-1]
            n = @noise.noise3D(
              (x + cx * @chunkSize[0]) / horizontalScale,
              (y + cy * @chunkSize[1]) / verticalScale,
              (z + cz * @chunkSize[2]) / horizontalScale) - (y + cy * @chunkSize[1] - seaLevel) / 32
            chunk.set(n > 0, x, y, z)
      data =
        chunk: chunk
        mesh: null
      @chunks.set(data, cx, cy, cz)
    ).bind(this)
    generateChunk(0, 0, 0)
    generateChunk(1, 0, 0)
    generateChunk(1, 0, 1)
    generateChunk(0, 0, 1)
    console.log('generation complete')

    @selectedChunk =
      x: 0
      y: 0
      z: 0
    $(document).keydown(((e) ->
      switch e.keyCode
        when 74 # J
          @selectedChunk.x -= 1
        when 76 # L
          @selectedChunk.x += 1
        when 73 # I
          @selectedChunk.z += 1
        when 75 # K
          @selectedChunk.z -= 1
        when 85 # U
          @selectedChunk.y -= 1
        when 79 # O
          @selectedChunk.y += 1
        when 71 # G
          generateChunk(@selectedChunk.x, @selectedChunk.y, @selectedChunk.z)
      console.log(@selectedChunk.x + ', ' + @selectedChunk.y + ', ' + @selectedChunk.z, @chunks.exists(@selectedChunk.x, @selectedChunk.y, @selectedChunk.z))
    ).bind(this))


  initGeometry: ->


    @scene.add m = new THREE.Mesh(
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
    #geometry = generateMarchingCubesGeometry(@grid)
    generateChunkGeometry = ((cx, cy, cz) ->

      chunk = null
      getFromAny = ((x, y, z) ->
        actualChunk = chunk
        [ncx, ncy, ncz] = [cx, cy, cz]
        if x < 0
          x = chunk.size[0] + x
          ncx--
        else if x > chunk.size[0] - 1
          x = x - (chunk.size[0] - 1)
          ncx++
        if y < 0
          y = chunk.size[1] + y
          ncy--
        else if y > chunk.size[1] - 1
          y = y - (chunk.size[1] - 1)
          ncy++
        if z < 0
          z = chunk.size[2] + z
          ncz--
        else if z > chunk.size[2] - 1
          z = z - (chunk.size[2] - 1)
          ncz++
        if not @chunks.exists(ncx, ncy, ncz)
          return undefined
        if ncx != cx or ncy != cy or ncz != cz
          actualChunk = @chunks.get(ncx, ncy, ncz).chunk
        return actualChunk.get(x, y, z)
      ).bind(this)

      cubes = new MarchingCubes()
      chunk = @chunks.get(cx, cy, cz).chunk
      geometry = cubes.generateGeometry(getFromAny, @cubeSize, [-1, @chunkSize[0]-1], [-1, @chunkSize[1]-1], [-1, @chunkSize[2]-1])
      #geometry = cubes.generateGeometry(getFromAny, @cubeSize, [-1, @chunkSize[0]-1], [-1, @chunkSize[1]-1], [-1, @chunkSize[2]-1])
      console.log('computing face normals')
      geometry.computeFaceNormals()
      console.log('finished adding mesh')
      @scene.add mesh = new THREE.Mesh(
        geometry,
        #new THREE.MeshBasicMaterial({color: 0x00ff00})
      new THREE.MeshLambertMaterial({color: 0x00ff00, ambient: 0x00ff00})
      )
      mesh.position.x = cx * @cubeSize * (@chunkSize[0] - 1)
      mesh.position.y = cy * @cubeSize * (@chunkSize[1] - 1)
      mesh.position.z = cz * @cubeSize * (@chunkSize[2] - 1)
    ).bind(this)
    @chunks.handleEvent('set', (data, coords...) ->
      console.log('Generating ' + coords)
      generateChunkGeometry(coords...))
    #@chunks.forEach()
    #generateChunkGeometry(0,0,0)
    console.log('complete')

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
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)
