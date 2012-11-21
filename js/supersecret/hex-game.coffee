Renderer = p.require('Renderer')
FirstPerson = p.require('FirstPerson')
BaseGame = p.require('BaseGame')

class HexGame extends BaseGame
  constructor: (container, width, height, opt_scene, opt_camera) ->
    super(container, width, height, opt_scene, opt_camera)

    DEBUG.expose('scene', @scene)

    @person = new FirstPerson(container, @camera)
    @person.updateCamera()

  initGeometry: ->
    #@scene.add new THREE.Mesh(new THREE.SphereGeometry(1, 8, 8), new THREE.LineBasicMaterial({color: 0xff0000}))
    @terrain = []
    HEIGHT = 120
    WIDTH = 40

    noise = new SimplexNoise()

    TILE_SIZE = 2

    spacingZ = TILE_SIZE + Math.cos(2 * Math.PI / 6) - Math.cos(2 * Math.PI / 6 * 2)
    spacingX = (TILE_SIZE * Math.cos(Math.PI / 6) / 2)
    TOTAL_WIDTH = TILE_SIZE / 2 * spacingZ * WIDTH
    TOTAL_HEIGHT = TILE_SIZE / 2 * spacingX * HEIGHT
    console.log(TOTAL_WIDTH, TOTAL_HEIGHT)

    geometry = new THREE.Geometry()
    for x in [0..HEIGHT]
      width = WIDTH - (if z % 2 then 1 else 0)
      offset = if z % 2 then spacingZ / 2 else 0
      for z in [0..width]
        zPosition = z * spacingZ + offset - TOTAL_WIDTH / 2
        xPosition = x * spacingX - TOTAL_HEIGHT / 2
        baseVectors = []
        vectors = []
        rstep = Math.PI * 2 / 6
        for r in [0..Math.PI * 2 - rstep] by rstep
          vectors.push new THREE.Vector3(
            xPosition + Math.sin(r) * TILE_SIZE / 2,
            (noise.noise2D(xPosition / 20, zPosition / 20) + 1) * 5,
            zPosition + Math.cos(r) * TILE_SIZE / 2)
          baseVectors.push new THREE.Vector3(
            xPosition + Math.sin(r) * TILE_SIZE / 2,
            0,
            zPosition + Math.cos(r) * TILE_SIZE / 2)
        #v1 = new THREE.Vector3(xPosition + Math.sin(2 * Math.PI / 6) , 0, zPosition + Math.cos(2 * Math.PI / 6) * TILE_SIZE / 2)
        #mesh = new THREE.Mesh(
        #  new THREE.SphereGeometry(.2, 8, 8),
        #  new THREE.LineBasicMaterial({color: 0xff0000}))
        #mesh.position.z = zPosition
        #mesh.position.x = xPosition
        #@scene.add mesh



        for v in baseVectors
          geometry.vertices.push v
        for v in vectors
          geometry.vertices.push v

        l = geometry.vertices.length
        geometry.faces.push new THREE.Face3(l-6, l-5, l-4)
        geometry.faces.push new THREE.Face3(l-6, l-4, l-3)
        geometry.faces.push new THREE.Face3(l-6, l-3, l-2)
        geometry.faces.push new THREE.Face3(l-6, l-2, l-1)

        geometry.faces.push new THREE.Face3(l-6, l-12, l-11)
        geometry.faces.push new THREE.Face3(l-5, l-6, l-11)

        geometry.faces.push new THREE.Face3(l-5, l-11, l-10)
        geometry.faces.push new THREE.Face3(l-4, l-5, l-10)

        geometry.faces.push new THREE.Face3(l-4, l-10, l-9)
        geometry.faces.push new THREE.Face3(l-3, l-4, l-9)

        geometry.faces.push new THREE.Face3(l-3, l-9, l-8)
        geometry.faces.push new THREE.Face3(l-2, l-3, l-8)

        geometry.faces.push new THREE.Face3(l-2, l-8, l-7)
        geometry.faces.push new THREE.Face3(l-1, l-2, l-7)

        geometry.faces.push new THREE.Face3(l-1, l-7, l-12)
        geometry.faces.push new THREE.Face3(l-6, l-1, l-12)

    geometry.computeFaceNormals()
    materials = [
      new THREE.LineBasicMaterial({color: 0x0000ff}),
      new THREE.MeshPhongMaterial({color: 0x0000ff, ambient: 0x0000aa})
    ]
    materialIndex = 1
    mesh = new THREE.Mesh(geometry, materials[materialIndex])
    @scene.add mesh
    DEBUG.expose('nextMaterial', ->
      materialIndex++
      materialIndex %= materials.length
      mesh.material = materials[materialIndex]
    )

  initLights: ->
    @scene.add new THREE.AmbientLight(0x505050, 1, 50)
    light = new THREE.PointLight(0xffffff, 1, 50)
    light.position.x = 0
    light.position.z = 0
    light.position.y = 10
    #@scene.add light
    DEBUG.expose('light', light)

    @dlightRotation = 0
    dlight = new THREE.DirectionalLight(0xff0000, 50, 500)
    dlight.position.x = @camera.position.x
    dlight.position.y = @camera.position.y
    dlight.position.z = @camera.position.z
    #dlight.lookAt(new THREE.Vector3(@camera.position.x, @camera.position.y, @camera.position.z))
    @dlight = dlight
    dlight.shadowCameraVisible = true
    @scene.add dlight
    DEBUG.expose('dlight', dlight)


  render: (delta) ->
    @dlightRotation += .01
    @dlightRotation %= 2 * Math.PI
    @dlight.position.x = Math.cos(@dlightRotation) * 10
    @dlight.position.z = Math.sin(@dlightRotation) * 10
    @dlight.position.y = 20
    @dlight.lookAt(new THREE.Vector3(0, 0, 0))

    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)

p.provide('HexGame', HexGame)
