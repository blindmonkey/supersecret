Renderer = p.require('Renderer')
FirstPerson = p.require('FirstPerson')
BaseGame = p.require('BaseGame')

class WorldGame extends BaseGame
  constructor: (container, width, height, opt_scene, opt_camera) ->
    super(container, width, height, opt_scene, opt_camera)

    DEBUG.expose('chunk', @chunk)
    DEBUG.expose('scene', @scene)

    @camera.position.x = 0
    @camera.position.y = 1
    @camera.position.z = 0

    @person = new FirstPerson(container, @camera)
    @person.updateCamera()




  initGeometry: ->
    PIECES = 256

    longitudeStep = 360 / PIECES
    latitudeStep = 180 / (PIECES / 2)

    material = new THREE.LineBasicMaterial({color: 0xff0000})

    polygons = []

    min = 0
    max = 0

    #debugger
    for feature in maps.d3world.features
      if feature.type != 'Feature'
        throw 'Non-feature found in features'

      polygon = feature.geometry.coordinates
      if feature.geometry.type == 'MultiPolygon'
        polygon = polygon[0]
      if polygon.length == 1
        polygon = polygon[0]

      p = []
      for point in polygon
        if point[0] < min
          min = point[0]
        if point[0] > max
          max = point[0]
        p.push({x: point[0], y: point[1]})
      polygons.push(p)
    console.log(min, max, polygons)

    radius = 10
    latitude = -90 + latitudeStep
    while latitude < 90
      y = Math.sin(latitude / 180 * Math.PI)
      r = Math.cos(latitude / 180 * Math.PI)

      longitude = -180
      while longitude < 180
        isInPoly = false
        for polygon in polygons
          if isPointInPoly(polygon, {x:-latitude, y:longitude})
            isInPoly = true
            break
        if isInPoly
          x = Math.cos(longitude / 180 * Math.PI) * r
          z = Math.sin(longitude / 180 * Math.PI) * r

          if isNaN(x) or isNaN(z) or isNaN(y) or isNaN(r)
            throw 'shit'

          #geometry = new THREE.Geometry()
          v1 = new THREE.Vector3(x * radius, y * radius, z * radius)
          v2 = new THREE.Vector3(x * (radius + .1), y * (radius + .1), z * (radius + .1))
          #geometry.vertices.push(v1)
          #geometry.vertices.push(v2)
          #@scene.add(new THREE.Line(geometry, material))
          m = new THREE.Mesh(
            new THREE.SphereGeometry(.1, 2, 2),
            material
            )
          m.position = v1
          @scene.add(m)

        longitude += longitudeStep
      latitude += latitudeStep

    #geometry.computeFaceNormals()
    console.log('done')
    #material = new THREE.MeshPhongMaterial({color: 0xff0000})
    #mesh = new THREE.Mesh(geometry, material)
    #mesh = new THREE.Line(geometry, material)
    #@scene.add(mesh)
    ###
    @scene.add(new THREE.Mesh(
      new THREE.SphereGeometry(2, 16, 16),
      new THREE.MeshPhongMaterial({color: 0xff0000})))
    ###

  initLights: ->
    @scene.add new THREE.AmbientLight(0x505050)
    light = new THREE.PointLight(0x505050, 3, 2000)
    light.x = -150
    light.y = 0
    light.z = 36
    DEBUG.expose('light', light)
    @scene.add light

  render: (delta) ->
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)


p.provide('WorldGame', WorldGame)
