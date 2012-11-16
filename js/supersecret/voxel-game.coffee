Renderer = p.require('Renderer')
FirstPerson = p.require('FirstPerson')
BaseGame = p.require('BaseGame')

getIndex = (position, size) ->
  return position.x + position.y * size.x + position.z * size.x * size.y

class Chunk
  constructor: (size) ->
    @data = []
    @size = size
    for x in [1..size.x]
      for y in [1..size.y]
        for z in [1..size.z]
          @data.push(null)

  set: (position, value) ->
    i = getIndex(position, @size)
    @data[i] = value

  get: (position) ->
    i = getIndex(position, @size)
    return @data[i]


class VoxelGame extends BaseGame
  constructor: (container, width, height, opt_scene, opt_camera) ->
    @chunk = new Chunk({
      x: 64
      y: 64
      z: 64
    })
    @cubeSize = 16

    super(container, width, height, opt_scene, opt_camera)

    @camera.position.x = 0
    @camera.position.y = 1
    @camera.position.z = 0

    @person = new FirstPerson(container, @camera)

  initGeometry: ->
    geometry = new THREE.Geometry()
    verticesSize =
      x: @chunk.size.x + 1
      y: @chunk.size.y + 1
      z: @chunk.size.z + 1
    for z in [0..@chunk.size.z]
      for y in [0..@chunk.size.y]
        for x in [0..@chunk.size.x]
          geometry.vertices.push(new THREE.Vector3(x * @chunk.cubeSize, y * @chunk.cubeSize, z * @chunk.cubeSize))
          if x > 0 and y > 0 and z > 0
            voxel = @chunk.get({x:x,y:y,z:z})
            px = x - 1
            py = y - 1
            pz = z - 1
            topFace1 = new THREE.Face3(
              getIndex({x:px,y:y,z:z}, verticesSize),
              getIndex({x:x,y:py,z:z}, verticesSize),
              getIndex({x:x,y:y,z:z}, verticesSize))
            geometry.faces.push(topFace1)
    material = new THREE.LineBasicMaterial({color: 0xff0000})
    mesh = new THREE.Mesh(geometry, material)
    @scene.add(mesh)
    @scene.add(new THREE.Mesh(
      new THREE.SphereGeometry(10, 16, 16),
      new THREE.LineBasicMaterial({color: 0xff0000})))

  render: (delta) ->
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)


p.provide('VoxelGame', VoxelGame)