lib.load(
  'events'
  'firstperson'
  'polygons'
  'treedeque'
  ->
    createEmitter()
    supersecret.Game.loaded = true)

randomNumber = (max, negativify=false, scale=null) ->
  r = Math.random()
  if scale?
    r = scale(r)
  if negativify
    r = (r - 0.5) * 2
  return r * max

randomVector = ->
  new THREE.Vector3((randomNumber(100, true) for _i in [0..2])...)

Emitter = null
createEmitter = ->
  Emitter = class Emitter extends EventManagedObject
    constructor: (position, frequency, material, particleCount=1000) ->
      super()
      @position = position
      @frequency = frequency
      @geometry = new THREE.Geometry()
      @pool = new TreeDeque()
      @pool.listSize = 100
      for i in [1..particleCount]
        vertex = new THREE.Vector3(10000,10000,10000)
        @geometry.vertices.push vertex
        @pool.push i-1

      @data = []
      @particleIndex = []
      @particles = new THREE.ParticleSystem(@geometry, material)
      @maxParticles = particleCount
      @timeElapsed = 0

    poolFull: ->
      return @pool.length <= 0

    addParticle: (position, data) ->
      return if @poolFull()
      console.log('adding particle')
      @data.push data
      i = @pool.pop()
      @particleIndex.push i

      if position instanceof Function
        position = position()

      @geometry.vertices[i].set(position...)
      @geometry.verticesNeedUpdate = true
      return @geometry.vertices[i]

    killParticle: (i) ->
      j = @particleIndex[i]
      @data.splice(i, 1)
      @particleIndex.splice(i, 1)
      @geometry.verticesNeedUpdate = true
      if j != undefined
        @geometry.vertices[j].set(10000,10000,10000)
        @pool.push j

    update: (delta) ->
      @timeElapsed += delta
      if @geometry.vertices.length > @maxParticles
        @geometry.vertices.splice(@geometry.vertices.length - @maxParticles)

      if @timeElapsed > @frequency
        counts = Math.floor(@timeElapsed / @frequency)
        @timeElapsed -= @frequency * counts
        if @maxParticles - @data.length > 0
          for i in [1..counts]
            #vertex = new THREE.Vector3(@position...)
            data = {}
            vertex = @addParticle(@position, data)
            @fireEvent('create', vertex, data)

      if @data.length > 0
        shouldDie = []
        for i in [1..@data.length]
          j = @particleIndex[i-1]
          vertex = @geometry.vertices[j]
          data = @data[i-1]
          @fireEvent('update', delta, vertex, data)
          shouldDie.push i if data.kill
        if shouldDie.length > 0
          for i in [shouldDie.length..1]
            @killParticle i
        @geometry.verticesNeedUpdate = true

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)
    @person.updateCamera()

  createParticleTexture: ->
    canvas = document.createElement('canvas')
    $('body').append(canvas)
    canvas.width = 128
    canvas.height = 128
    context = canvas.getContext('2d')

    context.fillStyle = '#05f'
    cx = canvas.width / 2
    cy = canvas.height / 2
    context.arc(cx, cy, cx, 0, Math.PI * 2)
    grd = context.createRadialGradient(cx, cy, 0, cx, cy, cx);
    grd.addColorStop(0, 'rgba(215, 0, 5, .8)');
    grd.addColorStop(0.5, 'rgba(255, 127, 5, .3)');
    grd.addColorStop(1, 'rgba(255, 215, 10, .01)');

    context.fillStyle = grd;
    context.fill()

    # context.fillStyle = '#f0f'
    # context.fillRect(0,0,context.canvas.width, context.canvas.height)
    # context.fillStyle = '#0f0'
    # context.fillRect(
    #   context.canvas.width * .25
    #   context.canvas.height * .25
    #   context.canvas.width * .5
    #   context.canvas.height * .5)

    texture = new THREE.Texture(canvas) #context.getImageData(0, 0, canvas.width, canvas.height))
    texture.needsUpdate = true
    return texture

  initGeometry: ->
    console.log('initializing geometry...')
    @particles = new Emitter((->
        v = new THREE.Vector3(randomNumber(1,true), randomNumber(1,true), randomNumber(1,true))
        v.normalize()
        return [v.x * 5, v.y * 5, v.z * 5]
      ),
      1,
      undefined)
      #new THREE.LineBasicMaterial({ color: 0xff0000 }))
      (new THREE.ParticleBasicMaterial({
        size: 10,
        map: @createParticleTexture(),
        blending: THREE.AdditiveBlending,
        depthTest: false,
        transparent : true }))
    @scene.add @particles.particles

    @particles.handleEvent('create', (vertex, data) ->
      data.velocity =
        x: randomNumber(30, true)
        y: randomNumber(60, false)+10
        z: randomNumber(30, true)
      data.life = randomNumber(1000, false, ((x) -> Math.sqrt(x)))+100
    )

    @particles.handleEvent('update', (delta, vertex, data) ->
      data.velocity.y += .09 * delta
    )

    @particles.handleEvent('update', (delta, vertex, data) ->
      data.velocity.x += randomNumber(1, true) * delta / 1000
      data.velocity.y += (randomNumber(4, true) + 1) * delta / 1000
      data.velocity.z += randomNumber(10, true) * delta / 1000
    )

    @particles.handleEvent('update', (delta, vertex, data) ->
      delta = delta / 1000

      vertex.x += data.velocity.x * delta
      vertex.y += data.velocity.y * delta
      vertex.z += data.velocity.z * delta
      data.kill = true if not (-100 < vertex.y < 100)
    )

    @particles.handleEvent('update', (delta, vertex, data) ->
      data.life -= delta
      data.kill = true if data.life <= 0
    )

    console.log('done')

    @gravity = 100

  update: (delta) ->
    #@updateParticles(delta)
    @particles.update(delta)
    @person.update(delta)
