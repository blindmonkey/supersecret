Game = p.require('Game')
PipeGame = p.require('PipeGame')
VoxelGame = p.require('VoxelGame')
WorldGame = p.require('WorldGame')
TerrainGame = p.require('TerrainGame')
DnaGame = p.require('DnaGame')
FirstPerson = p.require('FirstPerson')

getQueryParams = ->
  query = window.location.href.split('?').splice(1).join('?')
  components = query.split('&')
  params = {}
  for component in components
    s = component.split('=')
    continue if s.length == 0
    if s.length == 1
      params[s] = true
    else
      key = s[0]
      v = s.splice(1).join('=')
      params[s] = v
  return params

window.init = (exposeDebug) ->
  $container = $('#container')
  #WIDTH = screen.availWidth#800
  #HEIGHT = screen.availHeight
  WIDTH = window.innerWidth
  HEIGHT = window.innerHeight
  console.log(WIDTH, HEIGHT)

  games =
    voxels: VoxelGame
    world: WorldGame
    test: Game
    pipes: PipeGame
    terrain: TerrainGame
    dna: DnaGame

  params = getQueryParams()

  GameClass = games[params.game or 'voxels']

  game = new GameClass($container, WIDTH, HEIGHT)
  console.log("Game created! Starting!")
  game.start()

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

