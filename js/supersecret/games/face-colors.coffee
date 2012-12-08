lib.load(
  'facemanager',
  'firstperson',
  -> supersecret.Game.loaded = true)

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false
  constructor: (container, width, height, opt_scene, opt_camera) ->
    params = getQueryParams()
    @viewAngle = parseFloat(params.viewAngle) or 90

    super(container, width, height, opt_scene, opt_camera)

    @camera.position.x = 1
    @camera.position.y = 1
    @camera.position.z = 0
    @person = new FirstPerson(container, @camera)
    @person.updateCamera()


  initGeometry: ->
    # @scene.add new THREE.Mesh(
    #   new THREE.SphereGeometry(1, 8, 8),
    #   new THREE.LineBasicMaterial({color: 0xff0000})
    # )

    faces = new FaceManager(200)
    m = 100
    faces.addFace([0, 0, 0], [m, 0, 0], [m, 0, -m], {color: new THREE.Color(0xff0000)})
    faces.addFace([0, 0, 0], [m, 0, -m], [0, 0, -m], {color: new THREE.Color(0xff00ff)})
    faces.addFace([0, 0, 0], [0, 0, -m], [-m, 0, -m], {color: new THREE.Color(0x0000ff)})
    faces.addFace([0, 0, 0], [-m, 0, -m], [-m, 0, 0], {color: new THREE.Color(0x00ffff)})
    faces.addFace([0, 0, 0], [-m, 0, 0], [-m, 0, m], {color: new THREE.Color(0x00ff00)})
    faces.addFace([0, 0, 0], [-m, 0, m], [0, 0, m], {color: new THREE.Color(0xffff00)})
    faces.addFace([0, 0, 0], [0, 0, m], [m, 0, m], {color: new THREE.Color(0xffff00)})
    faces.addFace([0, 0, 0], [m, 0, m], [m, 0, 0], {color: new THREE.Color(0xffff00)})

    geometry = faces.generateGeometry()
    geometry.computeVertexNormals()
    mesh = new THREE.Mesh(
      geometry,
      new THREE.LineBasicMaterial({vertexColors: THREE.FaceColors}))
    @scene.add mesh

  render: (delta) ->
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)

