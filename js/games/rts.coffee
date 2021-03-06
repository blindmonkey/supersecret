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
getNoise = null
initGenerator = ->
  # Math.seedrandom(seed)
  console.log('Reinitializing noise with ', description)
  noise = new NoiseGenerator(
    new SimplexNoise(Math.random), description)
  noise2 = new NoiseGenerator(
    new SimplexNoise(Math.random), description)
  noise3 = new SimplexNoise(Math.random)
  getNoise = cached((x, y) ->
    n1 = noise.noise2D(x, y)
    n2 = noise2.noise2D(x, y)
    n3 = (noise3.noise2D(x, y) + 1) / 2
    return (n2 - n1) * n3 + n1
  )
  console.log('Noise initialized')

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
  maxHeight: ->
    return noise.getMaxValue()
  getHeight: (x, y) ->
    noise.noise2D(x, y)
  test: (a, b) ->
    console.log('test!')
    return a + b
  geometry: generateGeometry
})
comm.ready()
comm.handleReady(->
  comm.console.log('uhh hey...')
  )
"""
terrainWorkerDeps = [
  'js/lib/three/three.min.js'
  'js/lib/random/seededrandom.js'
  'js/coffee-script.js'
  'js/workers/console.js'
  'js/lib/simplex.js'
  'js/lib/util/cache'
  'js/lib/workers/comm'
  'facemanager'
  'noisegenerator'
  # 'grid'
  #'worker-console'
]
terrainWorker = null

# now = -> new Date().getTime()

# lib.load(
#   'firstperson'
#   'grid'
#   'polygons'
#   'queue'
#   'now'
#   'updater'
#   'worker-comm'
#   'webworkers'
#   ->
#     console.log('libs loaded')
#     createTerrainWorker = ->
#       worker = webworker.fromCoffee(terrainWorkerDeps, terrainWorkerCode)
#       worker.onmessage = console.handleConsoleMessages('w1')
#       worker = new WorkerComm(worker, {});
#       worker.handleReady(->
#         supersecret.Game.loaded = true
#         worker.ready()
#       )
#       return worker
#     terrainWorker = createTerrainWorker()
# )

require('three/three.min.js')
require('three/base')
require('firstperson');
require('util/grid');
require('geometry/polygons');
require('util/queue');
require('time/now');
require('time/updater');
require('workers/comm');
require('geometry/facemanager');
require('noisegenerator')
require('webworkers')
require('workers/console.js')

serializer = {
  db: {}
}

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

distance = (p1, p2) ->
  if p1.length != p2.length
    throw 'Error: both vectors must match in size.'
  s = 0
  for i in [0..p1.length-1]
    diff = p2[i] - p1[i]
    s += diff*diff
  return Math.sqrt(s)

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
    @removeChildren()
    @data = undefined

  childrenLoaded: ->
    return true if not @hasChildren
    for dx in [0,1]
      for dy in [0,1]
        if not @children[dx][dy].loaded
          return false
    return true

  removeChildren: ->
    @forChild (child) ->
      child.parent = undefined
    @children = [[undefined, undefined], [undefined, undefined]]
    @hasChildren = false

  forEveryChild: (f) ->
    queue = new Queue()
    queue.push this
    while queue.length > 0
      node = queue.pop()
      node.forChild (child) ->
        queue.push child
      if node isnt this
        return if f(node) is false

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


divideThreshold = 2
shouldDivideNode = (node, position, maxheight=0) =>
  # console.log position
  d = distance([node.offset.x + node.size / 2, maxheight / 2, node.offset.y + node.size / 2],
      [position.x, position.y, position.z])
  s = Math.sqrt(node.size * node.size + node.size * node.size)
  return d < s * divideThreshold

# class GeometryGenerator
#   @requestGeometry: (scene, node, callback) ->



class QuadTreeGeometry
  @quadsEnabled: false
  @density: 4
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
    @quads = []
    @stopped = false
    @updater = new Updater(5000)
    @maxheight = null

  @enableQuadTree: ->
    return if QuadTreeGeometry.quadsEnabled
    console.log('Enabling quads')
    QuadTreeGeometry.quadsEnabled = true
  @disableQuadTree: ->
    return if not QuadTreeGeometry.quadsEnabled
    console.log('Disabling quads')
    QuadTreeGeometry.quadsEnabled = false
    for quad in @quads
      @scene.remove quad


  updateQuads: ->
    queue = new Queue()
    queue.push @tree
    while queue.length > 0
      node = queue.pop()
      if QuadTreeGeometry.showQuads
        @scene.add node.quad if node.quad

  cleanup: ->
    @stopped = true
    queue = new Queue()
    queue.push @tree
    while queue.length > 0
      node = queue.pop()
      @scene.remove node.mesh if node.mesh
      @scene.remove node.quad if node.quad
      node.forChild (child, x, y) ->
        queue.push child

  growTree: (position) ->
    return if @loading > 10
    @updater.update('trees', 'Loading ' + @loading)
    DEBUG.breakpoint(@shouldBreakpoint)
    @shouldBreakpoint = false
    # console.log('GROWING ', @loading)

    shouldUndivideNode = (node) =>
      d = distance([node.offset.x + node.size / 2, @maxheight / 2, node.offset.y + node.size / 2],
          [position.x, position.y, position.z])
      s = Math.sqrt(node.size * node.size + node.size * node.size)
      return d > s * s

    requestGeometry = (node, callback) =>
      @loading++
      console.log('Requesting mesh for ' + node.offset.x + ', ' + node.offset.y + 'x' + node.size)
      terrainWorker.i.geometry([node.offset.x + @offset.x, node.offset.y + @offset.y], QuadTreeGeometry.density, node.size, (geometry) =>
        @loading--
        return if @stopped
        t = now()
        # console.log("got mesh... for chunk #{cx}, #{cy} @#{density}")
        console.log('Got mesh for ' + node.offset.x + ', ' + node.offset.y + 'x' + node.size)
        geometry = serializer.deserialize('RawGeometry', geometry)
        console.log('Geometry deserialized in ' + (now() - t) + 'ms')
        mesh = new THREE.Mesh(geometry,
          # new THREE.MeshNormalMaterial()
          new THREE.MeshLambertMaterial({
            vertexColors: THREE.VertexColors
          })
        )
        node.mesh = mesh
        mesh.position.x = @offset.x + node.offset.x
        mesh.position.z = @offset.y + node.offset.y
        callback(mesh)
      )


    # shouldDivideNode = (node) =>
    #   d = distance([node.offset.x + node.size / 2, @maxheight / 2, node.offset.y + node.size / 2],
    #       [position.x, position.y, position.z])
    #   s = Math.sqrt(node.size * node.size + node.size * node.size)
    #   return d < s

    createQuad = (node) =>
      yv = @maxHeight
      gg = new THREE.Geometry()
      gg.vertices.push new THREE.Vector3(0, yv, 0)
      gg.vertices.push new THREE.Vector3(node.size, yv, 0)
      gg.vertices.push new THREE.Vector3(node.size, yv, node.size)
      gg.vertices.push new THREE.Vector3(0, yv, node.size)
      gg.vertices.push new THREE.Vector3(0, yv, 0)
      mm = new THREE.Line(gg, new THREE.LineBasicMaterial({color: 0xff0000, linewidth:4}))
      mm.position.x = @offset.x + node.offset.x
      mm.position.z = @offset.y + node.offset.y
      return mm


    queue = new Queue()
    queue.push(@tree)
    leaves = []
    unloadNodes = []
    while queue.length > 0
      node = queue.pop()
      continue if node.loading or node.parent is undefined

      doDivide = shouldDivideNode(node, position)
      # if node.quad
      #   if doDivide
      #     node.quad.material.color = new THREE.Color(0x00ff00)
      #     node.quad.material.linewidth = 4
      #   else
      #     node.quad.material.color = new THREE.Color(0xff0000)
      #     node.quad.material.linewidth = 2
      #     node.quad.materialNeedsUpdate = true
      divideAnyChildren = {v:false}
      if node.hasChildren
        node.forEveryChild (child) =>
          if child.hasChildren or shouldDivideNode(child, position) or child.loading
            divideAnyChildren.v = true
            return false
      # else
      #   divideAnyChildren.v = true
      divideAnyChildren = divideAnyChildren.v

      if node.hasChildren and node.parent and not doDivide and not divideAnyChildren
        # node.quad and node.quad.material.color = new THREE.Color(0xffffff)
        # continue
        unloadNodes.push node
        # leaves.push node
        # @scene.remove node.mesh if node.mesh
        # @scene.remove node.quad if node.quad
      else if node.hasChildren #and doDivide
        node.forChild (child, x, y) ->
          return if child.loading or child.parent is undefined #or not shouldDivideNode(child)
          if child.hasChildren
            queue.push(child)
          else
            leaves.push(child)
      else if not node.hasChildren and doDivide and (not node.parent or shouldDivideNode(node.parent, position))
        leaves.push node

    leaves.sort (a, b) ->
      anx = a.offset.x + a.size / 2
      any = a.offset.y + a.size / 2
      bnx = b.offset.x + b.size / 2
      bny = b.offset.y + b.size / 2
      return distance([position.x, position.z], [anx, any]) - distance([position.x, position.z], [bnx, bny])

    for leaf in leaves
      continue if @loading > 10 or leaf.loading or leaf.parent is undefined
      continue if leaf.size < @size / 4096
      continue if not shouldDivideNode(leaf, position) and not leaf.force

      console.log "Generating #{leaf.offset.x},#{leaf.offset.y}x#{leaf.size} s#{leaf.size}"

      meshes = []
      for dx in [0, 1]
        for dy in [0, 1]
          child = leaf.addChild(dx, dy)
          continue if child.loading or leaf.loading or leaf.parent is undefined
          child.loading = true
          do (meshes, leaf, child) =>
            requestGeometry(child, (mesh) =>
              return if child.parent is undefined
              return if child.parent and child.parent.loading
              return if not child.loading
              child.loading = false
              # simpleFaces = new FaceManager(2)
              # simpleFaces.addFace4([0, yv, 0], [child.size, yv, 0], [child.size, yv, child.size], [0, yv, child.size], {
              #   vertexColors: [new THREE.Color(), new THREE.Color(), new THREE.Color(), new THREE.Color()]
              #   })
              mm = createQuad(child)
              child.quad = mm
              if QuadTreeGeometry.quadsEnabled
                console.log('Adding quad')
                @scene.add mm

              meshes.push [child, mesh]
              if meshes.length is 4
                if leaf.mesh
                  @scene.remove leaf.mesh
                  leaf.mesh = undefined
                for [node, mesh] in meshes
                  @scene.remove node.mesh if node.mesh
                  node.mesh = mesh
                  @scene.add mesh
            )
    for node in unloadNodes
      console.log('============= REMOVING', node.offset.x, node.offset.y, node.size)
      node.loading = true
      do (node) =>
        requestGeometry(node, (mesh) =>
          if node.parent is undefined
            console.log('Geometry ignored because of missing parent')
            return
          if node.parent and node.parent.loading
            console.log('Geometry ignored because parent is loading')
            return
          if not node.loading
            console.log('Geometry ignored because node is not loading')
          node.loading = false
          node.forEveryChild (child) =>
            child.loading = false
            @scene.remove child.mesh if child.mesh
            @scene.remove child.quad if child.quad
            # child.removeChildren()
          node.removeChildren()
          @scene.remove node.mesh if node.mesh
          # @scene.remove node.quad if node.quad
          node.mesh = mesh
          mesh.position.x
          @scene.add mesh
        )




exports.Game = class NewGame extends BaseGame
  @loaded: false

  preinit: ->
    @chunksize = 4096
    @targetDensity = 32
    @chunks = new Grid(2, [Infinity, Infinity])

    console.log("PREINIT now")

  postinit: ->
    @camera.position.y = 500
    @person = new FirstPerson(container, @camera)
    @person.pitch = Math.PI / 4
    @person.updateCamera()
    @geometree = new QuadTreeGeometry(@scene, @chunksize)
    @setTransform('speed', parseFloat)
    @watch('speed', (v) =>
      @person.speed = v or 10
    )
    @setTransform('quads', (v) ->
      if v == 'true' or v == '1' or v == 'y' or v == 'yes' or v == 't'
        return true
      return false
    )
    @watch('quads', (v) =>
      if v
        QuadTreeGeometry.enableQuadTree()
      else
        QuadTreeGeometry.disableQuadTree()
    )
    @setTransform 'divide', parseFloat
    @watch 'divide', (v) =>
      divideThreshold = v or 1
    @setTransform 'density', parseInt
    @watch 'density', (v) =>
      QuadTreeGeometry.density = v or 4
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
      @geometree.cleanup()
      @geometree = new QuadTreeGeometry(@scene, @chunksize)
      terrainWorker.call('setNoise', layers, ->)
      terrainWorker.i.maxHeight (v) =>
        @geometree.maxHeight = v

    )

  generateChunk: (cx, cy) ->
    throw "NEVER AGAIN"
    return false if @loading > 10
    yp = @camera.position.y
    chunkcenterx = cx * @chunksize + @chunksize / 2
    chunkcentery = cy * @chunksize + @chunksize / 2
    d = distance([@camera.position.x, @camera.position.y, @camera.position.z],
        [chunkcenterx, 10, chunkcentery])

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
    terrainWorker.i.maxHeight (v) =>
      @geometree.maxheight = v
      console.log('Max height is ' + v)
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

    cx = Math.floor(@camera.position.x / @chunksize)
    cy = Math.floor(@camera.position.z / @chunksize)
    for dx in [-1..1]
      for dy in [-1..1]
        ox = (cx + dx) * @chunksize
        oy = (cy + dy) * @chunksize
        # position = {
        #   x: @camera.position.x - ox
        #   y: @camera.position.y
        #   z: @camera.position.z - oy
        # }
        # doDivide = shouldDivideNode({
        #   offset: {x: ox, y: oy}
        #   size: @chunksize
        # }, position)
        if not @chunks.exists(cx + dx, cy + dy) #and doDivide
          chunk = new QuadTreeGeometry(@scene, @chunksize)
          chunk.offset.x = ox
          chunk.offset.y = oy
          @chunks.set(chunk, cx + dx, cy + dy)

    @chunks.forEachChunk (coords...) =>
      chunk = @chunks.get(coords...)
      position = {
        x: @camera.position.x - chunk.offset.x
        y: @camera.position.y
        z: @camera.position.z - chunk.offset.y
      }
      if shouldDivideNode(chunk.tree, position)
        chunk.growTree(position)
      else
        chunk.cleanup()
        @chunks.remove(coords...)

    # @geometree.growTree({
    #   x: @camera.position.x - @geometree.offset.x
    #   y: @camera.position.y
    #   z: @camera.position.z - @geometree.offset.y
    # })

    # cx = Math.floor(@camera.position.x / @chunksize)
    # cy = Math.floor(@camera.position.z / @chunksize)
    # n = 30
    # spiral(cx, cy, 30, (x, y) =>
    #   @generateChunk(x, y)
    # )
    @person.update(delta)

window.delayLoad = true
terrainWorker.handleReady(->
  console.log('ready');
  window.delayLoad = false
)
