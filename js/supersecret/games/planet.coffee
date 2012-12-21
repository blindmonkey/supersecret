lib.load(
  'facemanager'
  'firstperson'
  'noisegenerator'
  'now'
  'polygons'
  -> supersecret.Game.loaded = true)

class Sun
  constructor: (scene) ->
    @light = new THREE.DirectionalLight(0xffffff, 0.4)
    @light.position.y = 0
    @light.position.x = 1
    @light.position.z = 1
    @rotation = 0
    @rotationSpeed = Math.PI / 16 / 1000
    scene.add @light
    @sunSphere = new THREE.Mesh(
      new THREE.SphereGeometry(1, 8, 8)
      new THREE.MeshLambertMaterial({color: 0xffff00})
    )
    scene.add @sunSphere

  update: (delta) ->
    @rotation -= @rotationSpeed * delta
    while @rotation < 0
      @rotation += 2 * Math.PI
    cos = Math.cos(@rotation)
    sin = Math.sin(@rotation)
    @light.position.x = cos
    @light.position.z = sin
    @sunSphere.position.x = cos * 100
    @sunSphere.position.z = sin * 100


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
        @rotationalMomentum = (e.clientX - lx) # / 50
        @pitch += (e.clientY - ly) / 50
        lastMouse = [e.clientX, e.clientY]
      ).bind(this))
    @doRotate = true

    @distance = 200
    $(@container).bind('mousewheel', ((e, delta) ->
      delta = e.originalEvent.wheelDeltaY
      @distance += delta / 120
      @placeCamera()
    ).bind(this))

    @placeCamera()

  placeCamera: ->
    r = Math.cos(@pitch) * @distance
    @camera.position.x = Math.cos(@rotation) * r
    @camera.position.z = Math.sin(@rotation) * r
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
      multiplier: .18
    }, {
      scale: 30
      multiplier: .14
    }, {
      scale: 40
      multiplier: .13
    }, {
      scale: 50
      multiplier: .12
    }, {
      scale: 75
      multiplier: .11
    }, {
      scale: 80
      multiplier: .10
    }])
    sphereRadius = 50
    t1 = now()

    updater = new Updater(1000)
    geometry = null
    attrmap = ['a', 'b', 'c']
    moved = new Set()
    #faces = new FaceManager(geometry.faces.length+1)
    faces = null
    queue = []
    (generateInitialGeometry = ->
      geometry = polygons.cube(sphereRadius)
      faces = FaceManager.fromGeometry(geometry)
      queue = []
    )()

    fixVertex = (x, y, z) ->
      n = noise.noise3D(x, y, z)
      color = null
      if n < 0
        n = 0
        color = new THREE.Color(0x0000ff)
      else if n > 1.1
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
      console.log ('updating geometry')
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

    queuePush = (face, generation) ->
      queue.push face, generation

    queuePop = ->
      return queue.shift()

    updateFace = (face, generation) ->
      moreFaces = polygons.complexifyFace(face, 1)
      faces.removeFaces face
      n = 0
      for face in moreFaces
        newFace = []
        newColors = []
        for vi in [0..2]
          v = face[vi]
          [v, color] = fixVertex(v...)
          newFace.push v
          newColors.push color
        queuePush faces.addFace(newFace..., {vertexColors: newColors}), generation+1

    updater = new Updater(1500)
    # faceUpdateTime = 50
    @setTransform('time', parseInt)
    @watch 'freq', (v) ->
      updater.setFrequency('geometry-update', v)
    @watched.faces = @watched.faces or 2

    faceAverage = (face) ->
      xs = 0
      ys = 0
      zs = 0
      for [x,y,z] in [face.a, face.b, face.c]
        xs+=x
        ys+=y
        zs+=z
      return [xs / 3, ys / 3, zs / 3]

    projector = new THREE.Projector()

    faceTest = false
    @runUpdater = =>
      originVector = projector.projectVector(new THREE.Vector3(0,0,0), @camera)
      # console.log('UPDATER!')
      t1 = now()
      if queue.length == 0
        console.log('Updating queue!')
        i = 0
        faces.forEachFace((face) =>
          if i < (@watched.faces)
            queue.push face
            i++
        )
      updatedFaces = 0
      skippedFaces = 0
      while queue.length > 0 and now() - t1 < @watched.time
        [face, generation] = queuePop()
        shouldUpdateFace = not faceTest
        if faceTest
          vf = (projector.projectVector(new THREE.Vector3(p...), @camera) for p in [face.a, face.b, face.c])
          for v in vf
            if -1 < v.x < 1 and -1 < v.y < 1 and v.z < originVector.z
              shouldUpdateFace = true
              break

        if shouldUpdateFace
          updateFace face, generation
          updatedFaces++
        else
          queuePush face, generation
          skippedFaces++
      updater.update('geometry-stats', "The geometry currently consists of #{queue.length} faces. Last cycle, #{updatedFaces} faces were updated and #{skippedFaces} were skipped")
      updater.update('geometry-update', updateGeometry)

    updateGeometry()
    #@runUpdater()
    @doUpdate = false
    @sunRotate = true

    $(document).keydown((e) =>
      console.log(e.keyCode)
      if e.keyCode == 85 # U
        @runUpdater.bind(this)()
      else if e.keyCode == 84 # T
        faceTest = not faceTest
      else if e.keyCode == 65 # A
        generateInitialGeometry()
      else if e.keyCode == 83 # S
        @sunRotate = not @sunRotate
      else if e.keyCode == 82 # R
        @doRotate = not @doRotate
      else if e.keyCode == 73 # I
        @doUpdate = not @doUpdate
        if @doUpdate
          console.log('update enabled')
        else
          console.log('update disabled')
      )

  initLights: ->
    @scene.add new THREE.AmbientLight(0x303030)
    @sun = new Sun(@scene)

    # light = new THREE.DirectionalLight(0xffffff, .6)
    # light.position.y = Math.random()
    # light.position.x = -Math.random()
    # light.position.z = -Math.random()
    # @scene.add light
    # light = new THREE.DirectionalLight(0xffffff, .6)
    # light.position.y = -Math.random()
    # light.position.x = Math.random()
    # light.position.z = Math.random()
    # @scene.add light



  update: (delta) ->
    if not @lastRotation
      @lastRotation = null
    @runUpdater() if @doUpdate
    @rotationalMomentum *= .9
    @rotation += @rotationalMomentum * delta / 1000
    if @doRotate
      @rotationalMomentum += .1
    if @lastRotation != @rotation
      @lastRotation = @rotation
      @placeCamera()
    if @sunRotate
      @sun.update(delta)
    # @person.update(delta)
