require('math')
require('time/now')

exports.Renderer = class
  constructor: (container, width, height) ->
    @width = width
    @height = height
    @canvas = $('<canvas>')
    @canvas[0].width = @width
    @canvas[0].height = @height
    @context = @canvas[0].getContext('2d')
    $(container).append(@canvas)

  resize: (width, height) ->
    @width = width
    @height = height
    @canvas[0].width = width
    @canvas[0].height = height

  start: (tick) ->
    @stopped = false
    frameHistory = []

    maybeUpdate = ((frequency) ->
      frequency = frequency or 10000

      lastUpdated = now() - frequency
      return ->
        if now() - lastUpdated > frequency
          if frameHistory.length > 100
            frameHistory = frameHistory.splice(frameHistory.length - 100, 100)
          console.log('Render loop: ' + 1000 / math.average(frameHistory) + ' frames per second')
          lastUpdated = now()
    )(5000)

    renderer = @
    lastTime = now()
    f = ->
      n = now()
      tick(n - lastTime)
      frameHistory.push(n - lastTime)
      maybeUpdate()
      lastTime = n
      if not renderer.stopped
        requestAnimationFrame(f)
    f()
    return {
      pause: ->
        renderer.stopped = true
      unpause: ->
        renderer.stopped = false
        lastTime = now()
        f()
    }
