class FirstPerson
  constructor: (container, camera) ->
    @container = $(container)
    @camera = camera
    @rotation = 0
    @pitch = 0
    @initialized = false

    @initControls()

    @keys = {
      UP: [38, 87]
      LEFT: [37, 65]
      RIGHT: [39, 68]
      DOWN: [40, 83]
      RISE: [69]
    }
    @downKeys = {}

  initControls: ->
    return if @initialized
    @initialized = true
    dragging = false
    lastPos = null
    @camera.position.y = 1
    person = this
    @container.mousedown (e) ->
      if e.button == 0
        dragging = true
        lastPos = [e.clientX, e.clientY]

    @container.mouseup (e) ->
      if e.button == 0
        dragging = false
        lastPos = null

    @container.mousemove (e) ->
      if dragging and lastPos != null
        [lx, ly] = lastPos
        [x, y] = [e.clientX, e.clientY]

        person.rotateY((x - lx) / -10)
        person.rotatePitch((y - ly) / -10)

        lastPos = [x, y]

    $(document).keydown(((e) ->
      console.log(e.keyCode)
      @downKeys[e.keyCode] = true
    ).bind(this))
    $(document).keyup(((e) ->
      @downKeys[e.keyCode] = false
    ).bind(this))

  update: (delta) ->
    for keyset of @keys
      for key in @keys[keyset]
        if @downKeys[key]
          if keyset == 'RISE'
            @camera.position.y += delta
          else if keyset == 'UP'
            @walkForward()
          else if keyset == 'DOWN'
            @walkBackward()
          else if keyset == 'LEFT'
            @strafeLeft()
          else if keyset == 'RIGHT'
            @strafeRight()

  rotateY: (degrees) ->
    radians = degrees * Math.PI / 180
    @rotation += radians
    while @rotation < 0
      @rotation += Math.PI * 2
    while @rotation > Math.PI * 2
      @rotation -= Math.PI * 2
    @updateCamera()

  updateCamera: ->
    targetX = @camera.position.x + Math.cos(@rotation)
    targetY = @camera.position.y - Math.sin(@pitch)
    targetZ = @camera.position.z + Math.sin(@rotation)
    @camera.lookAt(new THREE.Vector3(targetX, targetY, targetZ))

  rotatePitch: (degrees) ->
    radians = degrees * Math.PI / 180
    @pitch += radians
    while @pitch < 0
      @pitch += Math.PI * 2
    while @pitch > Math.PI * 2
      @pitch -= Math.PI * 2
    @updateCamera()

  walkForward: (speed) ->
    speed = speed or 10
    @camera.position.x = @camera.position.x + Math.cos(@rotation) * speed
    @camera.position.z = @camera.position.z + Math.sin(@rotation) * speed

  walkBackward: (speed) ->
    speed = speed or 10
    @camera.position.x = @camera.position.x + Math.cos(@rotation + Math.PI) * speed
    @camera.position.z = @camera.position.z + Math.sin(@rotation + Math.PI) * speed

  strafeLeft: (speed) ->
    speed = speed or 10
    @camera.position.x = @camera.position.x + Math.cos(@rotation - Math.PI / 2) * speed
    @camera.position.z = @camera.position.z + Math.sin(@rotation - Math.PI / 2) * speed

  strafeRight: (speed) ->
    speed = speed or 10
    @camera.position.x = @camera.position.x + Math.cos(@rotation + Math.PI / 2) * speed
    @camera.position.z = @camera.position.z + Math.sin(@rotation + Math.PI / 2) * speed

p.provide('FirstPerson', FirstPerson)
