require('three/base')
require('firstperson')
require('three/three.min.js')
require('geometry/facemanager')
require('graphics/color')
# require('polygons')

class CircularGradient
  constructor: ->
    @stops = []

  add: (p, color) ->
    return if p < 0 or p > 1
    item =
      p:p
      color:color
    return @stops.push item if @stops.length == 0
    for i in [0..@stops.length - 1]
      if p < @stops[i].p
        @stops.splice(i, 0, item)
        return
    @stops.push(item)

  get: (p) ->
    p-1 while p > 1
    p+1 while p < 0
    op = p
    last = false
    for i in [0..@stops.length]
      last = yes if i == @stops.length
      i %= @stops.length
      nextp = @stops[i].p
      pi = if i is 0 then @stops.length - 1 else i - 1
      prevp = @stops[pi].p
      if nextp <= p or p > prevp
        next = @stops[i].color
        prev = @stops[pi].color
        if prevp > nextp
          nextp += 1
          p = op+1 if op <= nextp
        normp = (p - prevp) / (nextp - prevp)
        console.log(normp)
        return Color.lerp(prevp, nextp, normp)
    throw "WTF"


window.CircularGradient = CircularGradient;


exports.Game = class NewGame extends BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)

  initGeometry: ->
    faces = new FaceManager(5000)
    # geometry = new THREE.Geometry()
    createRing = (radius, rotationOffset) ->
      rotationOffset = rotationOffset or 0
      N = 20
      for r in [1..N]
        rotation = r / N * Math.PI * 2
        # console.log(rotation)
        # prevrotation = (r-1) / N * Math.PI * 2
        currentx = Math.cos(rotation + rotationOffset) * radius
        currenty = Math.sin(rotation + rotationOffset) * radius
        [currentx, currenty]


    DENSITY = 20
    rings = []
    gradient = new CircularGradient()
    gradient.add 0, 0xff0000
    gradient.add 0.5, 0x00ff00




    for x in [0..20]
      ring = createRing DENSITY, x/2
      rings.push ring
      if rings.length > 1
        prevring = rings[rings.length - 2]
        for j in [1..ring.length]
          i = (j - 1)
          j = j % ring.length
          [rcx, rcy] = ring[i]
          [rnx, rny] = ring[j]
          [pcx, pcy] = prevring[i]
          [pnx, pny] = prevring[j]
          color = gradient.get(i / ring.length)
          console.log(color)
          color = color.hex()
          faces.addFace(
            [rcx, rcy, x*10]
            [pnx, pny, (x-1)*10]
            [rnx, rny, x*10]
            { color: color })
          faces.addFace(
            [rcx, rcy, x*10]
            [pcx, pcy, (x-1)*10]
            [pnx, pny, (x-1)*10]
            { color: color })
          # faces.addFace(
          #   [rcx, rcy, x*10]
          #   [pnx, pny, (x-1)*10]
          #   [pcx, pcy, (x-1)*10])
          # faces.addFace([ring[i][0], ring[i][1], x * 10],
          #   [ring[j][0], ring[j][1], x * 10],
          #   [prevring[j][0], prevring[j][1], (x-1) * 10])
          # faces.addFace([ring[i][0], ring[i][1], x * 10],
          #   [prevring[j][0], prevring[j][1], (x-1) * 10],
          #   [prevring[i][0], prevring[i][1], (x-1) * 10])


    geometry = faces.generateGeometry()
    geometry.computeFaceNormals()

    @scene.add new THREE.Mesh(geometry
      # new THREE.MeshNormalMaterial()
      new THREE.MeshBasicMaterial({
        vertexColors: THREE.FaceColors
      })
    )



  update: (delta) ->
    @person.update(delta)
