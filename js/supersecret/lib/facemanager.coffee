lib.export('FaceManager', class supersecret.FaceManager
  constructor: ->
    @faces = []
    @vectors = []
    @vectorIndex = {}
    @faceIndex = {}

  getVectorId: (v) ->
    if v instanceof Array
      if v.length != 3
        throw "invalid vector"
      return v.join('/')
    return v.x + '/' + v.y + '/' + v.z

  getFaceId: (f) ->
    va = @getVectorId(f.a)
    vb = @getVectorId(f.b)
    vc = @getVectorId(f.c)
    return va + '|' + vb + '|' + vc

  addVector: (v) ->
    vectorId = @getVectorId(v)
    if v instanceof Array
      v = new THREE.Vector3(v...)
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

  addFace: (a, b, c, doubleSided) ->
    [aId, bId, cId] = (@getVectorId(v) for v in [a, b, c])
    face = {
      a: a
      b: b
      c: c
    }
    faceId = @getFaceId(face)
    if faceId not of @faceIndex
      @faces.push @processFace(face)
      @faceIndex[faceId] = face
    if doubleSided
      @addFace(a, c, b)

  addFaces: (faces) ->
    @addFace(face.a, face.b, face.c) for face in faces

  generateGeometry: ->
    geometry = new THREE.Geometry()
    for vector in @vectors
      geometry.vertices.push vector
    for face in @faces
      geometry.faces.push new THREE.Face3(face.aIndex, face.bIndex, face.cIndex)
    return geometry
)
