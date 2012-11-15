requestAnimationFrame = p.require('requestAnimationFrame')

average = (l) ->
  s = 0
  for i in l
    s += i
  return s / l.length

requestAnimationFrame = require('requestAnimationFrame')


class Renderer
  constructor: (width, height) ->
    VIEW_ANGLE = 45
    ASPECT = WIDTH / HEIGHT
    NEAR = 0.1
    FAR = 10000
    
    @renderer = new THREE.WebGLRenderer()
    @renderer.setSize(WIDTH, HEIGHT)

  maybeUpdate: -> ((frequency) ->
    frequency = frequency or 10000

    lastUpdated = new Date().getTime() - frequency
    return ->
      if new Date().getTime() - lastUpdated > frequency
        console.log('Render loop going well. ' + 1000 / average(frameHistory) + ' frames per second')
        lastUpdated = new Date().getTime())(5000)

  start = (tick) ->
    renderer = this
    @stopped = false
    frameHistory = []
    
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

p.provide('Renderer', Renderer)