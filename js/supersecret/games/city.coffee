lib.load('firstperson', ->
  supersecret.Game.loaded = true)

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false
  constructor: (container, width, height, opt_scene, opt_camera) ->
    params = getQueryParams()
    @viewAngle = parseFloat(params.viewAngle) or 90

    @size =
      width: 25
      height: 25

    super(container, width, height, opt_scene, opt_camera)

    @person = new FirstPerson(container, @camera)

  #initGrid: ->


  initGeometry: ->
    console.log('Initializing grid')
    geometry = new THREE.Geometry()
    for x in [0..@size.width]
      for y in [0..@size.height]
        if x < @size.width
          geometry.vertices.push new THREE.Vector3(x     - @size.width / 2, 0, y - @size.height / 2)
          geometry.vertices.push new THREE.Vector3(x + 1 - @size.width / 2, 0, y - @size.height / 2)
        if y < @size.height
          geometry.vertices.push new THREE.Vector3(x - @size.width / 2, 0, y     - @size.height / 2)
          geometry.vertices.push new THREE.Vector3(x - @size.width / 2, 0, y + 1 - @size.height / 2)
    console.log('done' + geometry.vertices.length)
    @scene.add new THREE.Line(geometry, new THREE.LineBasicMaterial({color: 0x00ff00}), THREE.LinePieces)
    #@initGrid()
    # @scene.add new THREE.Mesh(
    #   new THREE.SphereGeometry(1, 16, 16),
    #   new THREE.LineBasicMaterial({color: 0xff0000})
    #   )

  render: (delta) ->
    @person.update(delta)
    @renderer.renderer.render(@scene, @camera)
