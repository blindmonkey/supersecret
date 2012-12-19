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
    @person = new FirstPerson(container, @camera)

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
    geometry = polygons.cube(1)
    attrmap = ['a', 'b', 'c']
    moved = new Set()
    faces = new FaceManager(geometry.faces.length+1)

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

    updateFace = (face) ->
      moreFaces = polygons.complexifyFace(face, 1)
      faces.removeFaces face
      for face in moreFaces
        newFace = []
        newColors = []
        for vi in [0..2]
          v = face[attrmap[vi]]
          [v, color] = fixVertex(v...)
          newFace.push v
          newColors.push color
        faces.addFace(newFace..., {vertexColors: newColors})

    mesh = null
    updateGeometry = =>
      geometry = faces.generateGeometry()
      console.log("Planet generated in #{now() - t1}")
      console.log("Planet generated with #{geometry.vertices.length} vertices and #{geometry.faces.length} faces")
      geometry.computeFaceNormals()
      geometry.verticesNeedUpdate = true
      geometry.facesNeedUpdate = true
      geometry.colorsNeedUpdate = true

      if mesh is null or mesh.geometry != geometry
        @scene.remove mesh if mesh
        mesh = new THREE.Mesh(
          geometry
          new THREE.MeshLambertMaterial({vertexColors: THREE.VertexColors})
          )
        @scene.add mesh

    runUpdater = ->
      faces.forEachFace((face) ->
        updateFace(face)
      )
      updateGeometry()




    # console.log('starting iteration')
    # for faceIndex in [0..geometry.faces.length-1]
    #   updater.update('face-iteration', "#{faceIndex} / #{geometry.faces.length}")
    #   face = geometry.faces[faceIndex]
    #   continue if face.a == face.b == face.c
    #   vs = []
    #   colors = []
    #   for vertexIndexIndex in [0..2]
    #     vertexIndex = face[attrmap[vertexIndexIndex]]
    #     vertex = geometry.vertices[vertexIndex]
    #     n = noise.noise3D(vertex.x, vertex.y, vertex.z)
    #     if n < 0
    #       n = 0
    #       colors.push new THREE.Color(0x0000ff)
    #     else if n > .9
    #       colors.push new THREE.Color(0xffffff)
    #     else
    #       colors.push new THREE.Color(0x00ff00)
    #     r = (n/32 + 1) * sphereRadius
    #     v = [vertex.x, vertex.y, vertex.z]
    #     vs.push [
    #       vertex.x * r
    #       vertex.y * r
    #       vertex.z * r
    #     ]
    #   faces.addFace(vs..., {vertexColors: colors})


    #geometry = faces.generateGeometry()
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
