flipFaces = (faces...) ->
  newFaces = []
  for face in faces
    [a, c, b] = face
    newFaces.push [a, b, c]
  return newFaces

lib.export('CubeRenderer', class CubeRenderer
  @faces:
    front: [[[-0.5, -0.5, 0.5], [0.5, -0.5, 0.5], [0.5, 0.5, 0.5]]
            [[-0.5, -0.5, 0.5], [0.5, 0.5, 0.5], [-0.5, 0.5, 0.5]]]
    above: [[[-0.5, 0.5, -0.5], [0.5, 0.5, 0.5], [0.5, 0.5, -0.5]]
            [[-0.5, 0.5, -0.5], [-0.5, 0.5, 0.5], [0.5, 0.5, 0.5]]]
    right: [[[0.5, -0.5, -0.5], [0.5, 0.5, -0.5], [0.5, 0.5, 0.5]]
            [[0.5, -0.5, -0.5], [0.5, 0.5, 0.5], [0.5, -0.5, 0.5]]]

  @render: (neighbors) ->
    faces = []
    if neighbors[0] and not neighbors[1]
      faces.push(CubeRenderer.faces.front...)
    if not neighbors[0] and neighbors[1]
      faces.push(flipFaces(CubeRenderer.faces.front...)...)
    if neighbors[0] and not neighbors[2]
      faces.push(CubeRenderer.faces.above...)
    if not neighbors[0] and neighbors[2]
      faces.push(flipFaces(CubeRenderer.faces.above...)...)
    if neighbors[0] and not neighbors[4]
      faces.push(CubeRenderer.faces.right...)
    if not neighbors[0] and neighbors[4]
      faces.push(flipFaces(CubeRenderer.faces.right...)...)

    if faces.length
      return faces #[faces, undefined]
    return null
)
