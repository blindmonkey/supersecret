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

PIECES = [
  '''
  0010
  0110
  0100
  0000
  '''
]

(->
  stringPieces = PIECES
  PIECES = []

  for piece in stringPieces
    piece = piece.trim()
    rows = piece.split('\n')
    realPiece = []
    for x in [0..3]
      realPieceRow = []
      for y in [0..3]
        realPieceRow.push !!parseInt(rows[y][x])
      realPiece.push realPieceRow
    PIECES.push realPiece
)()

console.log(PIECES)


supersecret.Game = class HexagonGame extends supersecret.BaseGame
  constructor: (container, width, height, opt_scene, opt_camera) ->

    @gridSize =
      width: 15
      height: 20
      radius: 10
    @grid = []
    for x in [0..@gridSize.width-1]
      row = []
      for y in [0..@gridSize.height-1]
        row.push(null)
      @grid.push row
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
      DOWN: 83
      ZOOMIN: 69
      ZOOMOUT: 81
      ROTATE_TOGGLE: 82

    @doRotate = true

    @playerPiece = PIECES[0]
    @playerPiecePosition =
      x: 0
      y: @gridSize.height

    $(document).keydown(((e) ->
      if e.keyCode == actions.LEFT
        @playerPiecePosition.x -= 1
      else if e.keyCode == actions.DOWN
        @playerPiecePosition.y -= 1
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

      while @playerPiecePosition.x < 0
        @playerPiecePosition.x += @gridSize.width
      while @playerPiecePosition.x >= @gridSize.width
        @playerPiecePosition.x -= @gridSize.width

    ).bind(this))

  placeCamera: ->
    @camera.position.x = Math.cos(@rotation) * @distance
    @camera.position.z = Math.sin(@rotation) * @distance
    @camera.position.y = Math.sin(@pitch) * @distance
    @camera.lookAt(new THREE.Vector3(0, 0, 0))

  createBlockGeometry: (x, y) ->
    blockSize = @gridSize.radius * Math.PI * 2 / @gridSize.width
    resolution = 5
    nx = (x + 1)
    ny = y + 1

    ycoord = y * blockSize #- @gridSize.height * blockSize / 3
    nycoord = ny * blockSize #- @gridSize.height * blockSize / 3

    rx = x / @gridSize.width * 2 * Math.PI
    rnx = nx / @gridSize.width * 2 * Math.PI

    geometry = new THREE.Geometry()
    for r in [0..resolution]
      rot = r / resolution * (rnx - rx) + rx

      geometry.vertices.push new THREE.Vector3(
        Math.cos(rot) * @gridSize.radius,
        ycoord,
        Math.sin(rot) * @gridSize.radius
      )
      geometry.vertices.push new THREE.Vector3(
        Math.cos(rot) * @gridSize.radius,
        nycoord,
        Math.sin(rot) * @gridSize.radius
      )
      geometry.vertices.push new THREE.Vector3(
        Math.cos(rot) * (@gridSize.radius - blockSize),
        ycoord,
        Math.sin(rot) * (@gridSize.radius - blockSize)
      )
      geometry.vertices.push new THREE.Vector3(
        Math.cos(rot) * (@gridSize.radius - blockSize),
        nycoord,
        Math.sin(rot) * (@gridSize.radius - blockSize)
      )

      if r == 0
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 1,
          geometry.vertices.length - 3,
          geometry.vertices.length - 2,
          )
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 3,
          geometry.vertices.length - 4,
          geometry.vertices.length - 2,
          )
      else if r > 0
        #Top faces
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 1,
          geometry.vertices.length - 3,
          geometry.vertices.length - 5,
          )
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 5,
          geometry.vertices.length - 3,
          geometry.vertices.length - 7,
          )
        #bottom faces
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 2,
          geometry.vertices.length - 6,
          geometry.vertices.length - 4,
          )
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 4,
          geometry.vertices.length - 6,
          geometry.vertices.length - 8,
          )
        #front faces
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 3,
          geometry.vertices.length - 4,
          geometry.vertices.length - 8,
          )
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 8,
          geometry.vertices.length - 7,
          geometry.vertices.length - 3,
          )
        #front faces
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 3,
          geometry.vertices.length - 4,
          geometry.vertices.length - 8,
          )
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 8,
          geometry.vertices.length - 7,
          geometry.vertices.length - 3,
          )
        #back faces
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 1,
          geometry.vertices.length - 6,
          geometry.vertices.length - 2,
          )
        geometry.faces.push new THREE.Face3(
          geometry.vertices.length - 6,
          geometry.vertices.length - 1,
          geometry.vertices.length - 5,
          )
    geometry.faces.push new THREE.Face3(
      geometry.vertices.length - 1,
      geometry.vertices.length - 2,
      geometry.vertices.length - 3,
      )
    geometry.faces.push new THREE.Face3(
      geometry.vertices.length - 3,
      geometry.vertices.length - 2,
      geometry.vertices.length - 4,
      )

    geometry.computeFaceNormals()
    return new THREE.Mesh(geometry,
      new THREE.MeshPhongMaterial({color: 0x00ff00}))
      #new THREE.LineBasicMaterial({color: 0x00ff00}))


  initGeometry: ->
    blockSize = @gridSize.radius * Math.PI * 2 / @gridSize.width

    resolution = 5
    for y in [0..@gridSize.height-1]
      for x in [0..@gridSize.width-1]
        block = @grid[x][y]

        if block
          @scene.add @createBlockGeometry(x, y)
    geometry = new THREE.Geometry()
    for x in [0..@gridSize.width-1]
      nextX = (x + 1) % @gridSize.width
      rx = x / @gridSize.width * 2 * Math.PI
      rnx = nextX / @gridSize.width * 2 * Math.PI
      geometry.vertices.push(new THREE.Vector3(
        Math.cos(rx) * @gridSize.radius,
        0,
        Math.sin(rx) * @gridSize.radius
        ))
      geometry.vertices.push(new THREE.Vector3(
        Math.cos(rnx) * @gridSize.radius,
        0,
        Math.sin(rnx) * @gridSize.radius
        ))
    @scene.add new THREE.Line(geometry, new THREE.LineBasicMaterial({color: 0xff0000}), THREE.LinePieces)






  initLights: ->
    console.log('initializing lights!')
    #@scene.add new THREE.AmbientLight(0xffffff)
    light = new THREE.PointLight(0xffffff, .9, 100)
    light.position.x = 0
    light.position.y = 10
    light.position.z = 0
    DEBUG.expose('light', light)
    @scene.add light

    dlight = new THREE.DirectionalLight(0xffffff, .6)
    dlight.position.set(1, 1, 1)
    @scene.add dlight
    dlight = new THREE.DirectionalLight(0xffffff, .6)
    dlight.position.set(-1, 1, -1)
    @scene.add dlight

  render: (delta) ->
    @rotationalMomentum *= .9
    @rotation += @rotationalMomentum
    if @doRotate
      @rotation += .01
      @placeCamera()
    #@person.update(delta)
    @renderer.renderer.render(@scene, @camera)
