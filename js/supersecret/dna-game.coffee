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


random =
  choice: (l) ->
    return l[Math.floor(Math.random() * l.length)]


class DnaGame extends BaseGame
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
    @distance = 27


    lastMouse = null
    dragging = false
    $(container).bind('mousewheel', ((e, delta) ->
      delta = e.originalEvent.wheelDeltaY
      @distance += delta / 120
    ).bind(this))

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

    DEBUG.expose('game', this)

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
    colors = [0xff0000, 0x00ff00, 0x0000ff]
    for y in [-10..10]
      rotation = (y / 15 * Math.PI * 2) % (Math.PI * 2)
      x = Math.cos(rotation) * 2
      z = Math.sin(rotation) * 2
      v1 = new THREE.Vector3(x, y, z)
      v2 = new THREE.Vector3(-x, y, -z)

      #v = new THREE.Vector3(x, y, z)
      geometry = new THREE.SphereGeometry(.2, 8, 8)
      mesh = new THREE.Mesh(geometry, new THREE.MeshPhongMaterial({color: random.choice(colors)}))
      mesh.position = v1
      @scene.add mesh

      geometry = new THREE.SphereGeometry(.2, 8, 8)
      mesh = new THREE.Mesh(geometry, new THREE.MeshPhongMaterial({color: random.choice(colors)}))
      mesh.position = v2
      @scene.add mesh

      geometry = new THREE.CylinderGeometry(.05, .05, 3.6, 8, 8, false)
      mesh = new THREE.Mesh(geometry, new THREE.MeshPhongMaterial({color: 0x777777}))
      mesh.position.y = y
      mesh.rotation.z = Math.PI / 2
      mesh.rotation.y = -rotation# + Math.PI / 2 + Math.PI / 4
      @scene.add mesh

      geometry = new THREE.Geometry()
      geometry.vertices.push(v1)
      geometry.vertices.push(v2)
      #@scene.add new THREE.Line(geometry, new THREE.LineBasicMaterial({color: 0xff0000}))




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


p.provide('DnaGame', DnaGame)
