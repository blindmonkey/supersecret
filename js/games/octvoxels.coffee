require('core/events')
require('firstperson')
require('geometry/facemanager')
require('geometry/polygons')
require('math')
require('three/base')
require('three/three.min.js')
require('time/updater')
require('util/array-grid')
require('util/grid')
require('util/ntree')
require('util/queue')
require('voxels/generator')
require('voxels/renderer')
require('voxels/renderers/cube')
require('webworkers')
require('workers/comm')
require('workers/console.js')


class MeshWorker extends Events
  @deps: [
    # 'js/lib/three/three.min.js'
    'js/coffee-script.js'
    'js/lib/workers/console.js'
    'js/loader.js'
  ]

  @code: """
    hostre = /^(.+:\\/\\/.+?)(\\/.*)$/
    m = baseURL.match(hostre)
    lib.init(m[1], '/js/lib/')
    comm = null

    geometry = {
      id: 0
      geometries: {}
      start: (request) ->
        id = geometry.id++
        geometry.geometries[id] = []
        comm.i.startGeometry(id, request)
      send: (handle, faces...) ->
        for face in faces
          geometry.geometries[handle].push face
        if geometry.geometries[handle].length > 100
          geometry.send_ handle
      send_: (handle) ->
        comm.i.sendGeometry handle, geometry.geometries[handle]...
        geometry.geometries[handle] = []
      finish: (handle) ->
        geometry.send_ handle
        comm.i.finishGeometry handle
      discard: (handle) ->
        comm.i.discardGeometry handle
    }

    loaded = (e) ->
      console.log('Things were loaded!')
      comm = new e.WorkerComm(self, {
        hi: ->
          console.log('hi was called!')
          return 2
      })
      comm.ready()

    lib.load(
      'three/three.min.js'
      'workers/comm'
      loaded
    )
  """

  constructor: ->
    super()
    @worker = webworker.fromCoffee(MeshWorker.deps, MeshWorker.code)
    @worker.onmessage = console.handleConsoleMessages('w1')
    @requestId = 0
    @geometries = {}
    @callbacks = {}
    @comm = new WorkerComm(@worker, {
      startGeometry: (handle) ->
        @geometries[handle] = new FaceManager(500)
      sendGeometry: (handle, faces...) ->
        for face in faces
          @geometries.addFace face...
      finishGeometry: (handle) ->
        @callbacks[handle](@geometries[handle].generateGeometry())
        @discardGeometry handle
      discardGeometry: (handle) ->
        delete @geometries[handle]
        delete @callbacks[handle]
    })
    @comm.handleReady =>
      @comm.ready()
      @fireEvent('ready')

  requestGeometry: ()

  ready: ->
    return @comm.isReady







# OctTreeNode = NTreeNode(3)
# tree = new OctTreeNode(null, 1024, 0, 0, 0)


exports.Game = class NewGame extends BaseGame
  @loaded: false

  preinit: ->
    # @cubes = new CubeRenderer()
    @size = 64
    @generator = new WorldGenerator([16, 16, 16])
    @updater = new Updater(1000)
    @meshWorker = new MeshWorker()
    # @initGrid()
  postinit: ->
    @person = new FirstPerson(container, @camera)

  initGrid: ->
    console.log 'Init Grid'
    @grid = new ArrayGrid(3, [@size, @size, @size])
    @vrenderer = new VoxelRenderer(
      ((x, y, z) =>
        if x < 0 or x >= @size[0] or y < 0 or y >= @size[1] or z < 0 or z >= @size[2]
          return undefined
        return @grid.get(x, y, z) #!= null
      ), @grid.size, 10)
    for x in [1..@size-1]
      for y in [1..@size-1]
        for z in [1..@size-1]
          if @generator.getVoxel(x, y, z)
            @grid.set true, x-1, y-1, z-1
          else
            @grid.set false, x-1, y-1, z-1
          if x > 0 and y > 0 and z > 0
            # console.log('doing it')
            @vrenderer.updateVoxel(x-2, y-2, z-2, CubeRenderer)

  initGeometry: ->
    @scene.add new THREE.Mesh(new THREE.SphereGeometry(1, 4, 4))

    # console.log('Init geometry', @grid.get(0,0,0))
    # geometry = @vrenderer.geometry()
    # geometry.computeFaceNormals()
    # console.log(geometry.vertices.length)
    # @scene.add new THREE.Mesh(geometry, new THREE.MeshNormalMaterial())


  update: (delta) ->
    if @meshWorker.ready()
      @updater.update('worker', 'ready and willing')
    @updater.update('update', @camera.position)
    @person.update(delta)
