lib.load('set', ->)

lib.export('FaceManager', class supersecret.FaceManager
  constructor: (faceBufferCount, materials) ->
    @faceBufferCount = faceBufferCount || 100
    @materials = materials
    @faces = []
    @vectors = []
    @vectorIndex = {}
    @faceIndex = {}
    @facePool = null
    @nullFace = new THREE.Face3(0, 0, 0)
    @mesh = new THREE.Mesh()
    @regenerateGeometry()
    @addVector([0, 0, 0])

  regenerateGeometry: ->
    newGeometry = new THREE.Geometry()
    if @materials
      newGeometry.materials = @materials
    newGeometry.dynamic = true
    @facePool = new Set()
    offset = if @geometry then @geometry.faces.length else 0
    if @geometry
      newGeometry.vertices = @geometry.vertices
      newGeometry.faces = @geometry.faces
    for i in [1..@faceBufferCount]
      newGeometry.faces.push @nullFace
      @faces.push null
      @facePool.add(i - 1 + offset)
    @geometry = newGeometry


  getVectorId: (v) ->
    if v instanceof Array
      if v.length != 3
        throw "invalid vector"
      return v.join('/')
    return v.x + '/' + v.y + '/' + v.z

  updateFaceIndex: ->
    console.log('Regenerating face index')
    if @geometry
      @geometry.faces = []
    for faceIndex of @faces
      face = @faces[faceIndex]
      faceId = @getFaceId(face)
      @faceIndex[faceId] = @processFace(face)
      if @geometry
        @geometry.faces.push @makeFace3(face)

  removeFaces: (faces...) ->
    for face in faces
      faceId = @getFaceId(face)
      index = @faceIndex[faceId]
      delete @faceIndex[faceId]
      @faces[index] = null
      @geometry.faces[index] = @nullFace

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
      if @geometry
        @geometry.vertices.push v
        @geometry.verticesNeedUpdate = true
    return @vectorIndex[vectorId]

  hasVector: (v) ->
    vectorId = @getVectorId(v)
    return vectorId of @vectorIndex

  clearAndRecreateVectorIndex: ->
    @processFace(face) for face in @faces

  processFace: (face) ->
    [a, b, c] = (@addVector(v) for v in [face.a, face.b, face.c])
    face.aIndex = a
    face.bIndex = b
    face.cIndex = c
    return face

  makeFace3: (face) ->
    f = new THREE.Face3(face.aIndex, face.bIndex, face.cIndex,
        face.normal,
        face.color,
        face.materialIndex)
    if face.vertexColors
      f.vertexColors = (i for i in face.vertexColors)
    return f

  addFace: (a, b, c, properties, doubleSided) ->
    [aId, bId, cId] = (@getVectorId(v) for v in [a, b, c])
    face = {
      a: a
      b: b
      c: c
      normal: properties and properties.normal
      color: (properties and properties.color and new THREE.Color(properties.color)) or undefined
      materialIndex: properties and properties.materialIndex
      vertexColors: (properties and properties.vertexColors) or undefined
    }
    faceId = @getFaceId(face)
    if faceId not of @faceIndex
      if @facePool.length == 0
        @regenerateGeometry()
      emptyFaceIndex = @facePool.pop()
      @faces[emptyFaceIndex] = @processFace(face)
      @faceIndex[faceId] = emptyFaceIndex
      @geometry.faces[emptyFaceIndex] = @makeFace3(face)
      @geometry.verticesNeedUpdate = true
      @geometry.elementsNeedUpdate = true
      @geometry.facesNeedUpdate = true
    if doubleSided
      @addFace(a, c, b)

  addFaces: (faces) ->
    @addFace(face.a, face.b, face.c) for face in faces

  generateGeometry: ->
    return @geometry
    @geometry = new THREE.Geometry()
    @geometry.dynamic = true
    for vector in @vectors
      @geometry.vertices.push vector
    for face in @faces
      @geometry.faces.push @makeFace3(face)
    return @geometry
)
