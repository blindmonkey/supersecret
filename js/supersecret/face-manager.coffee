class supersecret.FaceManager
  constructor: ->
    @faces = []
    @vectors = []
    @vectorIndex = {}

  getVectorId: (v) ->
    return v.x + '/' + v.y + '/' + v.z

  addVector: (v) ->
    vectorId = @getVectorId(v)
    if vectorId not of @vectorIndex
      @vectorIndex[vectorId] = @vectors.length
      @vectors.push(v)
    return @vectorIndex[vectorId]

  clearAndRecreateVectorIndex: ->
    @processFace(face) for face in @faces

  processFace: (face) ->
    [a, b, c] = (@addVector(v) for v in [face.a, face.b, face.c])
    face.aIndex = a
    face.bIndex = b
    face.cIndex = c
    return face

  addFace: (a, b, c) ->
    [aId, bId, cId] = (@getVectorId(v) for v in [a, b, c])
    @faces.push @processFace({
      a: a
      b: b
      c: c
    })

  addFaces: (faces) ->
    @addFace(face.a, face.b, face.c) for face in faces

  createGeometry: ->
    geometry = new THREE.Geometry()
    for vector in @vectors
      geometry.vertices.push vector
    for face in @faces
      geometry.faces.push new THREE.Face3(face.aIndex, face.bIndex, face.cIndex)
    return geometry
