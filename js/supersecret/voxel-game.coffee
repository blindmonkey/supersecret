Renderer = p.require('Renderer')
FirstPerson = p.require('FirstPerson')
BaseGame = p.require('BaseGame')

class VoxelGame extends BaseGame
  constructor: (container, width, height, opt_scene, opt_camera) ->
    #super(container, width, height, opt_scene, opt_camera)
    console.log @camera