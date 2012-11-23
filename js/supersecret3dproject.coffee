# Game = p.require('Game')
# PipeGame = p.require('PipeGame')
# VoxelGame = p.require('VoxelGame')
# WorldGame = p.require('WorldGame')
# TerrainGame = p.require('TerrainGame')
# DnaGame = p.require('DnaGame')
# HexGame = p.require('HexGame')
# LinePhysics = p.require('LinePhysics')
# FirstPerson = p.require('FirstPerson')
# HexagonGame = p.require('HexagonGame')

window.init = (exposeDebug) ->
  $container = $('#container')
  #WIDTH = screen.availWidth#800
  #HEIGHT = screen.availHeight
  WIDTH = window.innerWidth
  HEIGHT = window.innerHeight
  console.log(WIDTH, HEIGHT)

  # games =
  #   voxels: VoxelGame
  #   world: WorldGame
  #   test: Game
  #   pipes: PipeGame
  #   terrain: TerrainGame
  #   dna: DnaGame
  #   hex: HexGame
  #   hexagon: HexagonGame
  #   lines: LinePhysics

  # params = getQueryParams()

  loadGame = ->
    console.log('Game loaded!')
    game = new supersecret.Game($container, WIDTH, HEIGHT)
    console.log("Game created! Starting!")
    game.start()

  waitForLoad = ->
    if supersecret.Game
      loadGame()
    else
      setTimeout(waitForLoad, 100)
  waitForLoad()

  # GameClass = games[params.game or 'voxels']

  # game = new GameClass($container, WIDTH, HEIGHT)
  # game.start()

  #person = new FirstPerson(camera)
  ###
  $(document).keydown((e) ->
    console.log 'down!!' + e.keyCode
    if e.keyCode in keys.UP
      console.log(camera.rotation.y)
      person.walkForward(75)
    else if e.keyCode == keys.RISE
      console.log 'RISE!'
      camera.position.y += 10
  )
  ###
  #controls = new THREE.FirstPersonControls(camera)

