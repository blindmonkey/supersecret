require('geometry/facemanager')
require('util/grid')

getCornerArray = (getter, coords...) ->
  [x, y, z] = coords
  return [
    getter(x, y, z)
    getter(x, y, z + 1)
    getter(x, y + 1, z)
    getter(x, y + 1, z + 1)
    getter(x + 1, y, z)
    getter(x + 1, y, z + 1)
    getter(x + 1, y + 1, z)
    getter(x + 1, y + 1, z + 1)
  ]

arraysEqual = (array1, array2) ->
  return false if array1.length != array2.length
  for i in [0..array1.length - 1]
    return false if array1[i] != array2[i]
  return true

exports.VoxelRenderer = class VoxelRenderer
  constructor: (getter, voxelGridSize, scale, materials) ->
    @grid = new Grid(3, voxelGridSize)
    @scale = scale
    @materials = materials
    @faces = new FaceManager(500, materials)
    @getter = getter

  isValid: (x, y, z) ->
    0 <= x < @grid.size[0] and 0 <= y < @grid.size[1] and 0 <= z < @grid.size[2]

  isDirty: (x, y, z, renderer) ->
    return false if not @isValid(x, y, z)
    voxel = @grid.get(x, y, z)
    return true if not voxel
    neighbors = getCornerArray(@getter, x, y, z)
    return true if renderer and voxel.renderer != renderer
    return true if not arraysEqual(voxel.neighbors, neighbors)
    return false

  updateVoxel: (x, y, z, renderer, properties) ->
    if @isValid(x, y, z) and not @isDirty(x, y, z, renderer)
      # console.log('Voxel #{ x }, #{ y }, #{ z } didn\'t need an update')
      return
    if @isValid(x, y, z) and @grid.exists(x, y, z)
      voxel = @grid.get(x, y, z)

    if voxel and voxel.faces
      console.log('Removing faces!!!')
      facesToRemove = []
      for simpleFace in voxel.faces
        face =
          a: simpleFace[0]
          b: simpleFace[1]
          c: simpleFace[2]
        facesToRemove.push face
      @faces.removeFaces(facesToRemove...)

    neighbors = getCornerArray(@getter, x, y, z)
    # console.log(neighbors)
    for neighbor in neighbors
      if neighbor is undefined
        return

    data = renderer.render(neighbors)
    if data?
      #[faces, properties] = data
      faces = data
      cacheVoxel =
        neighbors: neighbors
        renderer: renderer
      realFaces = []
      for face in faces
        newFace = []
        for [fx, fy, fz] in face
          newFace.push [fx * @scale + x * @scale, fy * @scale + y * @scale, fz * @scale + z * @scale]
        #console.log(newFace)
        realFaces.push newFace
        @faces.addFace(newFace.concat([properties])...)
      cacheVoxel.faces = realFaces
      @grid.set(cacheVoxel, x, y, z)

  geometry: ->
    return @faces.generateGeometry()
