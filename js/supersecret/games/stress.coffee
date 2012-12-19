lib.load(
  'grid'
  'now'
  'set'
  'updater'
  ->
    supersecret.Game.loaded = true)


supersecret.Game = class Voxels2Game
  @loaded: false
  constructor: (container, width, height) ->
    $canvas = $('<canvas>')
    canvas = $canvas[0]
    canvas.width = width
    canvas.height = height
    @context = canvas.getContext('2d')
    $(container).append($canvas)

    window.addEventListener('resize', (->
      canvas.width = window.innerWidth
      canvas.height = window.innerHeight
    ).bind(this), false);

    console.log('Starting add stress test')
    @data = []
    @data2 = []
    @maxdata = 0
    @maxdata2 = 0
    o = new Set()
    MAX = 1000000
    updater = new Updater(1000)
    for i in [0..MAX]
      updater.update('stress-test', "Stress test is #{i/MAX*100}% complete")

      t1 = now()
      key = i
      t2 = now() - t1
      @data2.push(t2)
      @maxdata2 = t2 if t2 > @maxdata2

      t1 = now()
      o.add(key)
      t2 = now() - t1
      @data.push(t2)
      @maxdata = t2 if t2 > @maxdata
    console.log('stress test is complete')

    @rdata = []
    while o.length > 0
      updater.update('stress-test', "#{o.length} items remaining")
      t1 = now()
      i = o.pop()
      t2 = now() - t1
      @rdata.push t2

    console.log(@data, @data2)

    @context.fillStyle = '#000'
    @context.fillRect(0, 0, @context.canvas.width, @context.canvas.height)

    first = false
    for i in [0..@data.length-1]
      d = @data[i]
      p = [i / @data.length * @context.canvas.width, d / @maxdata * @context.canvas.height]
      if first
        @context.moveTo(p...)
      else
        @context.lineTo(p...)

    @context.strokeStyle = '#f00'
    @context.stroke()

      # d2 = @data2[i]

  render: (delta) ->
    null



  start: ->
    lastUpdate = new Date().getTime()
    f = (->
      now = new Date().getTime()
      @render(now - lastUpdate)
      lastUpdate = now
      requestAnimationFrame(f)
    ).bind(this)
    f()
