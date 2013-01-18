lib.load(
  'grid'
  'array-grid'
  'firstperson'
  'polygons'
  'math'
  'queue'
  'voxel/voxel-renderer'
  'voxel/renderers/cube'
  'voxel/worldgenerator'
  -> supersecret.Game.loaded = true)

NTreeNode = (dim) ->
  class TreeNode
    constructor: (parent, size, offset...) ->
      @parent = parent
      @size = size
      @offset = offset
      @removeChildren()
      @data = undefined

    removeChildren: ->
      @forChild (child) ->
        child.parent = undefined
      @children = (undefined for i in [1..Math.pow(2, dim)])
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

    getIndex: (coords...) ->
      s = 0
      for i in [1..coords.length]
        s += coords[i-1] * Math.pow(2, i-1)
      return s

    forChild: (f, allChildren) ->
      return if not @hasChildren
      for child in @children
        f(child) if child or allChildren

    addChild: (coords...) ->
      for coord in coords
        if coord < 0 or coord > 1
          throw "Invalid child coordinate #{coord}"
      @hasChildren = true
      p = []
      for i in [1..coords.length]
        p.push @offset[i-1] + @size / 2 * coords[i]
      @children[@getIndex(coords...)] = new TreeNode(this, @size/2, p...)

    getChild: (coords...) ->
      @children[@getIndex(coords...)]

OctTreeNode = NTreeNode(3)
tree = new OctTreeNode(null, 1024, 0, 0, 0)
debugger


supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  preinit: ->
    # @cubes = new CubeRenderer()
    @size = 64
    @generator = new WorldGenerator([64, 64, 64])
    @initGrid()
  postinit: ->
    @person = new FirstPerson(container, @camera)

  initGrid: ->
    console.log 'Init Grid'
    @grid = new Grid(3, [@size, @size, @size])
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
    console.log('Init geometry', @grid.get(0,0,0))
    geometry = @vrenderer.geometry()
    console.log(geometry.vertices.length)
    @scene.add new THREE.Mesh(geometry)


  update: (delta) ->
    @person.update(delta)
