require('geometry/facemanager')
require('util/map')

distance = (x, y, z) -> Math.sqrt(x*x + y*y + z*z)

getMidPoint = ([x1, y1, z1], [x2, y2, z2]) ->
  return [
    (x2 - x1) / 2 + x1
    (y2 - y1) / 2 + y1
    (z2 - z1) / 2 + z1
  ]

exports.polygons = {
  complexifyFace: (face, radius) ->
    getNewPosition = ([x, y, z]) ->
      d = distance(x, y, z)
      return [
        x / d * radius
        y / d * radius
        z / d * radius
      ]

    vertices = [face.a, face.b, face.c]
    for vertexIndex in [0..2]
      vertex = vertices[vertexIndex]
      #vertex = geometry.vertices[vertex]
      #vertex = [vertex.x, vertex.y, vertex.z]
      vertex = getNewPosition(vertex)
      vertices[vertexIndex] = vertex

    mid12 = getNewPosition(getMidPoint(vertices[0], vertices[1]))
    mid23 = getNewPosition(getMidPoint(vertices[1], vertices[2]))
    mid13 = getNewPosition(getMidPoint(vertices[0], vertices[2]))
    return [
      [vertices[0], mid12, mid13]
      [mid12, vertices[1], mid23]
      [mid12, mid23, mid13]
      [mid23, vertices[2], mid13]
    ]


  complexify: (geometry, radius) ->
    faceIsEmpty = (face) ->
      face.a == face.b == face.c

    getNewPosition = ([x, y, z]) ->
      d = distance(x, y, z)
      return [
        x / d * radius
        y / d * radius
        z / d * radius
      ]

    faces = new FaceManager(geometry.faces.length * 4 + 1)
    moved = new Map()
    console.log("Face count: #{geometry.faces.length}")
    for face in geometry.faces
      continue if faceIsEmpty(face)
      f = {
        a: geometry.vertices[face.a]
        b: geometry.vertices[face.b]
        c: geometry.vertices[face.c]
      }
      f.a = [f.a.x, f.a.y, f.a.z]
      f.b = [f.b.x, f.b.y, f.b.z]
      f.c = [f.c.x, f.c.y, f.c.z]

      newFaces = polygons.complexifyFace(f, radius)
      for f in newFaces
        faces.addFace(f...)
      # vertex1 = geometry.vertices[face.a]
      # vertex2 = geometry.vertices[face.b]
      # vertex3 = geometry.vertices[face.c]
      # vertex1 = [vertex1.x, vertex1.y, vertex1.z]
      # vertex2 = [vertex2.x, vertex2.y, vertex2.z]
      # vertex3 = [vertex3.x, vertex3.y, vertex3.z]
      # moved.put(vertex1, getNewPosition(vertex1)) if not moved.contains(vertex1)
      # moved.put(vertex2, getNewPosition(vertex2)) if not moved.contains(vertex2)
      # moved.put(vertex3, getNewPosition(vertex3)) if not moved.contains(vertex3)
      # vertex1 = moved.get(vertex1)
      # vertex2 = moved.get(vertex2)
      # vertex3 = moved.get(vertex3)
      # mid12 = getNewPosition(getMidPoint(vertex1, vertex2))
      # mid23 = getNewPosition(getMidPoint(vertex2, vertex3))
      # mid13 = getNewPosition(getMidPoint(vertex1, vertex3))

      # faces.addFace vertex1, mid12, mid13
      # faces.addFace mid12, vertex2, mid23
      # faces.addFace mid12, mid23, mid13
      # faces.addFace mid23, vertex3, mid13
    return faces.generateGeometry()

  cube: (size) ->
    faces = new FaceManager(12)
    addFace = (mainAxis, otherAxes, mainAxisValue) ->
      axes =
        x: 0
        y: 1
        z: 2
      vertices = [[-1,-1], [0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1], [-1,0]]
      for v in [0..vertices.length-1]
        n = (v+1) % vertices.length
        v1 = vertices[v]
        v2 = vertices[n]
        face = [[],[],[]]
        face[0][axes[mainAxis]] = mainAxisValue
        face[0][axes[otherAxes[0]]] = v1[0]
        face[0][axes[otherAxes[1]]] = v1[1]
        face[1][axes[mainAxis]] = mainAxisValue
        face[1][axes[otherAxes[0]]] = v2[0]
        face[1][axes[otherAxes[1]]] = v2[1]
        face[2][axes[mainAxis]] = mainAxisValue
        face[2][axes[otherAxes[0]]] = 0
        face[2][axes[otherAxes[1]]] = 0
        faces.addFace face...
    addFace('x', ['y', 'z'], 1)
    addFace('x', ['z', 'y'], -1)
    addFace('z', ['x', 'y'], 1)
    addFace('z', ['y', 'x'], -1)
    addFace('y', ['z', 'x'], 1)
    addFace('y', ['x', 'z'], -1)
    return faces.generateGeometry()

  sphere: (radius, iterations, optgeometry) ->
    iterations = iterations or 0
    geometry = optgeometry or polygons.cube(radius)
    while iterations-- > 0
      geometry = polygons.complexify(geometry, radius)
    return geometry
}
