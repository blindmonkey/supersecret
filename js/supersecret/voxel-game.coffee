Renderer = p.require('Renderer')
FirstPerson = p.require('FirstPerson')
BaseGame = p.require('BaseGame')

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


class VoxelGame extends BaseGame
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
    @chunk = new Chunk({
      x: 128
      y: 128
      z: 128
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

    @person = new FirstPerson(container, @camera)
    @person.updateCamera()


  initGeometry: ->
    console.log(@chunk.get({x:1, y:1, z:1}))
    console.log("Generating geometry")
    geometry = new THREE.Geometry()
    verticesSize =
      x: @chunk.size.x + 1
      y: @chunk.size.y + 1
      z: @chunk.size.z + 1
    updater = new Updater(5000)
    for z in [0..@chunk.size.z]
      for y in [0..@chunk.size.y]
        for x in [0..@chunk.size.x]
          updater.update('Current coord: ' + x + ', ' + y + ', ' + z)
          geometry.vertices.push(new THREE.Vector3(x * @cubeSize, y * @cubeSize, z * @cubeSize))
          if x > 0 and y > 0 and z > 0
            voxel = @chunk.get({x:x-1,y:y-1,z:z-1})
            if x == 2 and y == 2 and z == 2
              console.log(voxel, {x:x-1,y:y-1,z:z-1})
            continue if not voxel
            aboveVoxel = @chunk.get({x:x-1,y:y,z:z-1})
            belowVoxel = @chunk.get({x:x-1,y:y-2,z:z-1})
            leftVoxel = @chunk.get({x:x-2,y:y-1,z:z-1})
            rightVoxel = @chunk.get({x:x,y:y-1,z:z-1})
            backVoxel = @chunk.get({x:x-1,y:y-1,z:z-2})
            frontVoxel = @chunk.get({x:x-1,y:y-1,z:z})
            px = x - 1
            py = y - 1
            pz = z - 1
            previousFacesLength = geometry.faces.length

            if not aboveVoxel
              geometry.faces.push.apply(geometry.faces, [
                new THREE.Face3(
                  getIndex({x:px,y:y,z:z}, verticesSize),
                  getIndex({x:x,y:y,z:z}, verticesSize),
                  getIndex({x:x,y:y,z:pz}, verticesSize)),
                new THREE.Face3(
                  getIndex({x:px,y:y,z:z}, verticesSize),
                  getIndex({x:x,y:y,z:pz}, verticesSize),
                  getIndex({x:px,y:y,z:pz}, verticesSize))])

            if not belowVoxel
              geometry.faces.push.apply(geometry.faces, [
                new THREE.Face3(
                  getIndex({x:px,y:py,z:z}, verticesSize),
                  getIndex({x:x,y:py,z:pz}, verticesSize),
                  getIndex({x:x,y:py,z:z}, verticesSize)),
                new THREE.Face3(
                  getIndex({x:px,y:py,z:z}, verticesSize),
                  getIndex({x:px,y:py,z:pz}, verticesSize),
                  getIndex({x:x,y:py,z:pz}, verticesSize))])

            if not leftVoxel
              geometry.faces.push.apply(geometry.faces, [
                new THREE.Face3(
                  getIndex({x:px,y:y,z:z}, verticesSize),
                  getIndex({x:px,y:y,z:pz}, verticesSize),
                  getIndex({x:px,y:py,z:z}, verticesSize)),
                new THREE.Face3(
                  getIndex({x:px,y:py,z:z}, verticesSize),
                  getIndex({x:px,y:y,z:pz}, verticesSize),
                  getIndex({x:px,y:py,z:pz}, verticesSize))])

            if not rightVoxel
              geometry.faces.push.apply(geometry.faces, [
                new THREE.Face3(
                  getIndex({x:x,y:y,z:z}, verticesSize),
                  getIndex({x:x,y:py,z:z}, verticesSize),
                  getIndex({x:x,y:y,z:pz}, verticesSize)),
                new THREE.Face3(
                  getIndex({x:x,y:py,z:z}, verticesSize),
                  getIndex({x:x,y:py,z:pz}, verticesSize),
                  getIndex({x:x,y:y,z:pz}, verticesSize))])

            if not backVoxel
              geometry.faces.push.apply(geometry.faces, [
                new THREE.Face3(
                  getIndex({x:px,y:y,z:pz}, verticesSize),
                  getIndex({x:x,y:y,z:pz}, verticesSize),
                  getIndex({x:x,y:py,z:pz}, verticesSize)),
                new THREE.Face3(
                  getIndex({x:px,y:y,z:pz}, verticesSize),
                  getIndex({x:x,y:py,z:pz}, verticesSize),
                  getIndex({x:px,y:py,z:pz}, verticesSize))])

            if not frontVoxel
              geometry.faces.push.apply(geometry.faces, [
                new THREE.Face3(
                  getIndex({x:px,y:y,z:z}, verticesSize),
                  getIndex({x:x,y:py,z:z}, verticesSize),
                  getIndex({x:x,y:y,z:z}, verticesSize)),
                new THREE.Face3(
                  getIndex({x:px,y:y,z:z}, verticesSize),
                  getIndex({x:px,y:py,z:z}, verticesSize),
                  getIndex({x:x,y:py,z:z}, verticesSize))])
    console.log("Geometry generated. Computing face normals for " + geometry.faces.length + " faces")
    geometry.computeFaceNormals()
    console.log('done')
    #material = new THREE.LineBasicMaterial({color: 0xff0000})
    material = new THREE.MeshPhongMaterial({color: 0xff0000})
    mesh = new THREE.Mesh(geometry, material)
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
    @renderer.renderer.render(@scene, @camera)


p.provide('VoxelGame', VoxelGame)
