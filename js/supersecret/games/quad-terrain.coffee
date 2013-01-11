lib.load(
  'facemanager'
  'firstperson'
  'polygons'
  'queue'
  -> supersecret.Game.loaded = true
)

class QuadTree
  constructor: (generator, size, scale) ->
    @generator = generator
    @size = Math.pow(2, Math.round(Math.log(size) / Math.log(2)))
    @scale = scale
    @maxerror = 2
    @tree = null
  
  getHeights: (x, y, size) ->
    return [
      [@generator(x,        y), @generator(x,        y+size/2)]
      [@generator(x+size/2, y), @generator(x+size/2, y+size/2)]
    ]
  
  getAverageFromHeights: (heights) ->
    average = 0
    for x in [0..1]
      for y in [0..1]
        average += heights[x][y]
    return average / 4
  
  getAverage: (x, y, size) ->
    heights = @getHeights(x, y, size)
    return @getAverageFromHeights(heights)
  
  shouldSubdivideTree: (tree, maxdepth=1) ->
    return true if Math.abs(tree.center - tree.average) > @maxerror
    return false if maxdepth <= 0
    return true if shouldSubdivide(tree.x, tree.y, tree.size / 2, maxdepth-1)
    return true if shouldSubdivide(tree.x+tree.size / 2, tree.y, tree.size / 2, maxdepth-1)
    return true if shouldSubdivide(tree.x, tree.y+tree.size / 2, tree.size / 2, maxdepth-1)
    return true if shouldSubdivide(tree.x+tree.size / 2, tree.y+tree.size / 2, tree.size / 2, maxdepth-1)
    return false
  
  shouldSubdivide: (x, y, size, maxdepth=1) ->
    return @shouldSubdivideTree(@generateTree(x, y, size, 0), maxdepth)
  
  createTreeNode: (parent, x, y, size) ->
    tree = {
      x: x
      y: y
      size: size
      depth: 0
      heights: getHeights(x, y, size)
      center: @generator(x + size / 2, y + size / 2)
      parent: parent
    }
    tree.average = @getAverageFromHeights(tree.heights)
    return tree
  
  generateTree_: (parent, x, y, size, maxdepth=10) ->
    tree = @createTreeNode(parent, x, y, size)
    if maxdepth > 0 and @shouldSubdivideTree(tree)
      halfsize = size / 2
      tree.children = [[null, null], [null, null]]
      for xx in [0..1]
        for yy in [0..1]
          nx = x + halfsize * xx
          ny = y + halfsize * yy
          tree.children[xx][yy] = child = @generateTree_(tree, nx, ny, halfsize, maxdepth - 1)
          if child.depth > tree.depth - 1
            tree.depth = child.depth + 1
    return tree
  
  generateTree: (x, y, size, maxdepth=10) ->
    queue = new Queue()
    root = null
    queue.push [null, x, y, size, maxdepth, null]
    while queue.length > 0
      [parent, x, y, size, maxdepth, callback] = queue.pop()
      tree = @createTreeNode(parent, x, y, size)
      root = tree if not parent?
      if maxdepth > 0 and @shouldSubdivideTree(tree)
        halfsize = size / 2
        tree.children = [[null, null], [null, null]]
        for xx in [0..1]
          for yy in [0..1]
            nx = x + halfsize * xx
            ny = y + halfsize * yy
            tree.children[xx][yy] = child = @generateTree_(tree, nx, ny, halfsize, maxdepth - 1)
            if child.depth > tree.depth - 1
              tree.depth = child.depth + 1
    
  
  generateFaces_: (tree, maxdepth=10) ->
    
  
  

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)

  initGeometry: ->
    cubeGeometry = polygons.cube(1)
    cubeGeometry.computeFaceNormals()
    @scene.add new THREE.Mesh(
      cubeGeometry
      new THREE.MeshNormalMaterial()
      #new THREE.SphereGeometry(1, 16, 16),
      # new THREE.LineBasicMaterial({color: 0xff0000})
      )

  update: (delta) ->
    @person.update(delta)
