lib.load('worker', 'pixels', 'updater', 'timer', ->
  supersecret.Game.loaded = true)

supersecret.Game = class WorkerTest
  @loaded: false
  constructor: (container, width, height) ->
    $canvas = $('<canvas>')
    canvas = $canvas[0]
    canvas.width = width
    canvas.height = height
    $(container).append $canvas
    @context = canvas.getContext('2d')
    @noise = new SimplexNoise()

  start: ->
    console.log 'loaded'

    @context.fillStyle = '#000'
    @context.fillRect(0, 0, @context.canvas.width, @context.canvas.height)
    updater = new Updater(500)
    updater.setFrequency
    pixels = new Pixels(@context)
    noise = @noise

    timer = new Timer()
    timer.start('worker')
    WorkerPool.setCycleTime(1)
    loopWorker = new NestedForWorker([[0,pixels.buffer.width-1], [0,pixels.buffer.height-1]], ((x, y) ->
      n = noise.noise2D(x / 32, y / 32)
      n = Math.floor((n + 1) / 2 * 255)
      pixels.set(x, y, new Color(n, n, n))
    ), {
      onpause: (state) ->
        pixels.update()
      ondone: ->
        pixels.update()
    })
    loopWorker.cycle = 500
    loopWorker.run()

    return
    loopWorker = new LoopWorker({
      init: (state) ->
        state.x = 0
      progress: (state) ->
        state.x++
      finished: (state) ->
        return state.x >= pixels.buffer.width
      work: (xstate) ->
        x = xstate.x
        yLoopWorker = new LoopWorker({
          init: (state) ->
            state.y = 0
          progress: (state) ->
            state.y++
          finished: (state) ->
            return state.y >= pixels.buffer.height
          work: (state) ->
            n = noise.noise2D(x / 32, state.y / 32)
            n = Math.floor((n + 1) / 2 * 255)
            pixels.set(x, state.y, new Color(n, n, n))
            updater.update('pixelsUpdate', ->
              pixels.update())
        }, {
          ondone: (state) ->
            console.log('Y loop for x = ' + x + ' finished at ' + state.y)
          onpause: (state) ->
            console.log('Y loop for x = ' + x + ' paused at ' + state.y)
          oncontinue: (state) ->
            console.log('Y loop for x = ' + x + ' continued at ' + state.y)
        })
        yLoopWorker.run()
      }, {
        ondone: (state) ->
          console.log('X loop finished at ' + state.x)
        onpause: (state) ->
          console.log('X loop paused at ' + state.x)
        oncontinue: (state) ->
          console.log('X loop continued at ' + state.x)
      }
    )
    loopWorker.run()

    # for x in [0..200]
    #   updater.update('x', x)
    #   for y in [0.. 200]
    #     if x < @context.canvas.width and y < @context.canvas.height
    #       pixels.set(x, y, new Color(Math.random() * 255, Math.random() * 255, Math.random() * 255))
    #   pixels.update()
    #loopWorker.pool.start(loopWorker)
