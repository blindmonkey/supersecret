lib.load(
  'facemanager'
  'firstperson'
  'noisegenerator'
  'now'
  -> supersecret.Game.loaded = true)

supersecret.Game = class PlanetGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)

  initGeometry: ->
    # @scene.add new THREE.Mesh(
    #   new THREE.SphereGeometry(1, 16, 16),
    #   new THREE.LineBasicMaterial({color: 0xff0000})
    #   )

    latFromIndex = (index, pieces) ->
      return 0 if pieces == 0
      index / pieces * Math.PI #- Math.PI / 2

    lngFromIndex = (index, pieces) ->
      return 0 if pieces == 0
      index / pieces * Math.PI * 2

    forEachLat = (pieces, f) ->
      for index in [0..pieces]
        f(index, latFromIndex(index, pieces))

    forEachLng = (lat, pieces, f) ->
      r = Math.sin(lat)
      y = Math.cos(lat)
      for index in [0..pieces]
        lng = lngFromIndex(index, pieces)
        x = Math.cos(lng) * r
        z = Math.sin(lng) * r
        f(index, lng, x, y, z)

    distance = (x, y, z) ->
      return Math.sqrt(x*x + y*y + z*z)
    resize = (nd, x, y, z) ->
      d = distance(x, y, z)
      return [
        x / d * nd
        y / d * nd
        z / d * nd
      ]

    rings = []
    latPieces = 512
    lngPieces = 1024
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
    forEachLat(latPieces, (latIndex, lat) =>
      npieces = if latIndex == 0 or latIndex == latPieces then 0 else lngPieces
      ring = []
      forEachLng(lat, npieces, (lngIndex, lng, x, y, z) =>
        ring.push [x, y, z]
      )
      rings.push ring
    )
    console.log(rings)
    console.log("First generation stage took #{now() - t1}")

    faces = new FaceManager(500)
    addFace = (rawVertices...) ->
      vertexColors = []
      vertices = []
      for vertex in rawVertices
        [x, y, z] = vertex
        n = noise.noise3D(x, y, z)
        if n < 0
          n = 0
          vertexColors.push new THREE.Color(0x0000ff)
        else if n > .9
          vertexColors.push new THREE.Color(0xffffff)
        else
          vertexColors.push new THREE.Color(0x00ff00)
        r = (n/32 + 1) * sphereRadius
        vertices.push [x*r, y*r, z*r]
      faces.addFace(vertices..., {vertexColors: vertexColors})

    for ringIndex in [0..rings.length-2]
      ring = rings[ringIndex]
      nextRing = rings[ringIndex+1]
      isFirst = ringIndex == 0
      isLast = ringIndex == rings.length-2
      if isFirst
        p1 = ring[0]
        for p2index in [0..nextRing.length - 1]
          p2 = nextRing[p2index]
          p2next = nextRing[(p2index+1) % nextRing.length]
          addFace(p1, p2next, p2)
      else if isLast
        p2 = nextRing[0]
        for p1index in [0..ring.length - 1]
          p1 = ring[p1index]
          p1next = ring[(p1index+1) % ring.length]
          addFace(p1, p1next, p2)
      else
        for index in [0..ring.length - 1]
          p1 = ring[index]
          p1next = ring[(index+1) % ring.length]
          p2 = nextRing[index]
          p2next = nextRing[(index+1) % nextRing.length]
          addFace(p1, p1next, p2next)
          addFace(p1, p2next, p2)

    geometry = faces.generateGeometry()
    console.log("Planet generated in #{now() - t1}")
    console.log("Planet generated with #{geometry.vertices.length} vertices and #{geometry.faces.length} faces")
    geometry.computeFaceNormals()
    console.log('face normals computed')
    mesh = new THREE.Mesh(
      geometry
      new THREE.MeshLambertMaterial({vertexColors: THREE.VertexColors})
      )
    @scene.add mesh

    #faces = new FaceManager(500)
    # for latIndex in [0..latPieces]
    #   lat = latIndex / latPieces * Math.PI * 2 - Math.PI
    #   r = Math.sin(lat) * sphereRadius
    #   y = Math.cos(lat) * sphereRadius
    #   if latIndex == 0
    #     console.log(lat, r, y)

    #   for lngIndex in [0..lngPieces]
    #     lng = lngIndex / lngPieces * Math.PI * 2
    #     x = Math.cos(lng) * r
    #     z = Math.sin(lng) * r
    #     @scene.add m = new THREE.Mesh(
    #       new THREE.SphereGeometry(.1, 3, 3))
    #     m.position.x = x
    #     m.position.y = y
    #     m.position.z = z

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
    @person.update(delta)
