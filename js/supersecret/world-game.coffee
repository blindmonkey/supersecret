Renderer = p.require('Renderer')
FirstPerson = p.require('FirstPerson')
BaseGame = p.require('BaseGame')

lerpColor = (c1, c2, x) ->
  c1b = c1 & 0xFF
  c1g = (c1 & 0xFF00) >> 8
  c1r = (c1 & 0xFF0000) >> 16
  c2b = c2 & 0xFF
  c2g = (c2 & 0xFF00) >> 8
  c2r = (c2 & 0xFF0000) >> 16
  outr = Math.floor((c2r - c1r) * x + c1r)
  outg = Math.floor((c2g - c1g) * x + c1g)
  outb = Math.floor((c2b - c1b) * x + c1b)
  console.log(c1r, c1g, c1b, c2r, c2g, c2b, x, outr, outg, outb)
  if outr > 255
    outr = 255
  if outr < 0
    outr = 0
  if outg > 255
    outg = 255
  if outg < 0
    outg = 0
  if outb > 255
    outb = 255
  if outb < 0
    outb = 0
  return (outr << 16) + (outg << 8) + outb


class WorldGame extends BaseGame
  constructor: (container, width, height, opt_scene, opt_camera) ->
    super(container, width, height, opt_scene, opt_camera)

    DEBUG.expose('chunk', @chunk)
    DEBUG.expose('scene', @scene)

    @camera.position.x = -50
    @camera.position.y = 0
    @camera.position.z = 0

    #@person = new FirstPerson(container, @camera)
    #@person.updateCamera()
    @rotation = 0
    @pitch = 0
    @rotationalMomentum = 0


    lastMouse = null
    dragging = false
    $(container).mousedown(((e) ->
      dragging = true
      lastMouse = [e.clientX, e.clientY]
      ).bind(this))
    $(container).mouseup(((e) ->
      dragging = false
      lastMouse = null
      ).bind(this))
    $(container).mousemove(((e) ->
      if dragging
        [lx, ly] = lastMouse
        @rotationalMomentum = (e.clientX - lx) / 50
        @pitch += (e.clientY - ly) / 50
        lastMouse = [e.clientX, e.clientY]
      ).bind(this))

    @distance = 75

    @placeCamera()

    actions =
      LEFT: 74
      RIGHT: 76
      ZOOMIN: 69
      ZOOMOUT: 81
      ROTATE_TOGGLE: 82

    @doRotate = true

    $(document).keydown(((e) ->
      if e.keyCode == actions.LEFT
        #@rotateGeometry(-.1)
        @rotation += 1
        @placeCamera()
      else if e.keyCode == actions.RIGHT
        #@rotateGeometry(.1)
        @rotation -= 1
        @placeCamera()
      else if e.keyCode == actions.ZOOMIN
        @distance += 1
        @placeCamera()
      else if e.keyCode == actions.ZOOMOUT
        @distance -= 1
        @placeCamera()
      else if e.keyCode == actions.ROTATE_TOGGLE
        @doRotate = not @doRotate
      else
        console.log(e.keyCode + ' pressed but not bound')

      ).bind(this))

  placeCamera: ->
    @camera.position.x = Math.cos(@rotation) * @distance
    @camera.position.z = Math.sin(@rotation) * @distance
    @camera.position.y = Math.sin(@pitch) * @distance
    @camera.lookAt(new THREE.Vector3(0, 0, 0))

  rotateGeometry: (amount) ->
    for mesh in @globeGeometry
      mesh.rotation.y += amount

  initGeometry: ->
    material = new THREE.LineBasicMaterial({color: 0xff0000})

    polygons = []
    names = []

    min = 0
    max = 0

    smartMod = (n, m) ->
      while n < 0
        n += m
      while n >= m
        n -= m
      return n

    #debugger
    for feature in maps.d3world.features
      if feature.type != 'Feature'
        throw 'Non-feature found in features'

      polygon = feature.geometry.coordinates
      if feature.geometry.type == 'Polygon'
        console.log feature.properties.name
        polygon = [polygon]

      for points in polygon
        p = []
        for point in points[0]
          if point[0] < min
            min = point[0]
          if point[0] > max
            max = point[0]
          p.push({x: smartMod(360-point[0]+180, 360), y: point[1]})
        polygons.push(p)
        names.push(feature.properties.name)
    console.log(min, max, polygons)

    uncharted = []
    mapped = {}
    l = (n for n in names)
    l.sort()
    console.log(l)

    @globeGeometry = []

    projectLatLong = (latitude, longitude, size) ->
      y = Math.sin(latitude / 180 * Math.PI)
      r = Math.cos(latitude / 180 * Math.PI)
      x = Math.cos(longitude / 180 * Math.PI) * r
      z = Math.sin(longitude / 180 * Math.PI) * r
      return {x:x * size, y:y * size, z:z * size}

    @countryValues = {}
    for country in names
      @countryValues[country] = Math.random()
    @countryUpdates = {}

    color1 = 0xc02020
    color2 = 0x00ff00

    outlineMaterial = new THREE.LineBasicMaterial({color: 0x00ff00})
    radius = 10
    for polygonIndex in [0..polygons.length - 1]
      polygon = polygons[polygonIndex]
      name = names[polygonIndex]
      geometry = new THREE.Geometry()
      addFace = (a, b, c) ->
        geometry.faces.push(
          new THREE.Face3(
            (geometry.vertices.length + a) % geometry.vertices.length,
            (geometry.vertices.length + b) % geometry.vertices.length,
            (geometry.vertices.length + c) % geometry.vertices.length))

      color = lerpColor(color1, color2, @countryValues[name])
      # avgx = 0
      # avgy = 0
      for pointIndex in [0..polygon.length - 1]
        point = polygon[pointIndex]
        nextPoint = polygon[(pointIndex + 1) % polygon.length]

        # avgx += point.x
        # avgy += point.y

        projected = projectLatLong(point.y, point.x, 1)
        nextProjected = projectLatLong(nextPoint.y, nextPoint.x, 1)

        if name not of @countryUpdates
          @countryUpdates[name] = []

        realr1 = radius
        realr2 = radius + @countryValues[name] + .2
        r1 = 0
        r2 = 0

        vectorAtR = (point, r) ->
          return new THREE.Vector3(point.x * r, point.y * r, point.z * r)
        v1 = vectorAtR(projected, realr1)
        v2 = vectorAtR(projected, realr2)
        v3 = vectorAtR(nextProjected, realr1)
        v4 = vectorAtR(nextProjected, realr2)

        #@countryUpdates[name].push(updateVectors)

        geometry.vertices.push(v1)
        geometry.vertices.push(v2)
        geometry.vertices.push(v3)
        geometry.vertices.push(v4)
        addFace(-4, -2, -1)
        addFace(-4, -1, -3)
        addFace(-4, -1, -2)
        addFace(-4, -3, -1)
      # avgx /= polygon.length
      # avgy /= polygon.length
      # projectedAvg = projectLatLong(avgx, avgy)
      geometry.computeFaceNormals()
      m = new THREE.Mesh(geometry, new THREE.MeshPhongMaterial({color: color}))
      @scene.add m
      @globeGeometry.push m
      ##
    @scene.add new THREE.Mesh(new THREE.SphereGeometry(radius, 32, 32), new THREE.LineBasicMaterial({color: 0x000000}))

    pointSize = .25

    PIECES = 128
    #MAX_HEIGHT =

    longitudeStep = 360 / PIECES
    latitudeStep = 180 / (PIECES / 2)

    @vectorInit = 0

    ###
    for country in @countryUpdate
      @countryUpdate[country](@countryValues[country])
    ###


    #for polygon in polygons


    drawLatLngPoints = (pieces) ->
      latitude = -90 + latitudeStep
      while latitude < 90
        longitude = -180
        while longitude < 180
          isInPoly = false
          name = null
          polygon = null
          for polygonI of polygons
            polygon = polygons[polygonI]
            if isPointInPoly(polygon, {x:longitude+180, y:latitude})
              name = names[polygonI]
              if name not of mapped
                mapped[name] = true
              countryName = name
              isInPoly = true
              break

          if isInPoly
            if countryName not of @countryUpdate
              @countryUpdate[countryName] = []

            outVector = projectLatLong(latitude, longitude+180, 1)

            geometry.vertices.push(new THREE.Vector3(
              outVector.x * radius,
              outVector.y * radius,
              outVector.z * radius))
            v = @countryValues[countryName]
            geometry.vertices.push(new THREE.Vector3(
              outVector.x * (radius + v / 10),
              outVector.y * (radius + v / 10),
              outVector.z * (radius + v / 10)))
            m = new THREE.Line(geometry, new THREE.LineBasicMaterial({color: 0xff0000}))
            @scene.add m
            @globeGeometry.push m


          longitude += longitudeStep
        latitude += latitudeStep
        ###
        m = new THREE.Mesh(geometry,
          new THREE.MeshPhongMaterial({color: 0xff0000}))
        @scene.add(m)
        @globeGeometry.push(m)
        ###
      console.log(uncharted)


    #geometry.computeFaceNormals()
    console.log('done')

  initLights: ->
    console.log('initializing lights!')
    #@scene.add new THREE.AmbientLight(0x505050)
    light = new THREE.PointLight(0x505050, 3, 50)
    light.position.x = -20
    light.position.y = 0
    light.position.z = 0
    DEBUG.expose('light', light)
    @scene.add light

    light = new THREE.PointLight(0x505050, 3, 50)
    light.position.x = 20
    light.position.y = 0
    light.position.z = 0
    DEBUG.expose('light', light)
    @scene.add light

    light = new THREE.PointLight(0x505050, 3, 50)
    light.position.x = 0
    light.position.y = 0
    light.position.z = 20
    DEBUG.expose('light', light)
    @scene.add light

    light = new THREE.PointLight(0x505050, 3, 50)
    light.position.x = 0
    light.position.y = 0
    light.position.z = -20
    DEBUG.expose('light', light)
    @scene.add light

    ###
    light = new THREE.DirectionalLight(0xffffff, 3, 2000)
    light.position.x = -75
    light.position.y = 0
    light.position.z =0
    light.target.position.set(0, 0, 0)
    #@scene.add light
    DEBUG.expose('dlight', light)

    light = new THREE.DirectionalLight(0xffffff, 3, 2000)
    light.position.x = 75
    light.position.y = 0
    light.position.z =0
    light.target.position.set(0, 0, 0)
    #@scene.add light
    DEBUG.expose('dlight2', light)
    ###

  render: (delta) ->
    if @vectorInit < 0 && false
      @vectorInit += .01
      for country of @countryUpdates
        for updater in @countryUpdates[country]
          updater(.2 * @vectorInit, (@countryValues[country] + .2) * @vectorInit)
    @rotationalMomentum *= .9
    @rotation += @rotationalMomentum
    if @doRotate
      @rotation += .01
      @placeCamera()
    #@person.update(delta)
    @renderer.renderer.render(@scene, @camera)


p.provide('WorldGame', WorldGame)
