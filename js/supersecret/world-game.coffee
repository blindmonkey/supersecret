Renderer = p.require('Renderer')
FirstPerson = p.require('FirstPerson')
BaseGame = p.require('BaseGame')

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

    @placeCamera()

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
        @rotation += e.clientX - lx
        @pitch += e.clientY - ly
        lastMouse = [e.clientX, e.clientY]
      ).bind(this))

    $(document).keydown(((e) ->
      if e.keyCode == 74
        @rotateGeometry(-.1)
      else if e.keyCode == 76
        @rotateGeometry(.1)
      ).bind(this))

  placeCamera: ->
    @camera.position.x = Math.cos(@rotation) * 75
    @camera.position.z = Math.sin(@rotation) * 75
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
          p.push({x: point[0]+180, y: point[1]})
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

    outlineMaterial = new THREE.LineBasicMaterial({color: 0x00ff00})
    radius = 10
    for polygon in polygons
      geometry = new THREE.Geometry()
      # avgx = 0
      # avgy = 0
      for point in polygon
        # avgx += point.x
        # avgy += point.y
        projected = projectLatLong(point.y, point.x, 1)
        geometry.vertices.push(new THREE.Vector3(projected.x * radius, projected.y * radius, projected.z * radius))
      # avgx /= polygon.length
      # avgy /= polygon.length
      # projectedAvg = projectLatLong(avgx, avgy)
      m = new THREE.Line(geometry, outlineMaterial)
      @scene.add m
      @globeGeometry.push m

    pointSize = .25

    PIECES = 128
    #MAX_HEIGHT =

    @countryUpdate = {}

    longitudeStep = 360 / PIECES
    latitudeStep = 180 / (PIECES / 2)

    @countryValues = {}
    for country in names
      @countryValues[country] = Math.random() * 10
    ###
    for country in @countryUpdate
      @countryUpdate[country](@countryValues[country])
    ###

    latitude = -90 + latitudeStep
    while latitude < 90
      longitude = -180
      while longitude < 180
        isInPoly = false
        countryName = null
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
          geometry = new THREE.Geometry()
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
          ###
          pTopLeft = projectLatLong(latitude - pointSize, longitude+180 - pointSize, radius)
          pTopRight = projectLatLong(latitude + pointSize, longitude+180 - pointSize, radius)
          pBottomLeft = projectLatLong(latitude - pointSize, longitude+180 + pointSize, radius)
          pBottomRight = projectLatLong(latitude + pointSize, longitude+180 + pointSize, radius)
          #p = projectLatLong(latitude, longitude+180)

          oTopLeft = new THREE.Vector3(pTopLeft.x, pTopLeft.y, pTopLeft.z)
          oTopRight = new THREE.Vector3(pTopRight.x, pTopRight.y, pTopRight.z)
          oBottomLeft = new THREE.Vector3(pBottomLeft.x, pBottomLeft.y, pBottomLeft.z)
          oBottomRight = new THREE.Vector3(pBottomRight.x, pBottomRight.y, pBottomRight.z)
          geometry.vertices.push oTopLeft
          geometry.vertices.push oTopRight
          geometry.vertices.push oBottomLeft
          geometry.vertices.push oBottomRight

          pTopLeft = new THREE.Vector3(pTopLeft.x, pTopLeft.y, pTopLeft.z)
          pTopRight = new THREE.Vector3(pTopRight.x, pTopRight.y, pTopRight.z)
          pBottomLeft = new THREE.Vector3(pBottomLeft.x, pBottomLeft.y, pBottomLeft.z)
          pBottomRight = new THREE.Vector3(pBottomRight.x, pBottomRight.y, pBottomRight.z)
          geometry.vertices.push pTopLeft
          geometry.vertices.push pTopRight
          geometry.vertices.push pBottomLeft
          geometry.vertices.push pBottomRight

          rerenderVector = ((outVector, oTopLeft, oTopRight, oBottomLeft, oBottomRight, pTopLeft, pTopRight, pBottomLeft, pBottomRight, geometry) ->
            return (value) ->
              value = value or 10
              pTopLeft.x = oTopLeft.x + outVector.x * value
              pTopLeft.y = oTopLeft.y + outVector.y * value
              pTopLeft.z = oTopLeft.z + outVector.z * value
              pTopRight.x = oTopRight.x + outVector.x * value
              pTopRight.y = oTopRight.y + outVector.y * value
              pTopRight.z = oTopRight.z + outVector.z * value
              pBottomLeft.x = oBottomLeft.x + outVector.x * value
              pBottomLeft.y = oBottomLeft.y + outVector.y * value
              pBottomLeft.z = oBottomLeft.z + outVector.z * value
              pBottomRight.x = oBottomRight.x + outVector.x * value
              pBottomRight.y = oBottomRight.y + outVector.y * value
              pBottomRight.z = oBottomRight.z + outVector.z * value
              geometry.verticesNeedUpdate = true
          )(outVector, oTopLeft, oTopRight, oBottomLeft, oBottomRight, pTopLeft, pTopRight, pBottomLeft, pBottomRight, geometry)
          @countryUpdate[countryName].push(rerenderVector)

          #geometry.faces.push new THREE.Face3(geometry.vertices.length - 4, geometry.vertices.length - 3, geometry.vertices.length - 1)

          geometry.faces.push new THREE.Face3(geometry.vertices.length - 4, geometry.vertices.length - 3, geometry.vertices.length - 1)
          geometry.faces.push new THREE.Face3(geometry.vertices.length - 4, geometry.vertices.length - 1, geometry.vertices.length - 2)
          ###


        longitude += longitudeStep
      latitude += latitudeStep
      ###
      m = new THREE.Mesh(geometry,
        new THREE.MeshPhongMaterial({color: 0xff0000}))
      @scene.add(m)
      @globeGeometry.push(m)
      ###
    @scene.add new THREE.Mesh(new THREE.SphereGeometry(9.9, 32, 32), new THREE.LineBasicMaterial({color: 0x000000}))
    console.log(uncharted)


    #geometry.computeFaceNormals()
    console.log('done')

  initLights: ->
    @scene.add new THREE.AmbientLight(0x505050)
    light = new THREE.PointLight(0x505050, 3, 2000)
    light.x = -150
    light.y = 0
    light.z = 36
    DEBUG.expose('light', light)
    @scene.add light

  render: (delta) ->
    @rotation += .01
    @placeCamera()
    #@person.update(delta)
    @renderer.renderer.render(@scene, @camera)


p.provide('WorldGame', WorldGame)
