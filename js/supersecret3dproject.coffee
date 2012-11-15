
###
window.doRender = (tick) ->
  stopped = false

  frameHistory = []
  average = (l) ->
    s = 0
    for i in l
      s += i
    return s / l.length
  maybeUpdate = (->
      lastUpdated = new Date().getTime() - 5000
      return ->
        if new Date().getTime() - lastUpdated > 5000
          console.log('Render loop going well. ' + 1000 / average(frameHistory) + ' frames per second')
          lastUpdated = new Date().getTime())()

  lastTime = new Date().getTime()
  f = ->
    now = new Date().getTime()
    tick(now - lastTime)
    afterTickTime = new Date().getTime()
    frameHistory.push(afterTickTime - now)
    maybeUpdate()
    lastTime = now
    if not stopped
      requestAnimationFrame(f)
  f()
  return {
    pause: ->
      stopped = true
    unpause: ->
      stopped = false
      lastTime = new Date().getTime()
      f()
  }


###

Game = p.require('Game')
FirstPerson = p.require('FirstPerson')


window.init = (exposeDebug) ->
  $container = $('#container')
  #WIDTH = screen.availWidth#800
  #HEIGHT = screen.availHeight
  WIDTH = $(window).width()
  HEIGHT = $(window).height()
  console.log(WIDTH, HEIGHT)



  game = new Game($container, WIDTH, HEIGHT)
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

