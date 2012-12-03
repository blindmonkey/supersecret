lib.load('firstperson', 'facemanager', ->
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
    a = [
      grid.get(x, y, z)
      grid.get(x, y, z + 1)
      grid.get(x, y + 1, z)
      grid.get(x, y + 1, z + 1)
      grid.get(x + 1, y, z)
      grid.get(x + 1, y, z + 1)
      grid.get(x + 1, y + 1, z)
      grid.get(x + 1, y + 1, z + 1)
    ]
    return (!!(i and i.data) for i in a)
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

getIndex = (position, size) ->
  return position.x + position.y * size.x + position.z * size.x * size.y

getPath = (obj, path) ->
  for i in [0..path.length - 1]
    if path[i] not of obj
      return undefined
    else
      obj = obj[path[i]]
  return obj

setPath = (obj, path, content) ->
  for i in [0..path.length - 1]
    if i == path.length - 1
      obj[path[i]] = content
    else
      if path[i] not of obj
        obj[path[i]] = {}
      obj = obj[path[i]]

class Chunk
  constructor: (size, init) ->
    @data = []
    @size = size
    for x in [1..size.x]
      for y in [1..size.y]
        for z in [1..size.z]
          @data.push(init and init(x, y, z) or null)

  set: (position, value) ->
    if position.x < 0 or position.x >= @size.x or position.y < 0 or position.y >= @size.y or position.z <0 or position.z >= @size.z
      return false
    i = getIndex(position, @size)
    @data[i] = value
    return true

  get: (position) ->
    if position.x < 0 or position.x >= @size.x or position.y < 0 or position.y >= @size.y or position.z <0 or position.z >= @size.z
      return false
    i = getIndex(position, @size)
    return @data[i]

forEachInSize = (size, f) ->
  min = 0
  max = size
  if size instanceof Object
    min = size.min
    max = size.max
  else
    max = size - 1
  for i in [min..max]
    f(i)



class ChunkManager
  constructor: (chunkSize, init) ->
    @size = chunkSize
    #@cubeSize = cubeSize
    @cache = {}
    @events = {}
    @geometry = null
    @initChunk = init
    @limits = null
    if @size.x != Infinity and @size.y != Infinity and @size.z != Infinity
      forEachInSize(@size.x, ((x) ->
        forEachInSize(@size.y, ((y) ->
          forEachInSize(@size.z, ((z) ->
            @generateChunk(x, y, z)
          ).bind(this))
        ).bind(this))
      ).bind(this))


  fireEvent: (name, args...) ->
    if name not of @events
      return
    (handler(args...) for handler in @events[name])

  registerHandler: (name, handler) ->
    if name not of @events
      @events[name] = []
    @events[name].push(handler)

  validateChunk: (x, y, z) ->
    validateParameter = (param, paramSize) ->
      if paramSize instanceof Object
        return paramSize.min <= param <= paramSize.max
      else if paramSize == Infinity
        return true
      return 0 <= param < paramSize
    return validateParameter(x, @size.x) and validateParameter(y, @size.y) and validateParameter(z, @size.z)

  normalizeChunk: (x, y, z) ->
    return {x:Math.floor(x), y:Math.floor(y), z:Math.floor(z)}

  getChunkId: (x, y, z) ->
    return x + '/' + y + '/' + z

  generateChunk: (x, y, z) ->
    @ongenerate and @ongenerate(x, y, z)
    chunkData = @initChunk and @initChunk.bind(this)(x, y, z) or null
    @set(x, y, z, chunkData)
    return chunkData

  generateChunks: (size, ongenerate) ->
    if size.x != Infinity and size.y != Infinity and size.z != Infinity
      forEachInSize(size.x, ((x) ->
        forEachInSize(size.y, ((y) ->
          forEachInSize(size.z, ((z) ->
            c = @generateChunk(x, y, z)
            ongenerate and ongenerate(x, y, z, c)
          ).bind(this))
        ).bind(this))
      ).bind(this))

  getNeighbors: (x, y, z) ->
    return {
      above: @get(x, y + 1, z)
      below: @get(x, y - 1, z)
      left: @get(x - 1, y, z)
      right: @get(x + 1, y, z)
      front: @get(x, y, z + 1)
      back: @get(x, y, z - 1)
    }

  updateLimits: (x, y, z) ->
    if @limits == null
      @limits =
        x:
          min: Infinity
          max: -Infinity
        y:
          min: Infinity
          max: -Infinity
        z:
          min: Infinity
          max: -Infinity
    @limits.x.min = x if x < @limits.x.min
    @limits.x.max = x if x > @limits.x.max
    @limits.y.min = y if y < @limits.y.min
    @limits.y.max = y if y > @limits.y.max
    @limits.z.min = z if z < @limits.z.min
    @limits.z.max = z if z > @limits.z.max

  forEach: (f) ->
    if @limits != null
      for x in [@limits.x.min..@limits.x.max]
        for y in [@limits.y.min..@limits.y.max]
          for z in [@limits.z.min..@limits.z.max]
            f(x, y, z)


  set: (x, y, z, content_or_property, maybe_content) ->
    property = 'data'
    content = content_or_property
    if maybe_content
      property = content_or_property
      content = maybe_content

    if not @validateChunk(x, y, z)
      throw "Chunk ID is invalid"
    chunk = @normalizeChunk(x, y, z)

    @updateLimits(chunk.x, chunk.y, chunk.z)

    chunkId = @getChunkId(chunk.x, chunk.y, chunk.z)
    if chunkId not of @cache
      @cache[chunkId] = {}

    data = @cache[chunkId]
    propertyStr = property
    property = property.split('.')
    setPath(data, property, content)
    @fireEvent('update', x, y, z, propertyStr)

  get: (x, y, z, maybe_property) ->
    if not @validateChunk(x, y, z)
      return null
      throw "Chunk ID is invalid - " + x + ', ' + y + ', ' + z
    property = maybe_property or 'data'
    chunk = @normalizeChunk(x, y, z)

    chunkId = @getChunkId(chunk.x, chunk.y, chunk.z)
    chunk = @cache[chunkId]
    if chunk
      property = property.split('.')
      data = chunk
      for p in property
        if p not of data
          return undefined
        data = data[p]
      return data
    return undefined
    return chunk and chunk[property]

class ChunkGeometryManager
  constructor: (chunk, chunkManager, cubeSize) ->
    @chunkManager = chunkManager
    @chunk = chunk
    @cubeSize = cubeSize
    @geometry = null

  createVoxelFaces: (x, y, z) ->
    voxel = @chunk.get(x, y, z)
    neighbors = @chunk.getNeighbors(x, y, z)
    px = x
    py = y
    pz = z
    x += 1
    y += 1
    z += 1

    faces = {}
    verticesSize =
      x: @chunk.size.x + 1
      y: @chunk.size.y + 1
      z: @chunk.size.z + 1

    if not neighbors.above
      faces.above = [
        new THREE.Face3(
          getIndex({x:px,y:y,z:z}, verticesSize),
          getIndex({x:x,y:y,z:z}, verticesSize),
          getIndex({x:x,y:y,z:pz}, verticesSize)),
        new THREE.Face3(
          getIndex({x:px,y:y,z:z}, verticesSize),
          getIndex({x:x,y:y,z:pz}, verticesSize),
          getIndex({x:px,y:y,z:pz}, verticesSize))]

    if not neighbors.below
      # if py == 0
      #   console.log("CREATING A BELOW FACE FOR 0", px, pz, neighbors.below)
      faces.below = [
        new THREE.Face3(
          getIndex({x:px,y:py,z:z}, verticesSize),
          getIndex({x:x,y:py,z:pz}, verticesSize),
          getIndex({x:x,y:py,z:z}, verticesSize)),
        new THREE.Face3(
          getIndex({x:px,y:py,z:z}, verticesSize),
          getIndex({x:px,y:py,z:pz}, verticesSize),
          getIndex({x:x,y:py,z:pz}, verticesSize))]

    if not neighbors.left
      faces.left = [
        new THREE.Face3(
          getIndex({x:px,y:y,z:z}, verticesSize),
          getIndex({x:px,y:y,z:pz}, verticesSize),
          getIndex({x:px,y:py,z:z}, verticesSize)),
        new THREE.Face3(
          getIndex({x:px,y:py,z:z}, verticesSize),
          getIndex({x:px,y:y,z:pz}, verticesSize),
          getIndex({x:px,y:py,z:pz}, verticesSize))]

    if not neighbors.right
      faces.right = [
        new THREE.Face3(
          getIndex({x:x,y:y,z:z}, verticesSize),
          getIndex({x:x,y:py,z:z}, verticesSize),
          getIndex({x:x,y:y,z:pz}, verticesSize)),
        new THREE.Face3(
          getIndex({x:x,y:py,z:z}, verticesSize),
          getIndex({x:x,y:py,z:pz}, verticesSize),
          getIndex({x:x,y:y,z:pz}, verticesSize))]

    if not neighbors.back
      faces.back = [
        new THREE.Face3(
          getIndex({x:px,y:y,z:pz}, verticesSize),
          getIndex({x:x,y:y,z:pz}, verticesSize),
          getIndex({x:x,y:py,z:pz}, verticesSize)),
        new THREE.Face3(
          getIndex({x:px,y:y,z:pz}, verticesSize),
          getIndex({x:x,y:py,z:pz}, verticesSize),
          getIndex({x:px,y:py,z:pz}, verticesSize))]

    if not neighbors.front
      faces.front = [
        new THREE.Face3(
          getIndex({x:px,y:y,z:z}, verticesSize),
          getIndex({x:x,y:py,z:z}, verticesSize),
          getIndex({x:x,y:y,z:z}, verticesSize)),
        new THREE.Face3(
          getIndex({x:px,y:y,z:z}, verticesSize),
          getIndex({x:px,y:py,z:z}, verticesSize),
          getIndex({x:x,y:py,z:z}, verticesSize))]
    return faces

  init: ->
    #console.log("Generating geometry")
    geometry = new THREE.Geometry()

    meshes = []
    #console.log('geo init')
    updater = new Updater(100)
    for z in [0..@chunk.size.z]
      for y in [0..@chunk.size.y]
        for x in [0..@chunk.size.x]
          #updater.update('Current coord: ' + x + ', ' + y + ', ' + z)
          geometry.vertices.push(new THREE.Vector3(x * @cubeSize, y * @cubeSize, z * @cubeSize))
          if x > 0 and y > 0 and z > 0
            #voxel = @chunk.get({x:x-1,y:y-1,z:z-1})
            voxel = @chunk.get(x-1,y-1,z-1)
            # if x == 2 and y == 2 and z == 2
            #   console.log(voxel, {x:x-1,y:y-1,z:z-1})
            continue if not voxel
            faces = @createVoxelFaces(x-1, y-1, z-1)
            geometry.faces.push(faces.above...) if faces.above
            geometry.faces.push(faces.below...) if faces.below
            geometry.faces.push(faces.left...) if faces.left
            geometry.faces.push(faces.right...) if faces.right
            geometry.faces.push(faces.back...) if faces.back
            geometry.faces.push(faces.front...) if faces.front
    # console.log("Geometry generated. Computing face normals for " + geometry.faces.length + " faces")
    if geometry.faces.length == 0
      return undefined
    geometry.computeFaceNormals()
    # console.log('done')
    #material = new THREE.LineBasicMaterial({color: 0xff0000})})
    material = new THREE.MeshPhongMaterial({color: 0xff0000})
    mesh = new THREE.Mesh(geometry, material)
    return mesh

  createVoxelFaces: (x, y, z) ->
    voxel = @chunk.get(x, y, z)
    neighbors = @chunk.getNeighbors(x, y, z)
    px = x
    py = y
    pz = z
    x += 1
    y += 1
    z += 1

    faces = {}
    verticesSize =
      x: @chunk.size.x + 1
      y: @chunk.size.y + 1
      z: @chunk.size.z + 1

    if not neighbors.above
      faces.above = [{
          a:new THREE.Vector3(px * @cubeSize, y * @cubeSize, z * @cubeSize),
          b:new THREE.Vector3(x * @cubeSize, y * @cubeSize, z * @cubeSize),
          c:new THREE.Vector3(x * @cubeSize, y * @cubeSize, pz * @cubeSize)},{
          a:new THREE.Vector3(px * @cubeSize, y * @cubeSize, z * @cubeSize),
          b:new THREE.Vector3(x * @cubeSize, y * @cubeSize, pz * @cubeSize),
          c:new THREE.Vector3(px * @cubeSize, y * @cubeSize, pz * @cubeSize)}]

    if not neighbors.below
      # if py == 0
      #   console.log("CREATING A BELOW FACE FOR 0", px, pz, neighbors.below)
      faces.below = [{
          a:new THREE.Vector3(px * @cubeSize, py * @cubeSize, z * @cubeSize),
          b:new THREE.Vector3(x * @cubeSize, py * @cubeSize, pz * @cubeSize),
          c:new THREE.Vector3(x * @cubeSize, py * @cubeSize, z * @cubeSize)},{
          a:new THREE.Vector3(px * @cubeSize, py * @cubeSize, z * @cubeSize),
          b:new THREE.Vector3(px * @cubeSize, py * @cubeSize, pz * @cubeSize),
          c:new THREE.Vector3(x * @cubeSize, py * @cubeSize, pz * @cubeSize)}]

    if not neighbors.left
      faces.left = [{
          a:new THREE.Vector3(px * @cubeSize, y * @cubeSize, z * @cubeSize),
          b:new THREE.Vector3(px * @cubeSize, y * @cubeSize, pz * @cubeSize),
          c:new THREE.Vector3(px * @cubeSize, py * @cubeSize, z * @cubeSize)},{
          a:new THREE.Vector3(px * @cubeSize, py * @cubeSize, z * @cubeSize),
          b:new THREE.Vector3(px * @cubeSize, y * @cubeSize, pz * @cubeSize),
          c:new THREE.Vector3(px * @cubeSize, py * @cubeSize, pz * @cubeSize)}]

    if not neighbors.right
      faces.right = [{
          a:new THREE.Vector3(x * @cubeSize, y * @cubeSize, z * @cubeSize),
          b:new THREE.Vector3(x * @cubeSize, py * @cubeSize, z * @cubeSize),
          c:new THREE.Vector3(x * @cubeSize, y * @cubeSize, pz * @cubeSize)},{
          a:new THREE.Vector3(x * @cubeSize, py * @cubeSize, z * @cubeSize),
          b:new THREE.Vector3(x * @cubeSize, py * @cubeSize, pz * @cubeSize),
          c:new THREE.Vector3(x * @cubeSize, y * @cubeSize, pz * @cubeSize)}]

    if not neighbors.back
      faces.back = [{
          a:new THREE.Vector3(px * @cubeSize, y * @cubeSize, pz * @cubeSize),
          b:new THREE.Vector3(x * @cubeSize, y * @cubeSize, pz * @cubeSize),
          c:new THREE.Vector3(x * @cubeSize, py * @cubeSize, pz * @cubeSize)},{
          a:new THREE.Vector3(px * @cubeSize, y * @cubeSize, pz * @cubeSize),
          b:new THREE.Vector3(x * @cubeSize, py * @cubeSize, pz * @cubeSize),
          c:new THREE.Vector3(px * @cubeSize, py * @cubeSize, pz * @cubeSize)}]

    if not neighbors.front
      faces.front = [{
          a:new THREE.Vector3(px * @cubeSize, y * @cubeSize, z * @cubeSize),
          b:new THREE.Vector3(x * @cubeSize, py * @cubeSize, z * @cubeSize),
          c:new THREE.Vector3(x * @cubeSize, y * @cubeSize, z * @cubeSize)},{
          a:new THREE.Vector3(px * @cubeSize, y * @cubeSize, z * @cubeSize),
          b:new THREE.Vector3(px * @cubeSize, py * @cubeSize, z * @cubeSize),
          c:new THREE.Vector3(x * @cubeSize, py * @cubeSize, z * @cubeSize)}]
    return faces

  init: ->
    geometry = generateMarchingCubesGeometry(@chunk, @cubeSize)
    console.log(geometry.faces.length)
    geometry.computeFaceNormals()
    # console.log('done')
    #material = new THREE.LineBasicMaterial({color: 0xff0000})})
    material = new THREE.MeshPhongMaterial({color: 0xff0000})
    mesh = new THREE.Mesh(geometry, material)
    return mesh

    console.log("Generating geometry")
    #geometry = new THREE.Geometry()
    faceManager = new FaceManager()

    meshes = []
    #console.log('geo init')
    updater = new Updater(100)
    for z in [0..@chunk.size.z]
      for y in [0..@chunk.size.y]
        for x in [0..@chunk.size.x]
          #updater.update('Current coord: ' + x + ', ' + y + ', ' + z)
          #geometry.vertices.push(new THREE.Vector3(x * @cubeSize, y * @cubeSize, z * @cubeSize))
          if x > 0 and y > 0 and z > 0
            #voxel = @chunk.get({x:x-1,y:y-1,z:z-1})
            voxel = @chunk.get(x-1,y-1,z-1)
            # if x == 2 and y == 2 and z == 2
            #   console.log(voxel, {x:x-1,y:y-1,z:z-1})
            continue if not voxel
            faces = @createVoxelFaces(x-1, y-1, z-1)
            faceManager.addFaces(faces.above) if faces.above
            faceManager.addFaces(faces.below) if faces.below
            faceManager.addFaces(faces.left) if faces.left
            faceManager.addFaces(faces.right) if faces.right
            faceManager.addFaces(faces.back) if faces.back
            faceManager.addFaces(faces.front) if faces.front
    # console.log("Geometry generated. Computing face normals for " + geometry.faces.length + " faces")
    # if geometry.faces.length == 0
    #   return undefined
    geometry = faceManager.generateGeometry()
    geometry.computeFaceNormals()
    # console.log('done')
    #material = new THREE.LineBasicMaterial({color: 0xff0000})})
    material = new THREE.MeshPhongMaterial({color: 0xff0000})
    mesh = new THREE.Mesh(geometry, material)
    return mesh


class WorldGeometryManager
  constructor: (chunks, scene, chunkSize, cubeSize) ->
    @chunks = chunks
    @chunkSize = chunkSize
    @cubeSize = cubeSize
    @scene = scene

    @chunks.registerHandler('update', ((x, y, z, updateType) ->
      console.log(updateType)
      return if updateType != 'data' and updateType isnt undefined

      chunk = @chunks.get(x, y, z)
      if chunk is undefined
        console.log("Updating undefined chunk")
        return
      else
        console.log('Chunk update event handler ' + x + ', ' + y + ', ' + z)
      mesh = @chunks.get(x, y, z, 'mesh')
      if mesh
        @scene.remove mesh

      updateChunks = []
      updateChunk = (x, y, z) ->
        updateChunks.push([x, y, z])


      chunkWrapper = {
        size: chunk.size
        get: chunk.get.bind(chunk)

        getNeighbors: (nx, ny, nz) ->
          neighbors = chunk.getNeighbors(nx, ny, nz)
          # Explanation:
          # If a neighbor (for this example, the neighbor below) is 'null' that
          # means that it is outside of the chunk and therefore unknown. So the
          # solution here is to get the below chunk
          if neighbors.below is null and ny == 0 and ch = chunks.get(x, y-1, z)
            neighbors.below = ch.get(nx, chunk.size.y - 1, nz)
            updateChunk(x, y-1, z)

          if neighbors.above is null and ny == chunk.size.y - 1 and ch = chunks.get(x, y+1, z)
            neighbors.above = ch.get(nx, 0, nz)
            updateChunk(x, y+1, z)

          if neighbors.left is null and nx == 0 and ch = chunks.get(x-1, y, z)
              neighbors.left = ch.get(chunk.size.x - 1, ny, nz)
              updateChunk(x-1, y, z)

          if neighbors.right is null and nx == chunk.size.x - 1 and ch = chunks.get(x+1, y, z)
              neighbors.right = ch.get(0, ny, nz)
              updateChunk(x+1, y, z)

          if neighbors.back is null and nz == 0 and ch = chunks.get(x, y, z-1)
              neighbors.back = ch.get(nx, ny, chunk.size.z - 1)
              updateChunk(x, y, z-1)

          if neighbors.front is null and nz == chunk.size.z - 1 and ch = chunks.get(x, y, z+1)
              neighbors.front = ch.get(nx, ny, 0)
              updateChunk(x, y, z+1)

          return neighbors

      }

      mesh = new ChunkGeometryManager(chunkWrapper, @chunks, @cubeSize).init()
      console.log("New mesh for " + x + ', ' + y + ', ' + z)
      if updateType == 'data'
        console.log("Doing updates!")
        updated = {}
        for coord in updateChunks
          [xx, yy, zz] = coord
          s = xx + '/' + yy + '/' + zz
          continue if updated[s]
          updated[s] = true
          console.log("Updating chunk " + xx + ', ' + yy + ', ' + zz)
          @chunks.fireEvent('update', xx, yy, zz)

      if mesh
        mesh.position.x = x * cubeSize * chunkSize.x
        mesh.position.y = y * cubeSize * chunkSize.y
        mesh.position.z = z * cubeSize * chunkSize.z
        @scene.add mesh
      @chunks.set(x, y, z, 'mesh', mesh)
    ).bind(this))


class NoiseGenerator
  constructor: (noise, description) ->
    @noise = noise
    @description = description

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


class Updater
  constructor: (frequency) ->
    @frequency = frequency
    @lastUpdate = null

  update: (message) ->
    if not @lastUpdate? or new Date().getTime() - @lastUpdate > @frequency
      @lastUpdate = new Date().getTime()
      console.log(message)


class Statistician
  constructor: (tracker) ->
    @tracked = {}
    @tracker = tracker

  track: (obj) ->
    for p of obj
      @tracked[p] = @tracker(@tracked[p], obj[p])



supersecret.Game = class VoxelGame extends supersecret.BaseGame
  @loaded: false
  constructor: (container, width, height, opt_scene, opt_camera) ->
    console.log 'Generating chunk...'
    noise = new SimplexNoise()
    generator = new NoiseGenerator(noise, [{
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

    rangeTracker = new Statistician((oldObj, newObj) ->
      min = parseFloat('Infinity')
      max = parseFloat('-Infinity')
      if oldObj
        max = oldObj.max
        min = oldObj.min
      if newObj > max
        max = newObj
      if newObj < min
        min = newObj
      return {
        min: min
        max: max
      }
    )
    # @chunk = new ChunkManager({
    #   x: 32
    #   y: 32
    #   z: 32
    # }, (x, y, z) ->
    #   n = generator.noise3D(x, y, z)
    #   rangeTracker.track({n:n})
    #   return n > 0)

    chunkSize = @chunkSize =
      x: 32
      y: 128
      z: 32
    horizontalScale = 2
    verticalScale = 1
    cubeSize = @cubeSize = 4

    seaLevel = chunkSize.y / 2
    @chunks = new ChunkManager({
      x: Infinity
      y: Infinity
      z: Infinity
      }, (cx, cy, cz) ->
        console.log('Generating chunk ' + cx + ', ' + cy + ', ' + cz)
        return new ChunkManager({
          x: chunkSize.x
          y: chunkSize.y
          z: chunkSize.z
        }, (x, y, z) ->
          n = generator.noise3D(
            (x + cx * chunkSize.x) / horizontalScale,
            (y + cy * chunkSize.y) / verticalScale,
            (z + cz * chunkSize.z) / horizontalScale) - (y + cy * chunkSize.y - seaLevel) / 32
          rangeTracker.track({n:n})
          return n > 0)
      )
    # @chunks.generateChunk(0, 0, 0)
    # @chunks.generateChunk(0, -1, 0)
    console.log(rangeTracker.tracked.n)

    super(container, width, height, opt_scene, opt_camera)

    wgm = new WorldGeometryManager(@chunks, @scene, @chunkSize, @cubeSize)

    @chunks.generateChunks({
      x: 1
      z: 1
      y: 1
    })

    DEBUG.expose('chunk', @chunk)
    DEBUG.expose('scene', @scene)

    @camera.position.x = 0
    @camera.position.y = 1
    @camera.position.z = 0

    @projector = new THREE.Projector()

    @person = new FirstPerson(container, @camera)
    @person.updateCamera()
    @mouse = null

    @selectedChunk =
      x: 0
      y: 0
      z: 0

    geometry = new THREE.Geometry()
    geometry.vertices.push new THREE.Vector3(0, 0, 0)
    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, 0, 0)

    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, 0, 0)
    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, 0, @chunkSize.z * @cubeSize)

    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, 0, @chunkSize.z * @cubeSize)
    geometry.vertices.push new THREE.Vector3(0, 0, @chunkSize.z * @cubeSize)

    geometry.vertices.push new THREE.Vector3(0, 0, @chunkSize.z * @cubeSize)
    geometry.vertices.push new THREE.Vector3(0, 0, 0)

    #############

    geometry.vertices.push new THREE.Vector3(0, @chunkSize.y * @cubeSize, 0)
    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, @chunkSize.y * @cubeSize, 0)

    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, @chunkSize.y * @cubeSize, 0)
    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, @chunkSize.y * @cubeSize, @chunkSize.z * @cubeSize)

    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, @chunkSize.y * @cubeSize, @chunkSize.z * @cubeSize)
    geometry.vertices.push new THREE.Vector3(0, @chunkSize.y * @cubeSize, @chunkSize.z * @cubeSize)

    geometry.vertices.push new THREE.Vector3(0, @chunkSize.y * @cubeSize, @chunkSize.z * @cubeSize)
    geometry.vertices.push new THREE.Vector3(0, @chunkSize.y * @cubeSize, 0)

    #############
    geometry.vertices.push new THREE.Vector3(0, 0, 0)
    geometry.vertices.push new THREE.Vector3(0, @chunkSize.y * @cubeSize, 0)
    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, 0, 0)
    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, @chunkSize.y * @cubeSize, 0)
    geometry.vertices.push new THREE.Vector3(0, 0, @chunkSize.z * @cubeSize)
    geometry.vertices.push new THREE.Vector3(0, @chunkSize.y * @cubeSize, @chunkSize.z * @cubeSize)
    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, 0, @chunkSize.z * @cubeSize)
    geometry.vertices.push new THREE.Vector3(@chunkSize.x * @cubeSize, @chunkSize.y * @cubeSize, @chunkSize.z * @cubeSize)

    @selectedChunkMesh = new THREE.Line(
      geometry,
      new THREE.LineBasicMaterial({color: 0x00ff00}),
      THREE.LinePieces)
    @scene.add @selectedChunkMesh


    $(document).keydown(((e) ->
      px = @selectedChunk.x
      py = @selectedChunk.y
      pz = @selectedChunk.z
      if e.keyCode == 74
        @selectedChunk.x -= 1
      else if e.keyCode == 76
        @selectedChunk.x += 1
      else if e.keyCode == 73
        @selectedChunk.z -= 1
      else if e.keyCode == 75
        @selectedChunk.z += 1
      else if e.keyCode == 85
        @selectedChunk.y -= 1
      else if e.keyCode == 79
        @selectedChunk.y += 1
      else if e.keyCode == 90
        @chunks.fireEvent('update', @selectedChunk.x, @selectedChunk.y, @selectedChunk.z, 'data')
      else if e.keyCode == 71
        @chunks.generateChunk(@selectedChunk.x, @selectedChunk.y, @selectedChunk.z)
      if px != @selectedChunk.x or py != @selectedChunk.y or pz != @selectedChunk.z
        @selectedChunkMesh.position.x = @selectedChunk.x * @chunkSize.x * @cubeSize
        @selectedChunkMesh.position.y = @selectedChunk.y * @chunkSize.y * @cubeSize
        @selectedChunkMesh.position.z = @selectedChunk.z * @chunkSize.z * @cubeSize
        console.log('Chunk at ' + @selectedChunk.x + ', ' + @selectedChunk.y + ', ' + @selectedChunk.z + ' = ' + @chunks.get(@selectedChunk.x, @selectedChunk.y, @selectedChunk.z))
    ).bind(this))

    $(container).mousemove(((e) ->
      if @mouse == null
        @mouse = {}
      @mouse.x = e.clientX / @renderer.width * 2 - 1
      @mouse.y = -e.clientY / @renderer.height * 2 + 1
    ).bind(this))


  initGeometry: ->
    # @chunks.forEach(((x, y, z) ->
    #   chunk = @chunks.get(x, y, z)
    #   mesh = new ChunkGeometryManager(chunk, @cubeSize).init()
    #   mesh.position.x = x * @cubeSize * @chunkSize.x
    #   mesh.position.y = y * @cubeSize * @chunkSize.y
    #   mesh.position.z = z * @cubeSize * @chunkSize.z
    #   # console.log(@chunk.get({x:1, y:1, z:1}))
    #   @scene.add(mesh)
    # ).bind(this))
    # @scene.add(new THREE.Mesh(
    #  new THREE.SphereGeometry(10, 16, 16),
    #  new THREE.MeshPhongMaterial({color: 0xff0000})))

  initLights: ->
    @scene.add new THREE.AmbientLight(0x505050)
    # light = new THREE.PointLight(0x505050, 3, 2000)
    # light.x = -150
    # light.y = 0
    # light.z = 36
    # DEBUG.expose('light', light)
    # @scene.add light
    light = new THREE.DirectionalLight(0xffffff, .5)
    light.x = 1
    light.y = 1
    light.z = 1
    @scene.add light
    light = new THREE.DirectionalLight(0xffffff, .5)
    light.x = -1
    light.y = 1
    light.z = -1
    @scene.add light
    light = new THREE.DirectionalLight(0xffffff, .5)
    light.x = -1
    light.y = -1
    light.z = -1
    @scene.add light

  render: (delta) ->
    @person.update(delta)
    if @mouse and false
      vector = new THREE.Vector3(@mouse.x, @mouse.y, 0)
      @projector.unprojectVector(vector, @camera)

      ray = new THREE.Ray(@camera.position, vector.subSelf( @camera.position ).normalize() );

      oldIntersects = @intersects
      @intersects = ray.intersectObjects( @scene.children );
      #console.log(@mouse.x, @mouse.y, intersects)
      # if oldIntersects and oldIntersects.length > 0
      #   oldIntersects[0].object.material.emissive.setHex(0x000000)
      if @intersects.length > 0
        console.log(@mouse.x, @mouse.y)
        face = @intersects[0].face
        createSphereAt = (v) ->
          s = new THREE.Mesh(
            new THREE.SphereGeometry(1, 4, 4),
            new THREE.LineBasicMaterial({color: 0x00ff00})
          )
          s.position.x = v.x
          s.position.y = v.y
          s.position.z = v.z
          s.overdraw = true
          return s
        @scene.add createSphereAt(@intersects[0].object.geometry.vertices[face.a])
        @scene.add createSphereAt(@intersects[0].object.geometry.vertices[face.b])
        @scene.add createSphereAt(@intersects[0].object.geometry.vertices[face.c])
        #@intersects[0].object.material.emissive.setHex(0x00ff00)
        console.log(@intersects[0])

    @renderer.renderer.render(@scene, @camera)
