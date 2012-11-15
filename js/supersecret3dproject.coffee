Game = p.require('Game')
PipeGame = p.require('PipeGame')
FirstPerson = p.require('FirstPerson')


window.init = (exposeDebug) ->
  $container = $('#container')
  #WIDTH = screen.availWidth#800
  #HEIGHT = screen.availHeight
  WIDTH = window.innerWidth
  HEIGHT = window.innerHeight
  console.log(WIDTH, HEIGHT)

  game = new PipeGame($container, WIDTH, HEIGHT)
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

