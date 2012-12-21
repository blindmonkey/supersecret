lib.load(
  'firstperson'
  'polygons'
  -> supersecret.Game.loaded = true)

randomNumber = (max, negativify=false) ->
  r = Math.random()
  if negativify
    r = (r - 0.5) * 2
  return r * max

randomVector = ->
  new THREE.Vector3((randomNumber(100, true) for _i in [0..2])...)

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)

  createParticleTexture: ->
    canvas = document.createElement('canvas')
    canvas.width = 128
    canvas.height = 128
    context = canvas.getContext('2d')

    context.fillStyle = '#f0f'
    context.fillRect(0,0,context.canvas.width, context.canvas.height)
    context.fillStyle = '#0f0'
    context.fillRect(
      context.canvas.width * .25
      context.canvas.height * .25
      context.canvas.width * .5
      context.canvas.height * .5)

    texture = new THREE.Texture(canvas) #context.getImageData(0, 0, canvas.width, canvas.height))
    texture.needsUpdate = true
    return texture

  initGeometry: ->
    @particles = new THREE.Geometry()

    @gravity = 1
    @velocities = []
    for i in [0..1000]
      @generateParticle()

    # particleTexture = $('<canvas>')
    # $('body').append(particleTexture)

    # particleTexture = new THREE.Texture(particleTextureCanvas)
    # particleTexture.needsUpdate = true

    @system = new THREE.ParticleSystem(
      @particles
      #new THREE.MeshBasicMaterial({ color: 0xff0000 })
      new THREE.MeshBasicMaterial({
        map: @createParticleTexture()
        transparent: true
      })
      # new THREE.ParticleCanvasMaterial {
      #   blending: THREE.AdditiveBlending
      #   program: (context) ->
      # }
    )
    @scene.add @system

  generateParticle: (index) ->
    v = [randomNumber(10, true), randomNumber(50), randomNumber(10, true)]
    p = new THREE.Vector3(0,0,0)
    if index == undefined
      @velocities.push v
      @particles.vertices.push p
    else
      @velocities[index] = v
      @particles.vertices[index] = p

  updateParticles: (delta) ->
    d = delta / 1000
    for i in [0..@particles.vertices.length - 1]
      [dx, dy, dz] = @velocities[i]
      @velocities[i][1] -= @gravity
      particle = @particles.vertices[i]
      particle.x += dx * d
      particle.y += dy * d
      particle.z += dz * d
      if particle.y < -50
        @generateParticle(i)
        # @velocities[i][1] = -@velocities[i][1]
        # particle.y = -50
        # @velocities[i][1] *= 0.5
      if not (-100 < particle.x < 100 and -100 < particle.z < 100)
        @generateParticle(i)
    @particles.verticesNeedUpdate = true

  update: (delta) ->
    @updateParticles(delta)
    @person.update(delta)
