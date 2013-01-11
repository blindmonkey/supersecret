window.init = (exposeDebug) ->
  $container = $('#container')
  #WIDTH = screen.availWidth#800
  #HEIGHT = screen.availHeight
  WIDTH = window.innerWidth
  HEIGHT = window.innerHeight
  console.log(WIDTH, HEIGHT)

  params = getQueryParams()
  CoffeeScript.load('js/supersecret/games/' + params.game + '.coffee', ->
    console.log('Game loaded');
  )
  
  canvas = document.createElement('canvas')
  doResize = ->
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
  doResize()
  context = canvas.getContext('2d')
  $container.append(canvas)
  
  doRedraw = ->
    context.fillStyle = '#fff'
    context.fillRect(0, 0, canvas.width, canvas.height)
    barWidth = canvas.width * .6
    barHeight = Math.min(canvas.height, 50)
    #context.fillText("hello #{lib.percentage() * 100}%", 20, 20)
    context.strokeStyle = '#000'
    context.strokeRect(canvas.width / 2 - barWidth / 2, canvas.height / 2 - barHeight / 2, barWidth, barHeight)
    context.fillStyle = '#000'
    context.fillRect(canvas.width / 2 - barWidth / 2, canvas.height / 2 - barHeight / 2, barWidth * lib.percentage(), barHeight)
  
  lib.handle('loaded', ->
    doRedraw()
  )
  
  window.addEventListener('resize', (->
      doResize()
      doRedraw()
    ), false)

  loadGame = ->
    $(canvas).remove()
    console.log('Game loaded!')
    game = new supersecret.Game($container, WIDTH, HEIGHT)
    console.log("Game created! Starting!")
    game.start()

  waitForLoad = ->
    if supersecret.BaseGame and supersecret.Game and (supersecret.Game.loaded is undefined or supersecret.Game.loaded)
      loadGame()
    else
      setTimeout(waitForLoad, 100)
  waitForLoad()