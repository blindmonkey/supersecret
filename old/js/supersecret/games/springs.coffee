lib.load(
  'firstperson'
  'polygons'
  -> supersecret.Game.loaded = true)

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
