lib.load(
  'facemanager'
  'firstperson'
  'noisegenerator'
  'now'
  'polygons'
  -> supersecret.Game.loaded = true)

supersecret.Game = class PlanetGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    # @person = new FirstPerson(container, @camera)

    @camera.position.x = -50
    @camera.position.y = 0
    @camera.position.z = 0
    @rotation = 0
    @pitch = 0
    @rotationalMomentum = 0

    lastMouse = null
    dragging = false
    $(@container).mousedown(((e) ->
      dragging = true
      lastMouse = [e.clientX, e.clientY]
      ).bind(this))
    $(@container).mouseup(((e) ->
      dragging = false
      lastMouse = null
      ).bind(this))
    $(@container).mousemove(((e) ->
      if dragging
        [lx, ly] = lastMouse
        @rotationalMomentum = (e.clientX - lx) / 50
        @pitch += (e.clientY - ly) / 50
        lastMouse = [e.clientX, e.clientY]
      ).bind(this))
    @doRotate = true

    @distance = 200

    @placeCamera()

  placeCamera: ->
    @camera.position.x = Math.cos(@rotation) * @distance
    @camera.position.z = Math.sin(@rotation) * @distance
    @camera.position.y = Math.sin(@pitch) * @distance
    @camera.lookAt(new THREE.Vector3(0, 0, 0))

  initGeometry: ->
    # @scene.add new THREE.Mesh(
    #   new THREE.SphereGeometry(1, 16, 16),
    #   new THREE.LineBasicMaterial({color: 0xff0000})
    #   )

    distance = (x, y, z) ->
      return Math.sqrt(x*x + y*y + z*z)
    resize = (nd, x, y, z) ->
      d = distance(x, y, z)
      return [
        x / d * nd
        y / d * nd
        z / d * nd
      ]

    noise = new NoiseGenerator(new SimplexNoise(), [{
      scale: .65
    }, {
      scale: 2
      multiplier: .7
    }, {
      scale: 3
      multiplier: .6
    }, {
      scale: 5
      multiplier: .5
    }, {
      scale: 8
      multiplier: .35
    }, {
      scale: 12
      multiplier: .3
    }, {
      scale: 16
      multiplier: .25
    }, {
      scale: 20
      multiplier: .2
    }, {
      scale: 24
      multiplier: .15
    }])
    sphereRadius = 50
    t1 = now()

    updater = new Updater(1000)
    geometry = polygons.cube(sphereRadius)
    attrmap = ['a', 'b', 'c']
    moved = new Set()
    #faces = new FaceManager(geometry.faces.length+1)
    faces = FaceManager.fromGeometry(geometry)

    fixVertex = (x, y, z) ->
      n = noise.noise3D(x, y, z)
      color = null
      if n < 0
        n = 0
        color = new THREE.Color(0x0000ff)
      else if n > .9
        color = new THREE.Color(0xffffff)
      else
        color = new THREE.Color(0x00ff00)
      r = (n/32 + 1) * sphereRadius
      return [[
        x * r
        y * r
        z * r
      ], color]

    mesh = null
    updateGeometry = =>
      # console.log ('updating geometry')
      geometry = faces.generateGeometry()
      # console.log("Planet generated in #{now() - t1}")
      # console.log("Planet generated with #{geometry.vertices.length} vertices and #{geometry.faces.length} faces")
      geometry.computeFaceNormals()
      geometry.verticesNeedUpdate = true
      geometry.facesNeedUpdate = true
      geometry.colorsNeedUpdate = true
      geometry.normalsNeedUpdate = true

      if mesh is null or mesh.geometry != geometry
        @scene.remove mesh if mesh
        mesh = new THREE.Mesh(
          geometry
          new THREE.MeshLambertMaterial({vertexColors: THREE.VertexColors})
          # new THREE.LineBasicMaterial({color: 0xff0000})
          )
        @scene.add mesh

    queue = []

    updateFace = (face) ->
      moreFaces = polygons.complexifyFace(face, 1)
      faces.removeFaces face
      for face in moreFaces
        newFace = []
        newColors = []
        for vi in [0..2]
          v = face[vi]
          [v, color] = fixVertex(v...)
          newFace.push v
          newColors.push color
        queue.push faces.addFace(newFace..., {vertexColors: newColors})

    updater = new Updater(1500)
    @runUpdater = ->
      # console.log('UPDATER!')
      t1 = now()
      if queue.length == 0
        console.log('Updating queue!')
        faces.forEachFace((face) ->
          queue.push face
        )
      while queue.length > 0 and now() - t1 < 500
        face = queue.shift()
        updateFace(face)

      updater.update('geometry-update', updateGeometry)


    @runUpdater()
    @doUpdate = true

    $(document).keydown((e) =>
      if e.keyCode == 85
        @runUpdater()
      else if e.keyCode == 73
        @doUpdate = not @doUpdate
      )

  initLights: ->
    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.y = Math.random()
    light.position.x = Math.random()
    light.position.z = Math.random()
    @scene.add light

    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.y = Math.random()
    light.position.x = -Math.random()
    light.position.z = -Math.random()
    @scene.add light
    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.y = -Math.random()
    light.position.x = Math.random()
    light.position.z = Math.random()
    @scene.add light



  update: (delta) ->
    @runUpdater() if @doUpdate
    @rotationalMomentum *= .9
    @rotation += @rotationalMomentum
    if @doRotate
      @rotation += .01
      @placeCamera()
    # @person.update(delta)
