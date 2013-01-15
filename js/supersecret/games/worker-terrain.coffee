terrainWorkerCode = """
console.log('hello from worker')

getIndex = (size, x, y) ->
  return y * size + x

randomoffset = ->
  return {
    x: (Math.random() * 2 - 1) * 100
    y: (Math.random() * 2 - 1) * 100
  }

seed = undefined
description = [{
    scale: .01
    multiplier: 10
    offset: randomoffset()
  }, {
    scale: .03
    multiplier: 4
    offset: randomoffset()
  }, {
    scale: .05
    multiplier: 3
    offset: randomoffset()
  }, {
    scale: .09
    multiplier: .9
    offset: randomoffset()
  }, {
    scale: .12
    multiplier: .7
    offset: randomoffset()
  }, {
    scale: .2
    multiplier: .6
    offset: randomoffset()
  }, {
    scale: .35
    multiplier: .5
  }, {
    scale: .5
    multiplier: .3
  }, {
    scale: .8
    multiplier: .1
  }, {
    scale: 1.5
    multiplier: .05
  }, {
    scale: 2
    multiplier: .04
  }, {
    scale: 4
    multiplier: .03
  }, {
    scale: .02
    multiplier: 2
  }
]
# description = [{
#   scale: 0.0001
#   multiplier: 128
# }]
noise = null
initGenerator = ->
  # Math.seedrandom(seed)
  console.log('Reinitializing noise with ', description)
  noise = new NoiseGenerator(
    new SimplexNoise(Math.random), description)

generateGeometry = (offset, density, size) ->
  [ox, oy] = offset
  t = new Date().getTime()
  maxheight = noise.getMaxValue()

  getColor = (n) ->
    n = n / maxheight
    return 0x0000ff if n < 0
    return 0x00ff00 if n < .3
    return 0xff6633 if n < .6
    return 0xffffff
    return Math.floor(n / maxheight * 256)


  faces = new FaceManager(500)
  for y in [1..density-1]
    for x in [1..density-1]
      xl = (x - 1) / (density-1) * size
      xs = x / (density-1) * size
      yl = (y - 1) / (density-1) * size
      ys = y / (density-1) * size

      n_xl_yl = noise.noise2D(xl + ox, yl + oy)
      n_xs_yl = noise.noise2D(xs + ox, yl + oy)
      n_xl_ys = noise.noise2D(xl + ox, ys + oy)
      n_xs_ys = noise.noise2D(xs + ox, ys + oy)

      faces.addComplexFace4(
        [xl, n_xl_ys, ys]
        [xs, n_xs_ys, ys]
        [xs, n_xs_yl, yl]
        [xl, n_xl_yl, yl]
        {
          vertexColors: [
            new THREE.Color(getColor(n_xl_ys))
            new THREE.Color(getColor(n_xs_ys))
            new THREE.Color(getColor(n_xs_yl))
            new THREE.Color(getColor(n_xl_yl))
          ]
        }
      )
  geometry = faces.generateGeometry()
  geometry.computeFaceNormals()
  console.log("Geometry generated in " + (new Date().getTime() - t) + 'ms')
  return geometry

comm = new WorkerComm(self, {
  init: ->
    console.log('init!')
    initGenerator()
  setSeed: (newSeed) ->
    setSeed = newSeed
    initGenerator()
  setNoise: (newDescription) ->
    description = newDescription

    initGenerator()
  test: (a, b) ->
    console.log('test!')
    return a + b
  geometry: generateGeometry
  geometry2: (size, tilesize) ->
    console.log('geo')
    t = new Date().getTime()
    geo = new THREE.Geometry()
    # faces = new FaceManager(500)
    for y in [0..size-1]
      for x in [0..size-1]
        n = noise.noise2D(x, y)
        geo.vertices.push new THREE.Vector3(x * tilesize, n, y * tilesize)
        if x > 0 and y > 0
          face1 = new THREE.Face3(getIndex(size, x, y), getIndex(size, x, y - 1), getIndex(size, x - 1, y))
          face2 = new THREE.Face3(getIndex(size, x, y - 1), getIndex(size, x - 1, y - 1), getIndex(size, x - 1, y))
          geo.faces.push(face1)
          geo.faces.push(face2)
          for face in [face1, face2]
            for vertexFaceIndex in [0..2]
              vertexIndex = face[['a', 'b', 'c'][vertexFaceIndex]]
              vertex = geo.vertices[vertexIndex]
              if vertex.y < 0
                color = new THREE.Color(0x0000ff)
              else
                color = new THREE.Color(0x00ff00)
              face.vertexColors[vertexFaceIndex] = color

    comm.console.log("Geometry generation finished in " + (new Date().getTime() - t) + "s")
    geo.computeFaceNormals()
    return geo
})
comm.ready()
comm.handleReady(->
  comm.console.log('uhh hey...')
  )
"""
terrainWorkerDeps = [
  'js/three.min.js'
  'js/seededrandom.js'
  'js/coffee-script.js'
  'js/worker-console.js'
  'js/simplex-noise.js'
  'worker-comm'
  'facemanager'
  'noisegenerator'
  # 'grid'
  #'worker-console'
]
terrainWorker = null

# now = -> new Date().getTime()

lib.load(
  'firstperson'
  'grid'
  'polygons'
  'queue'
  'now'
  'updater'
  'worker-comm'
  'webworkers'
  ->
    console.log('libs loaded')
    createTerrainWorker = ->
      worker = webworker.fromCoffee(terrainWorkerDeps, terrainWorkerCode)
      worker.onmessage = console.handleConsoleMessages('w1')
      worker = new WorkerComm(worker, {});
      worker.handleReady(->
        supersecret.Game.loaded = true
        worker.ready()
      )
      return worker
    terrainWorker = createTerrainWorker()
)

serializer = {
  db: {}
}

serializer.serialize = (name, obj) ->
  methods = serializer.db[name]
  return methods && methods.serialize(obj)
serializer.deserialize = (name, obj) ->
  methods = serializer.db[name]
  return methods && methods.deserialize(obj)
serializer.teach = (name, serialize, deserialize) ->
  serializer.db[name] =
    serialize: serialize
    deserialize: deserialize

identity = (o) -> o
serializer.teach('RawGeometry', identity, ((o) ->
  # geo = new THREE.Geometry()
  o.__proto__ = THREE.Geometry.prototype
  for p of o
    if p == 'vertices'
      for v in o.vertices
        v.__proto__ = THREE.Vector3.prototype
        #geo.vertices.push new THREE.Vector3(v.x, v.y, v.z)
    else if p == 'faces'
      for f in o.faces
        f.__proto__ = THREE.Face3.prototype
        # geo.faces.push face = new THREE.Face3(f.a, f.b, f.c)
        # face.normal = new THREE.Vector3(f.normal.x, f.normal.y, f.normal.z)
        f.normal.__proto__ = THREE.Vector3.prototype
        if f.vertexColors.length > 0
          for vertexColorIndex in [0..f.vertexColors.length-1]
            # color = new THREE.Color(0)
            c = f.vertexColors[vertexColorIndex]
            c.__proto__ = THREE.Color.prototype
            # color.setRGB(c.r, c.g, c.b)
            # face.vertexColors[vertexColorIndex] = color
    # else
    #   geo[p] = o[p]
  # return geo)
  return o)
)
serializer.teach('Geometry', identity, ((o) ->
  geo = new THREE.Geometry()
  for p of o
    if p == 'vertices'
      for v in o.vertices
        geo.vertices.push new THREE.Vector3(v.x, v.y, v.z)
    else if p == 'faces'
      for f in o.faces
        # f.__proto__ = THREE.Face3.prototype
        geo.faces.push face = new THREE.Face3(f.a, f.b, f.c)
        face.normal = new THREE.Vector3(f.normal.x, f.normal.y, f.normal.z)
        # f.normal.__proto__ = THREE.Vector3.prototype
        if f.vertexColors.length > 0
          for vertexColorIndex in [0..f.vertexColors.length-1]
            color = new THREE.Color(0)
            c = f.vertexColors[vertexColorIndex]
            # c.__proto__ = THREE.Color.prototype
            color.setRGB(c.r, c.g, c.b)
            face.vertexColors[vertexColorIndex] = color
    else
      geo[p] = o[p]
  return geo)
)

distance = (x1, y1, z1, x2, y2, z2) ->
  xd = x2 - x1
  yd = y2 - y1
  zd = z2 - z1
  return Math.sqrt(zd*zd + yd*yd + xd*xd)

spiral = (cx, cy, distance, f) ->
  x = y = 0
  dx = 0
  dy = -1
  for i in [0..distance]
    return if f(cx + x, cy + y) is false
    if x == y or (x < 0 and x == -y) or (x > 0 and x == 1-y)
      [dx, dy] = [-dy, dx]
    x += dx
    y += dy

class QuadTreeNode
  constructor: (parent, size, x, y) ->
    @parent = parent
    @size = size
    @offset =
      x: x
      y: y
    @hasChildren = false
    @children = [[undefined, undefined], [undefined, undefined]]
    @data = undefined

  forChild: (f) ->
    return if not @hasChildren
    for x in [0, 1]
      for y in [0, 1]
        if child = @children[x][y]
          f(child, x, y)
    return

  addChild: (x, y) ->
    if x < 0 or x > 1 or y < 0 or y > 1
      throw "Invalid child coordinate"
    @hasChildren = true
    px = @offset.x + @size / 2 * x
    py = @offset.y + @size / 2 * y
    return @children[x][y] = new QuadTreeNode(this, @size / 2, px, py)

  getChild: (x, y) ->
    return @children[x][y]



class QuadTreeGeometry
  constructor: (scene, size) ->
    @scene = scene
    @size = Math.pow(2, Math.ceil(Math.log(size) / Math.log(2)))
    @tree = new QuadTreeNode(null, @size, 0, 0)
    @growing = false
    @loading = 0
    @offset =
      x: 0
      y: 0
    @onmesh = null
    @shouldBreakpoint = false
    $(document).keydown((e) =>
      if e.keyCode == 66
        @shouldBreakpoint = true
    )
    @updater = new Updater(1000)

  growTree: (position) ->
    return if @loading > 10
    @updater.update('trees', 'Loading ' + @loading)
    DEBUG.breakpoint(@shouldBreakpoint)
    @shouldBreakpoint = false
    # console.log('GROWING ', @loading)

    queue = new Queue()
    queue.push(@tree)
    leaves = []
    while queue.length > 0
      node = queue.pop()
      continue if node.data is null
      if not node.hasChildren
        leaves.push node
      else
        node.forChild (child, x, y) ->
          if child.hasChildren
            queue.push(child)
          else
            leaves.push(child)

    for leaf in leaves
      return if @loading > 10
      d = distance(leaf.offset.x + leaf.size / 2, 64, leaf.offset.y + leaf.size / 2,
          position.x, position.y, position.z)

      s = Math.sqrt(leaf.size * leaf.size + leaf.size * leaf.size)

      levels = [
        [s*16, leaf.size / 2]
        # [s / 256, @size / 1024]
        # [s / 128, @size / 512]
        # [s / 64, @size / 256]
        # [s / 32, @size / 128]
        # [s / 16, @size / 64]
        # [s / 8, @size / 32]
        # [s / 4, @size / 16]
        # [s / 2, @size / 8]
        # [@size * 5 / 64, @size / 64]
        # [@size * 5 / 32, @size / 32]
        # [@size * 5 / 16, @size / 16]
        # [@size * 5 / 8, @size / 8]
        # [@size * 5 / 4, @size / 4]
        # [@size * 5 / 2, @size / 2]
        # [@size * 5, @size],
      ]

      # targetDensity = null
      # for [level, density] in levels
      #   if d - s < level
      #     targetDensity = density
      #     break
      # if leaf.parent
      #   return if not targetDensity?
      #   return if leaf.size <= targetDensity
      continue if d > s * 3 or leaf.size < @size / 1024

      console.log "Generating #{leaf.offset.x},#{leaf.offset.y}x#{leaf.size} @#{d} s#{leaf.size}"

      meshes = []
      for dx in [0, 1]
        for dy in [0, 1]
          child = leaf.addChild(dx, dy)
          child.data = null
          @loading++
          do (meshes, leaf, child) =>
            console.log('Requesting mesh for ' + child.offset.x + ', ' + child.offset.y + 'x' + child.size)
            terrainWorker.i.geometry([child.offset.x, child.offset.y], 16, child.size, (geometry) =>
              @loading--
              t = now()
              # console.log("got mesh... for chunk #{cx}, #{cy} @#{density}")
              console.log('Got mesh for ' + child.offset.x + ', ' + child.offset.y + 'x' + child.size)
              geometry = serializer.deserialize('RawGeometry', geometry)
              console.log('Geometry deserialized in ' + (now() - t) + 'ms')
              mesh = new THREE.Mesh(geometry,
                # new THREE.MeshNormalMaterial()
                new THREE.MeshLambertMaterial({
                  vertexColors: THREE.VertexColors
                })
              )
              child.data = mesh
              mesh.position.x = @offset.x + child.offset.x
              mesh.position.z = @offset.y + child.offset.y

              yv = 20
              # simpleFaces = new FaceManager(2)
              # simpleFaces.addFace4([0, yv, 0], [child.size, yv, 0], [child.size, yv, child.size], [0, yv, child.size], {
              #   vertexColors: [new THREE.Color(), new THREE.Color(), new THREE.Color(), new THREE.Color()]
              #   })
              gg = new THREE.Geometry()
              gg.vertices.push new THREE.Vector3(0, yv, 0)
              gg.vertices.push new THREE.Vector3(child.size, yv, 0)
              gg.vertices.push new THREE.Vector3(child.size, yv, child.size)
              gg.vertices.push new THREE.Vector3(0, yv, child.size)
              mm = new THREE.Line(gg, new THREE.LineBasicMaterial({color: 0xff0000}))
              mm.position.x = mesh.position.x
              mm.position.z = mesh.position.z
              @scene.add mm

              meshes.push mesh
              if meshes.length is 4
                if leaf.data
                  @scene.remove leaf.data
                  leaf.data = undefined
                for mesh in meshes
                  @scene.add mesh
            )

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  preinit: ->
    @chunksize = 2048
    @targetDensity = 32
    @meshes = new Grid(2, [Infinity, Infinity])
    console.log("PREINIT now")
    @loading = 0

  postinit: ->
    @camera.position.y = 500
    @person = new FirstPerson(container, @camera)
    @person.pitch = Math.PI / 4
    @person.updateCamera()
    @geometree = new QuadTreeGeometry(@scene, @chunksize)
    @setTransform('speed', parseFloat)
    @watch('speed', (v) =>
      @person.speed = v
    )
    @watch('noise', (v) =>
      return if not v
      # The format is as follows:
      # +#.#,#.#+#.#,#.#
      layers = []
      currentLayer = null
      currentNumber = null
      for char in v
        switch char
          when '+', '*'
            if currentNumber?
              currentLayer.multiplier = parseFloat(currentNumber)
              currentNumber = null
            if currentLayer
              layers.push currentLayer
            currentLayer = {}
            if char == '*'
              currentLayer.op = (a, b) -> a*((b+1)/2)
          when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.'
            if not currentNumber
              currentNumber = ''
            currentNumber += char
          when ','
            if currentNumber?
              currentLayer.scale = parseFloat(currentNumber)
              currentNumber = null
      if currentNumber?
        currentLayer.multiplier = parseFloat(currentNumber)
      layers.push currentLayer
      terrainWorker.call('setNoise', layers, ->)

    )

  generateChunk: (cx, cy) ->
    return false if @loading > 10
    yp = @camera.position.y
    chunkcenterx = cx * @chunksize + @chunksize / 2
    chunkcentery = cy * @chunksize + @chunksize / 2
    d = distance(@camera.position.x, @camera.position.y, @camera.position.z,
        chunkcenterx, 10, chunkcentery)

    levels = [
      [20, 1024]
      [30, 512]
      [40, 256]
      [50, 128]
      [100, 64]
      [200, 32]
      [400, 16]
      [800, 8]
      [1000, 4]
      [1600, 2]
    ]

    targetDensity = null
    for [level, density] in levels
      if d < level
        targetDensity = density
        break
    return if not targetDensity?


    # console.log(targetDensity)
    density = 1
    exists = @meshes.exists(cx, cy)
    if exists
      oldmesh = @meshes.get(cx, cy)
      if oldmesh
        [density, oldmesh, status] = oldmesh
        if density < targetDensity and not status
          density *= 2
        else if density > targetDensity and not status
          density = targetDensity
        else
          # console.log('density is fine...' + density, @targetDensity)
          return
      else
        return

    if not exists
      @meshes.set(null, cx, cy)
    else
      oldmesh = @meshes.get(cx, cy)
      [od, om, os] = oldmesh
      return if od >= density
      @meshes.set([od, om, true], cx, cy)
    @loading++
    console.log("requesting #{cx}, #{cy} @#{density}")
    terrainWorker.i.geometry([cx * @chunksize, cy * @chunksize], density, @chunksize, (rawgeo) =>
      @loading--
      t = now()
      console.log("got mesh... for chunk #{cx}, #{cy} @#{density}")
      geo = serializer.deserialize('RawGeometry', rawgeo)
      console.log('Geometry deserialized in ' + (now() - t) + 'ms')
      mesh = new THREE.Mesh(geo,
        # new THREE.MeshNormalMaterial()
        new THREE.MeshLambertMaterial({
          vertexColors: THREE.VertexColors
        })
      )
      mesh.position.x = cx * @chunksize
      mesh.position.z = cy * @chunksize
      oldmesh = @meshes.get(cx, cy)
      if oldmesh
        [olddensity, oldmesh, status] = oldmesh
        @scene.remove oldmesh
      @meshes.set([density, mesh, false], cx, cy)
      @scene.add mesh
    )


  initGeometry: ->
    @scene.add new THREE.Mesh(new THREE.SphereGeometry(1, 8, 8))
    terrainWorker.call('init', ->)
    #cubeGeometry = polygons.cube(1)
    #cubeGeometry.computeFaceNormals()
    #@scene.add new THREE.Mesh(
      #cubeGeometry
      #new THREE.MeshNormalMaterial()
      #new THREE.SphereGeometry(1, 16, 16),
       #new THREE.LineBasicMaterial({color: 0xff0000})
      #)

  randomDirectionalLight: ->
    light = new THREE.DirectionalLight(0xffffff, Math.random() * .4 + .4)
    light.position.y = Math.random() * .5 + .4
    light.position.x = Math.random() * 2 - 1
    light.position.z = Math.random() * 2 - 1
    return light

  initLights: ->
    @scene.add @randomDirectionalLight()
    @scene.add @randomDirectionalLight()

  update: (delta) ->
    if @camera.position.y != @lp
      @lp = @camera.position.y
      console.log(@camera.position.y)

    @geometree.growTree({
      x: @camera.position.x - @geometree.offset.x
      y: @camera.position.y
      z: @camera.position.z - @geometree.offset.y
    })

    # cx = Math.floor(@camera.position.x / @chunksize)
    # cy = Math.floor(@camera.position.z / @chunksize)
    # n = 30
    # spiral(cx, cy, 30, (x, y) =>
    #   @generateChunk(x, y)
    # )
    @person.update(delta)
