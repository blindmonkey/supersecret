lib.load('maze', 'facemanager', ->
  Amaze.loaded = true)

supersecret.Game = class Amaze extends supersecret.BaseGame
  @loaded: false
  constructor: (container, width, height, opt_scene, opt_camera) ->
    @maze = new MazeGenerator(20, 20)

    super(container, width, height, opt_scene, opt_camera)

    @person = new supersecret.FirstPerson(container, @camera)

  initGeometry: ->
    @scene.add new THREE.Mesh(new THREE.SphereGeometry(1, 8, 8), new THREE.LineBasicMaterial({color: 0xff0000}))

    geometry = new THREE.Geometry()
    for x in [0..@maze.size.width - 1]
      for y in [0..@maze.size.height - 1]
        if x == 0 or @maze.graph.connected([x, y], [x - 1, y])
          geometry.vertices.push new THREE.Vector3(x, 0, y)
          geometry.vertices.push new THREE.Vector3(x, 0, y + 1)
        if x == @maze.size.width - 1
          geometry.vertices.push new THREE.Vector3(x + 1, 0, y)
          geometry.vertices.push new THREE.Vector3(x + 1, 0, y + 1)
        if y == 0 or @maze.graph.connected([x, y], [x, y - 1])
          geometry.vertices.push new THREE.Vector3(x, 0, y)
          geometry.vertices.push new THREE.Vector3(x + 1, 0, y)
        if y == @maze.size.height - 1
          geometry.vertices.push new THREE.Vector3(x, 0, y + 1)
          geometry.vertices.push new THREE.Vector3(x + 1, 0, y + 1)
    @scene.add new THREE.Line(geometry, new THREE.LineBasicMaterial({color: 0x00ff00}), THREE.LinePieces)
    return



    faceManager = new FaceManager()
    for x in [0..@maze.size.width - 1]
      for y in [0..@maze.size.height - 1]
        faceManager.addFace(
          new THREE.Vector3(x, 0, y),
          new THREE.Vector3(x, 0, y + 1),
          new THREE.Vector3(x + 1, 0, y)
          )
        faceManager.addFace(
          new THREE.Vector3(x + 1, 0, y),
          new THREE.Vector3(x, 0, y + 1),
          new THREE.Vector3(x + 1, 0, y + 1)
          )
        if x == 0 or @maze.graph.connected([x, y], [x - 1, y])
          faceManager.addFace(
            new THREE.Vector3(x, 0, y),
            new THREE.Vector3(x, 0, y + 1),
            new THREE.Vector3(x, 1, y + 1), true
            )
          faceManager.addFace(
            new THREE.Vector3(x, 0, y),
            new THREE.Vector3(x, 1, y + 1),
            new THREE.Vector3(x, 1, y), true
            )
        if x == @maze.size.width - 1 #or @maze.graph.connected([x, y], [x + 1, y])
          faceManager.addFace(
            new THREE.Vector3(x + 1, 0, y),
            new THREE.Vector3(x + 1, 0, y + 1),
            new THREE.Vector3(x + 1, 1, y + 1), true
            )
          faceManager.addFace(
            new THREE.Vector3(x + 1, 0, y),
            new THREE.Vector3(x + 1, 1, y + 1),
            new THREE.Vector3(x + 1, 1, y), true
            )
        if y == 0 or @maze.graph.connected([x, y], [x, y - 1])
          faceManager.addFace(
            new THREE.Vector3(x, 0, y),
            new THREE.Vector3(x + 1, 0, y),
            new THREE.Vector3(x + 1, 1, y), true
            )
          faceManager.addFace(
            new THREE.Vector3(x, 0, y),
            new THREE.Vector3(x + 1, 1, y),
            new THREE.Vector3(x, 1, y), true
            )
        if y == @maze.size.height - 1 #or @maze.graph.connected([x, y], [x + 1, y])
          faceManager.addFace(
            new THREE.Vector3(x, 0, y + 1),
            new THREE.Vector3(x + 1, 0, y + 1),
            new THREE.Vector3(x + 1, 1, y + 1), true
            )
          faceManager.addFace(
            new THREE.Vector3(x, 0, y + 1),
            new THREE.Vector3(x + 1, 1, y + 1),
            new THREE.Vector3(x, 1, y + 1), true
            )
    geometry = faceManager.generateGeometry()
    geometry.computeFaceNormals()
    @scene.add new THREE.Mesh(geometry,
      new THREE.MeshPhongMaterial({color: 0x00ff00}))
      #new THREE.LineBasicMaterial({color: 0x00ff00}))


  initLights: ->
    console.log('initializing lights!')
    #@scene.add new THREE.AmbientLight(0xffffff)
    light = new THREE.PointLight(0xffffff, .9, 100)
    light.position.x = 0
    light.position.y = 10
    light.position.z = 0
    DEBUG.expose('light', light)
    @scene.add light

    dlight = new THREE.DirectionalLight(0xffffff, .6)
    dlight.position.set(1, 1, 1)
    @scene.add dlight
    dlight = new THREE.DirectionalLight(0xffffff, .6)
    dlight.position.set(-1, 1, -1)
    @scene.add dlight

  render: (delta) ->
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)
