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


supersecret.Game = class HexagonGame extends supersecret.BaseGame
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
    geometry = new THREE.Geometry()
    size = 2
    r = 0
    geometry.vertices.push new THREE.Vector3(Math.cos(r) * size, 0, Math.sin(r) * size)
    r += Math.PI * 2 / 5
    geometry.vertices.push new THREE.Vector3(Math.cos(r) * size, 0, Math.sin(r) * size)
    r += Math.PI * 2 / 5
    geometry.vertices.push new THREE.Vector3(Math.cos(r) * size, 0, Math.sin(r) * size)
    r += Math.PI * 2 / 5
    geometry.vertices.push new THREE.Vector3(Math.cos(r) * size, 0, Math.sin(r) * size)
    r += Math.PI * 2 / 5
    geometry.vertices.push new THREE.Vector3(Math.cos(r) * size, 0, Math.sin(r) * size)

    for vertex in geometry.vertices
      g = new THREE.SphereGeometry(.5, 8, 8)
      m = new THREE.Mesh(g, new THREE.LineBasicMaterial({color: 0x00ff00}))
      m.position = vertex
      @scene.add m




  initLights: ->
    console.log('initializing lights!')
    @scene.add new THREE.AmbientLight(0xffffff)
    light = new THREE.PointLight(0x505050, 3, 50)
    light.position.x = -20
    light.position.y = 0
    light.position.z = 0
    DEBUG.expose('light', light)
    @scene.add light

    dlight = new THREE.DirectionalLight(0xffffff, .6)
    dlight.position.set(1, 1, 1)
    @scene.add dlight

  render: (delta) ->
    @rotationalMomentum *= .9
    @rotation += @rotationalMomentum
    if @doRotate
      @rotation += .01
      @placeCamera()
    #@person.update(delta)
    @renderer.renderer.render(@scene, @camera)