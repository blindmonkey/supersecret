lib.export('FirstPerson', class FirstPerson
  constructor: (container, camera, horizontalAxes) ->
    @horizontalAxes = ['x', 'z']
    @container = $(container)
    @camera = camera
    @rotation = 0
    @pitch = 0
    @tilt = 0
    @initialized = false

    @initControls()

    @keys = {
      UP: [38, 87]
      LEFT: [37, 65]
      RIGHT: [39, 68]
      DOWN: [40, 83]
      RISE: [69]
      LOWER: [81]
      TILTRIGHT: [84]
      TILTLEFT: [82]
    }
    @downKeys = {}

  initControls: ->
    return if @initialized
    @initialized = true
    dragging = false
    lastPos = null
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

        person.rotateY((x - lx) / 10)
        person.rotatePitch((y - ly) / 10)

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
            @camera.position.y += delta / 10
          if keyset == 'LOWER'
            @camera.position.y -= delta / 10
          else if keyset == 'UP'
            @walkForward(delta / 10)
          else if keyset == 'DOWN'
            @walkBackward(delta / 10)
          else if keyset == 'LEFT'
            @strafeLeft(delta / 10)
          else if keyset == 'RIGHT'
            @strafeRight(delta / 10)
          else if keyset == 'TILTRIGHT'
            @tilt += .1
          else if keyset == 'TILTLEFT'
            @tilt -= .1

  rotateY: (degrees) ->
    radians = degrees * Math.PI / 180
    @rotation += radians
    while @rotation < 0
      @rotation += Math.PI * 2
    while @rotation > Math.PI * 2
      @rotation -= Math.PI * 2
    @updateCamera()

  updateCamera: ->
    v = new THREE.Vector3(0, 0, 0)

    [hAxis1, hAxis2] = @horizontalAxes
    # v.x = @camera.position.x + Math.cos(@rotation)
    # v.y = @camera.position.y - Math.sin(@pitch)
    # v.z = @camera.position.z + Math.sin(@rotation)
    cosPitch = Math.cos(@pitch)
    if cosPitch < 0
      cosPitch = 0.01
      @pitch = Math.acos(cosPitch)
    v[hAxis1] = @camera.position[hAxis1] + Math.cos(@rotation) * cosPitch
    v.y = @camera.position.y - Math.sin(@pitch)
    v[hAxis2] = @camera.position[hAxis2] + Math.sin(@rotation) * cosPitch
    #v.normalize()
    #console.log(@pitch)

    @camera.lookAt(v)
    @ca

  rotatePitch: (degrees) ->
    radians = degrees * Math.PI / 180
    @pitch += radians
    while @pitch < 0
      @pitch += Math.PI * 2
    while @pitch > Math.PI * 2
      @pitch -= Math.PI * 2

    @updateCamera()

  modifyPosition: (rotation, speed) ->
    speed = speed or 10
    [hAxis1, hAxis2] = @horizontalAxes
    @camera.position[hAxis1] = @camera.position[hAxis1] + Math.cos(rotation) * speed
    @camera.position[hAxis2] = @camera.position[hAxis2] + Math.sin(rotation) * speed

  walkForward: (speed) ->
    return @modifyPosition(@rotation, speed)

  walkBackward: (speed) ->
    return @modifyPosition(@rotation + Math.PI, speed)

  strafeLeft: (speed) ->
    return @modifyPosition(@rotation - Math.PI / 2, speed)

  strafeRight: (speed) ->
    return @modifyPosition(@rotation + Math.PI / 2, speed)
)
