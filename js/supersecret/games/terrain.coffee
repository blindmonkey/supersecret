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


supersecret.Game = class TerrainGame extends supersecret.BaseGame
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

  initGeometry: ->

    smartMod = (n, m) ->
      while n < 0
        n += m
      while n >= m
        n -= m
      return n

    projectLatLong = (latitude, longitude, size) ->
      y = Math.sin(latitude)
      r = Math.cos(latitude)
      x = Math.cos(longitude) * r
      z = Math.sin(longitude) * r
      return new THREE.Vector3(x * size, y * size, z * size)

    getLatLngIndex = (latPoint, longPoint, points) ->
      latPoint = smartMod(latPoint, Math.floor(points / 2) + 1)
      longPoint = smartMod(longPoint, points)
      return longPoint * (Math.floor(points / 2) + 1) + latPoint


    getLatLngFromPoints = (latPoint, longPoint, points) ->
      latPoint = smartMod(latPoint, Math.floor(points / 2) + 1)
      longPoint = smartMod(longPoint, points)
      return {
        longitude: longPoint / points * Math.PI * 2
        latitude: latPoint / Math.floor(points / 2) * Math.PI - Math.PI / 2
      }

    pointMap = {}

    geometry = new THREE.Geometry()
    POINTS = 10
    for longPoint in [0..POINTS - 1]
      for latPoint in [0..Math.floor(POINTS / 2)]
        latlng = getLatLngFromPoints(latPoint, longPoint, POINTS)
        projected = projectLatLong(latlng.latitude, latlng.longitude, 10)
        geometry.vertices.push projected

        console.log(getLatLngIndex(latPoint, longPoint, POINTS))

        geometry.faces.push new THREE.Face3(
          getLatLngIndex(latPoint, longPoint, POINTS),
          getLatLngIndex(latPoint + 1, longPoint + 1, POINTS),
          getLatLngIndex(latPoint, longPoint + 1, POINTS)
          )

        if latPoint == 0
          m = new THREE.Mesh(
            new THREE.SphereGeometry(1, 3, 3),
            new THREE.LineBasicMaterial({color: 0x00ff00}))
          m.position = projected
          @scene.add m

        ###
        nextLatLng = getLatLngFromPoints(latPoint + 1, longPoint + 1, POINTS)
        latitude = latlng.latitude
        longitude = latlng.longitude

        nextLatitude = nextLatLng.latitude
        nextLongitude = nextLatLng.longitude



        geometry = new THREE.Geometry()
        v1 = projectLatLong(latitude, longitude, 10)
        v2 = projectLatLong(latitude, longitude, 11)
        geometry.vertices.push new THREE.Vector3(v1.x, v1.y, v1.z)
        geometry.vertices.push new THREE.Vector3(v2.x, v2.y, v2.z)
        ###
    m = new THREE.Mesh(geometry, new THREE.LineBasicMaterial({color: 0xff0000}))
    #m = new THREE.Mesh(geometry, new THREE.MeshPhongMaterial({color: 0xff0000, ambient: 0x00ff00}))
    @scene.add m



    #material = new THREE.MeshPhongMaterial({color: 0xff0000, ambient: 0x505050})
    #@scene.add new THREE.Mesh(geometry, material)

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

  render: (delta) ->
    @rotationalMomentum *= .9
    @rotation += @rotationalMomentum
    if @doRotate
      @rotation += .01
      @placeCamera()
    #@person.update(delta)
    @renderer.renderer.render(@scene, @camera)
