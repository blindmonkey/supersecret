require('three/base')
require('firstperson')
require('three/three.min.js')
# require('polygons')

exports.Game = class NewGame extends BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)

  initGeometry: ->
    # cubeGeometry = polygons.cube(1)
    # cubeGeometry.computeFaceNormals()
    @scene.add new THREE.Mesh(
      # cubeGeometry
      new THREE.SphereGeometry(1, 8, 8)
      new THREE.MeshNormalMaterial()
      #new THREE.SphereGeometry(1, 16, 16),
      # new THREE.LineBasicMaterial({color: 0xff0000})
      )

  update: (delta) ->
    @person.update(delta)
