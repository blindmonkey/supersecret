lib.load(
  'facemanager'
  'firstperson'
  'polygons'
  'map'
  'set'
  -> supersecret.Game.loaded = true)

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)

  initGeometry: ->
    geometry = polygons.sphere(10, 5)
    geometry.computeFaceNormals()
    @scene.add new THREE.Mesh(geometry
      new THREE.MeshLambertMaterial({color: 0xff0000})
    )

  initLights: ->
    @scene.add new THREE.AmbientLight(0x505050)
    light = new THREE.DirectionalLight(0xffffff, .6)
    light.position.x = 1
    light.position.y = 1
    light.position.z = 0
    @scene.add light

  update: (delta) ->
    @person.update(delta)
