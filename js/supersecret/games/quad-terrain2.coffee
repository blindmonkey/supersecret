lib.load(
  'facemanager'
  'firstperson'
  'polygons'
  -> supersecret.Game.loaded = true)

class QuadTree
  constructor: (generator, size, scale) ->
    @generator = generator
    @size = Math.pow(2, Math.round(Math.log(size) / Math.log(2)))
    @scale = scale

  forEachChild: (offset, size, f) ->
    [x, y] = offset
    f(offset, size / 2)
    f([x + size / 2, y], size / 2)
    f([x, y + size / 2], size / 2)
    f([x + size / 2, y + size / 2], size / 2)

  getCornerHeights: (offset, size) ->
    [x, y] = offset
    return [
      [@generator(x, y), @generator(x, y + size)],
      [@generator(x + size, y), @generator(x + size, y + size)]]

  shouldSubdivide: (offset, size) ->
    [x, y] = offset
    corners = @getCornerHeights(offset, size)
    avg = corners[0][0] + corners[1][0] + corners[0][1] + corners[1][1]
    midheight = @generator(x + size / 2, y + size / 2)
    return Math.abs(midheight - avg) > 5

  generateTree_: (offset, size, maxdepth) ->
    tree = {
      depth = 0
      heights: @getCornerHeights(offset, size)
    }
    return tree if maxdepth < 0
    if @shouldSubdivide(offset, size)
      [x, y] = offset
      tree.children = []
      tree.children.push [
        @generateTree_(offset, size),
        @generateTree_([x, y+size/2], size)]
      tree.children.push [
        @generateTree_([x+size/2, y], size),
        @generateTree_([x+size/2, y+size/2], size)]
      treedepth = 0
      for x in [0..1]
        for y in [0..1]
          child = tree.children[x][y]
          child.parent = tree
          treedepth = child.depth if child.depth > treedepth
      tree.depth = treedepth
    return tree

  generateTree: (maxdepth) ->
    @tree = @generateTree_([0, 0], @size, maxdepth)

  generateGeometry_: (faces, offset, size, maxdepth) ->
    [x, y] = offset

  generateGeometry: (maxdepth) ->
    faces = new FaceManager(500)
    @generateGeometry_(faces, [0, 0], @size, maxdepth)
    return faces.generateGeometry()





supersecret.Game = class QuadTerrainGame extends supersecret.BaseGame
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
