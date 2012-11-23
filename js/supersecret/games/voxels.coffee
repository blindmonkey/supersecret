getIndex = (position, size) ->
  return position.x + position.y * size.x + position.z * size.x * size.y

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


class ChunkManager
  constructor: (chunkSize, init) ->
    @size = chunkSize
    #@cubeSize = cubeSize
    @cache = {}
    @events = {}
    @geometry = null
    for x in [1..@size.x]
      for y in [1..@size.y]
        for z in [1..@size.z]
          @set(x-1, y-1, z-1, init and init(x-1, y-1, z-1) or null)

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
        return paramSize.min <= x <= paramSize.max
      else if paramSize == parseFloat('Infinity')
        return true
      return 0 <= x < paramSize
    return validateParameter(x, @size.x) and validateParameter(y, @size.y) and validateParameter(z, @size.z)

  normalizeChunk: (x, y, z) ->
    return {x:Math.floor(x), y:Math.floor(y), z:Math.floor(z)}

  getChunkId: (x, y, z) ->
    return x + '/' + y + '/' + z

  set: (x, y, z, content_or_property, maybe_content) ->
    property = 'data'
    content = content_or_property
    if maybe_content
      property = content_or_property
      content = maybe_content

    if not @validateChunk(x, y, z)
      throw "Chunk ID is invalid"
    chunk = @normalizeChunk(x, y, z)

    chunkId = @getChunkId(chunk.x, chunk.y, chunk.z)
    if chunkId not of @cache
      @cache[chunkId] = {}

    data = @cache[chunkId]
    property = property.split('.')
    if property.length > 1
      for p in [0..property.length-2]
        if p not of data
          data[p] = {}
        data = data[p]
    data[property[property.length - 1]] = content
    @fireEvent('update', x, y, z)

  get: (x, y, z, maybe_property) ->
    if not @validateChunk(x, y, z)
      return undefined
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
  constructor: (chunk, cubeSize) ->
    @chunk = chunk
    @cubeSize = cubeSize
    @geometry = null

  createVoxelFaces: (x, y, z) ->
    voxel = @chunk.get(x, y, z)
    aboveVoxel = @chunk.get(x,     y + 1, z)
    belowVoxel = @chunk.get(x,     y - 1, z)
    leftVoxel  = @chunk.get(x - 1, y,     z)
    rightVoxel = @chunk.get(x + 1, y,     z)
    backVoxel  = @chunk.get(x,     y,     z - 1)
    frontVoxel = @chunk.get(x,     y,     z + 1)
    px = x
    py = y
    pz = z
    x += 1
    y += 1
    z += 1
    #previousFacesLength = geometry.faces.length

    faces = {}
    verticesSize =
      x: @chunk.size.x + 1
      y: @chunk.size.y + 1
      z: @chunk.size.z + 1

    if not aboveVoxel
      faces.above = [
        new THREE.Face3(
          getIndex({x:px,y:y,z:z}, verticesSize),
          getIndex({x:x,y:y,z:z}, verticesSize),
          getIndex({x:x,y:y,z:pz}, verticesSize)),
        new THREE.Face3(
          getIndex({x:px,y:y,z:z}, verticesSize),
          getIndex({x:x,y:y,z:pz}, verticesSize),
          getIndex({x:px,y:y,z:pz}, verticesSize))]

    if not belowVoxel
      faces.below = [
        new THREE.Face3(
          getIndex({x:px,y:py,z:z}, verticesSize),
          getIndex({x:x,y:py,z:pz}, verticesSize),
          getIndex({x:x,y:py,z:z}, verticesSize)),
        new THREE.Face3(
          getIndex({x:px,y:py,z:z}, verticesSize),
          getIndex({x:px,y:py,z:pz}, verticesSize),
          getIndex({x:x,y:py,z:pz}, verticesSize))]

    if not leftVoxel
      faces.left = [
        new THREE.Face3(
          getIndex({x:px,y:y,z:z}, verticesSize),
          getIndex({x:px,y:y,z:pz}, verticesSize),
          getIndex({x:px,y:py,z:z}, verticesSize)),
        new THREE.Face3(
          getIndex({x:px,y:py,z:z}, verticesSize),
          getIndex({x:px,y:y,z:pz}, verticesSize),
          getIndex({x:px,y:py,z:pz}, verticesSize))]

    if not rightVoxel
      faces.right = [
        new THREE.Face3(
          getIndex({x:x,y:y,z:z}, verticesSize),
          getIndex({x:x,y:py,z:z}, verticesSize),
          getIndex({x:x,y:y,z:pz}, verticesSize)),
        new THREE.Face3(
          getIndex({x:x,y:py,z:z}, verticesSize),
          getIndex({x:x,y:py,z:pz}, verticesSize),
          getIndex({x:x,y:y,z:pz}, verticesSize))]

    if not backVoxel
      faces.back = [
        new THREE.Face3(
          getIndex({x:px,y:y,z:pz}, verticesSize),
          getIndex({x:x,y:y,z:pz}, verticesSize),
          getIndex({x:x,y:py,z:pz}, verticesSize)),
        new THREE.Face3(
          getIndex({x:px,y:y,z:pz}, verticesSize),
          getIndex({x:x,y:py,z:pz}, verticesSize),
          getIndex({x:px,y:py,z:pz}, verticesSize))]

    if not frontVoxel
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
    console.log("Generating geometry")
    geometry = new THREE.Geometry()

    meshes = []
    console.log('geo init')
    updater = new Updater(100)
    for z in [0..@chunk.size.z]
      for y in [0..@chunk.size.y]
        for x in [0..@chunk.size.x]
          updater.update('Current coord: ' + x + ', ' + y + ', ' + z)
          geometry.vertices.push(new THREE.Vector3(x * @cubeSize, y * @cubeSize, z * @cubeSize))
          if x > 0 and y > 0 and z > 0
            #voxel = @chunk.get({x:x-1,y:y-1,z:z-1})
            voxel = @chunk.get(x-1,y-1,z-1)
            if x == 2 and y == 2 and z == 2
              console.log(voxel, {x:x-1,y:y-1,z:z-1})
            continue if not voxel
            faces = @createVoxelFaces(x-1, y-1, z-1)
            geometry.faces.push(faces.above...) if faces.above
            geometry.faces.push(faces.below...) if faces.below
            geometry.faces.push(faces.left...) if faces.left
            geometry.faces.push(faces.right...) if faces.right
            geometry.faces.push(faces.back...) if faces.back
            geometry.faces.push(faces.front...) if faces.front
    console.log("Geometry generated. Computing face normals for " + geometry.faces.length + " faces")
    geometry.computeFaceNormals()
    console.log('done')
    #material = new THREE.LineBasicMaterial({color: 0xff0000})})
    material = new THREE.MeshPhongMaterial({color: 0xff0000})
    mesh = new THREE.Mesh(geometry, material)
    return mesh




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
        multiplier: 1 / 4
      }, {
        scale: 1 / 256
        multiplier: 1 / 8
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
    @chunk = new ChunkManager({
      x: 32
      y: 32
      z: 32
    }, (x, y, z) ->
      n = generator.noise3D(x, y, z)
      rangeTracker.track({n:n})
      return n > 0)
    @cubeSize = 8
    console.log(rangeTracker.tracked.n)

    super(container, width, height, opt_scene, opt_camera)

    DEBUG.expose('chunk', @chunk)
    DEBUG.expose('scene', @scene)

    @camera.position.x = 0
    @camera.position.y = 1
    @camera.position.z = 0

    @projector = new THREE.Projector()

    @person = new supersecret.FirstPerson(container, @camera)
    @person.updateCamera()
    @mouse = null

    $(container).mousemove(((e) ->
      if @mouse == null
        @mouse = {}
      @mouse.x = e.clientX / @renderer.width * 2 - 1
      @mouse.y = -e.clientY / @renderer.height * 2 + 1
    ).bind(this))


  initGeometry: ->
    mesh = new ChunkGeometryManager(@chunk, @cubeSize).init()
    # console.log(@chunk.get({x:1, y:1, z:1}))
    @scene.add(mesh)
    @scene.add(new THREE.Mesh(
      new THREE.SphereGeometry(10, 16, 16),
      new THREE.MeshPhongMaterial({color: 0xff0000})))

  initLights: ->
    @scene.add new THREE.AmbientLight(0x505050)
    light = new THREE.PointLight(0x505050, 3, 2000)
    light.x = -150
    light.y = 0
    light.z = 36
    DEBUG.expose('light', light)
    @scene.add light

  render: (delta) ->
    @person.update(delta)
    if @mouse
      vector = new THREE.Vector3(@mouse.x, @mouse.y, .5)
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
