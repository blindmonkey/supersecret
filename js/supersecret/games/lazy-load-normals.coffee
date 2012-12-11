lib.load(
  'facemanager'
  'firstperson'
  'worker'
  -> supersecret.Game.loaded = true)

supersecret.Game = class LazyGame extends supersecret.BaseGame
  @loaded: false

  preinit: ->
    @noise = new SimplexNoise()

  postinit: ->
    @person = new FirstPerson(container, @camera)

  initGeometry: ->
    faceManager = new FaceManager(500)
    mesh = null

    updateGeometry = (->
      newGeometry = faceManager.generateGeometry()
      if mesh
        @scene.remove mesh
      newGeometry.computeFaceNormals()
      mesh = new THREE.Mesh(newGeometry,
        new THREE.MeshNormalMaterial())
      @scene.add mesh
    ).bind(this)

    scale = 5
    yscale = 10

    getVector = ((x, y) ->
      return [x*scale, @noise.noise2D(x/16, y/16) * yscale, y * scale]
    ).bind(this)

    worker = new NestedForWorker([[0,500], [0,500]], ((x, y) ->
      faceManager.addFace(
        getVector(x, y), getVector(x, y+1), getVector(x+1, y)
      )
    ).bind(this), {
      ondone: updateGeometry
      onpause: ->
        updateGeometry()
    })
    worker.cycle = 50
    worker.run()

  update: (delta) ->
    @person.update(delta)
