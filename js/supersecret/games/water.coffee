class supersecret.Game extends supersecret.BaseGame
  constructor: (container, width, height) ->
    super(container, width, height)
    @person = new supersecret.FirstPerson(container, @camera)

  initGeometry: ->
    geometry = new THREE.Geometry()
    springs = []
    width = 20
    height = 20
    meshes = []
    for x in [0..width - 1]
      for y in [0..height - 1]
        xx = x * 8
        zz = y * 8
        @scene.add m = new THREE.Mesh(new THREE.SphereGeometry(1, 5, 5), new THREE.LineBasicMaterial({color: 0xff0000}))
        m.position.x = xx
        m.position.z = zz
        m.position.y = Math.random()
        meshes.push m
    for x in [0..width - 1]
      for y in [0..height - 1]
        mesh = meshes[x * width + y]
        if x < width - 1
          other = meshes[(x + 1) * width + y]
          springs.push {
            start:m.position
            end:other.position
            length:m.position.length(other.position)
          }
        if y < height - 1
          other = meshes[x * width + y + 1]
          springs.push {
            start:m.position
            end:other.position
            length:m.position.length(other.position)
          }



  render: (delta) ->
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)

