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
    @scene.add new THREE.Mesh(
      new THREE.SphereGeometry(1, 8, 8),
      new THREE.LineBasicMaterial({color: 0xff0000})
    )
    makeRandomColor = ->
      r = Math.floor(Math.random() * 256)
      g = Math.floor(Math.random() * 256)
      b = Math.floor(Math.random() * 256)
      return new THREE.Color((r << 16) + (g << 8) + b)
    makeRandomColors = ->
      (makeRandomColor() for c in [0..2])

    faces = new FaceManager(200)
    m = 100
    faces.addFace([0, 0, 0], [m, 0, 0], [m, 0, -m], {vertexColors: makeRandomColors()})
    faces.addFace([0, 0, 0], [m, 0, -m], [0, 0, -m], {vertexColors: makeRandomColors()})
    faces.addFace([0, 0, 0], [0, 0, -m], [-m, 0, -m], {vertexColors: makeRandomColors()})
    faces.addFace([0, 0, 0], [-m, 0, -m], [-m, 0, 0], {vertexColors: makeRandomColors()})
    faces.addFace([0, 0, 0], [-m, 0, 0], [-m, 0, m], {vertexColors: makeRandomColors()})
    faces.addFace([0, 0, 0], [-m, 0, m], [0, 0, m], {vertexColors: makeRandomColors()})
    faces.addFace([0, 0, 0], [0, 0, m], [m, 0, m], {vertexColors: makeRandomColors()})
    faces.addFace([0, 0, 0], [m, 0, m], [m, 0, 0], {vertexColors: makeRandomColors()})
    console.log(faces.faces)

    geometry = faces.generateGeometry()
    geometry.computeVertexNormals()
    mesh = new THREE.Mesh(
      geometry,
      new THREE.LineBasicMaterial({vertexColors: THREE.VertexColors}))
    @scene.add mesh

  render: (delta) ->
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)

