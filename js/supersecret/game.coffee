
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

  initCamera: (width, height) ->
    VIEW_ANGLE = 45
    ASPECT = width / height
    NEAR = 0.1
    FAR = 10000

    camera = new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
    DEBUG.expose('camera', camera)

    @scene.add camera

    camera.position.z = 300
    camera.position.y = 100
    return camera

  initGeometry: ->
    sphereMaterial = new THREE.MeshLambertMaterial({
    #sphereMaterial = new THREE.LineBasicMaterial({
      color: 0xCC0000
    })
    geometry = new THREE.Geometry();
    width = 11
    length = 11
    getVertexIndex = (x, z) -> (z - 1) + (x - 1) * width
    count = 0
    for xx in [1..width]
      for zz in [1..length]
        x = (xx - 1) - Math.floor(width / 2)
        z = (zz - 1) - Math.floor(length / 2)
        console.log(x, z)
        x *= 50
        z *= 50
        console.log(x, z)
        #console.log(++count, x, z, getVertexIndex(x, z))
        geometry.vertices.push(new THREE.Vector3(x, 0, z))
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
    pointLight = new THREE.PointLight(0xFFFFFF, 100, 200)
    DEBUG.expose('pointLight', pointLight)

    pointLight.position.x = 10
    pointLight.position.y = 10
    pointLight.position.z = 0

    @scene.add(pointLight)

  start: ->
    @renderer.start @render.bind(this)

  render: (delta) ->
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)

p.provide('Game', Game)
