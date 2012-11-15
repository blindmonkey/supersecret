
Renderer = p.require('Renderer')
FirstPerson = p.require('FirstPerson')

class Game
  constructor: (container, width, height) ->
    @renderer = new Renderer(container, width, height)
    @scene = new THREE.Scene();
    @camera = @initCamera(width, height)
    @initGeometry()
    @initLights()
    @person = new FirstPerson(container, @camera)

    @person.rotation = 3.288
    @person.pitch = .5986
    @person.updateCamera()

  initCamera: (width, height) ->
    VIEW_ANGLE = 45
    ASPECT = width / height
    NEAR = 0.1
    FAR = 10000

    camera = new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
    DEBUG.expose('camera', camera)

    @scene.add camera

    camera.position.z = 46
    camera.position.x = 485
    camera.position.y = 235
    return camera

  initGeometry: ->
    sphereMaterial = new THREE.MeshLambertMaterial({
    #sphereMaterial = new THREE.LineBasicMaterial({
      color: 0x00CC00
    })
    geometry = new THREE.Geometry();
    width = 101
    length = 101
    getVertexIndex = (x, z) -> (z - 1) + (x - 1) * width
    count = 0
    noise = new SimplexNoise()
    for xx in [1..width]
      for zz in [1..length]
        x = (xx - 1) - Math.floor(width / 2)
        z = (zz - 1) - Math.floor(length / 2)
        x *= 5
        z *= 5

        y = 0
        #y = noise1.noise2D(x, z)
        y += noise.noise2D(x / 128, z / 128) * 2
        y += noise.noise2D(x / 64, z / 64)
        y += noise.noise2D(x / 32, z / 32) / 2
        y += noise.noise2D(x / 16, z / 16) / 4
        #y += noise2.noise2D(x / 25, z / 25) / 2
        #y += noise.noise2D(x / 4, z / 4) / 4
        #console.log(++count, x, z, getVertexIndex(x, z))
        geometry.vertices.push(new THREE.Vector3(x, y * 10, z))
        if xx > 1 and zz > 1
          geometry.faces.push(new THREE.Face3(getVertexIndex(xx - 1, zz - 1), getVertexIndex(xx, zz), getVertexIndex(xx, zz - 1)))
          geometry.faces.push(new THREE.Face3(getVertexIndex(xx, zz), getVertexIndex(xx - 1, zz - 1), getVertexIndex(xx - 1, zz)))
    geometry.computeFaceNormals()
    mesh = new THREE.Mesh(geometry, sphereMaterial)
    DEBUG.expose('mesh', mesh)
    #mesh.position.x = 0
    #mesh.position.y = 0
    #mesh.position.z = 0
    @scene.add(mesh)

  initLights: ->
    pointLight = new THREE.PointLight(0xFFFFFF, 1, 20)
    DEBUG.expose('pointLight', pointLight)

    pointLight.position.x = 10
    pointLight.position.y = 1000
    pointLight.position.z = 0
    pointLight.distance = 2000

    @scene.add(pointLight)

  start: ->
    @renderer.start @render.bind(this)

  render: (delta) ->
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)

p.provide('Game', Game)
