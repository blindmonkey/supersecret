lib.load('firstperson', ->
  supersecret.Game.loaded = true)

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false
  constructor: (container, width, height, opt_scene, opt_camera) ->
    params = getQueryParams()
    @viewAngle = parseFloat(params.viewAngle) or 90

    super(container, width, height, opt_scene, opt_camera)

    @person = new FirstPerson(container, @camera)

  initGeometry: ->
    @scene.add new THREE.Mesh(
      new THREE.SphereGeometry(1, 16, 16),
      new THREE.LineBasicMaterial({color: 0xff0000})
      )

  render: (delta) ->
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)
