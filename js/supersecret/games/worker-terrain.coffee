terrainWorker = null

now = -> new Date().getTime()

lib.load(
  'firstperson'
  'polygons'
  #'now'
  'worker-comm'
  'webworkers'
  ->
    console.log('libs loaded')
    terrainWorker = webworker.fromCoffee([
      'js/three.min.js'
      'js/coffee-script.js'
      'js/worker-console.js'
      'js/simplex-noise.js'
      'worker-comm'
      #'worker-console'
    ], """
      console.log('hello from worker')
      
      getIndex = (size, x, y) ->
        return y * size + x
      
      noise = new SimplexNoise()
      
      comm = new WorkerComm(self, {
        test: (a, b) ->
          console.log('test!')
          return a + b
        geometry: (size, tilesize) ->
          t = new Date().getTime()
          geo = new THREE.Geometry()
          for y in [0..size-1]
            for x in [0..size-1]
              #n = noise.noise2D(
              geo.vertices.push new THREE.Vector3(x * tilesize, 0, y * tilesize)
              if x > 0 and y > 0
                geo.faces.push(new THREE.Face3(getIndex(size, x, y), getIndex(size, x, y - 1), getIndex(size, x - 1, y)))
                geo.faces.push(new THREE.Face3(getIndex(size, x, y - 1), getIndex(size, x - 1, y - 1), getIndex(size, x - 1, y)))
          
          comm.console.log("Geometry generation finished in " + (new Date().getTime() - t) + "s")
          geo.computeFaceNormals()
          return geo
      })
      comm.ready()
      comm.handleReady(->
        comm.console.log('uhh hey...')
        )
    """)
    terrainWorker.onmessage = console.handleConsoleMessages('w1')
    terrainWorker = new WorkerComm(terrainWorker, {});
    terrainWorker.handleReady(->
      supersecret.Game.loaded = true
      terrainWorker.ready()
      #console.log('worker is ready!')
      #terrainWorker.call('test', 1, 2, (result) ->
        #console.log('yo dawg')
        #)
      #terrainWorker.call('geometry', (geo) ->
          #console.log('geometry received', geo)
        #)
    )
    #terrainWorker.onmessage = console.handleConsoleMessages('worker1')
    
    #terrainWorker.handleReady(->
    #)
)

serializer = {
  db: {}
}

serializer.serialize = (name, obj) ->
  methods = serializer.db[name]
  return methods && methods.serialize(obj)
serializer.deserialize = (name, obj) ->
  methods = serializer.db[name]
  return methods && methods.deserialize(obj)
serializer.teach = (name, serialize, deserialize) ->
  serializer.db[name] =
    serialize: serialize
    deserialize: deserialize
  
identity = (o) -> o
serializer.teach('Geometry', identity, ((o) ->
  geo = new THREE.Geometry()
  for p of o
    if p == 'vertices'
      for v in o.vertices
        geo.vertices.push new THREE.Vector3(v.x, v.y, v.z)
    else if p == 'faces'
      for f in o.faces
        geo.faces.push face = new THREE.Face3(f.a, f.b, f.c)
        face.normal = new THREE.Vector3(f.normal.x, f.normal.y, f.normal.z)
    else
      geo[p] = o[p]
  return geo)
)

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)

  initGeometry: ->
    terrainWorker.call('geometry', 128, 10, (rawgeo) =>
      t = now()
      geo = serializer.deserialize('Geometry', rawgeo)
      console.log('Geometry deserialized in ' + (now() - t) + 's')
      @scene.add new THREE.Mesh(geo, new THREE.MeshNormalMaterial())
      )
    #cubeGeometry = polygons.cube(1)
    #cubeGeometry.computeFaceNormals()
    #@scene.add new THREE.Mesh(
      #cubeGeometry
      #new THREE.MeshNormalMaterial()
      #new THREE.SphereGeometry(1, 16, 16),
       #new THREE.LineBasicMaterial({color: 0xff0000})
      #)

  update: (delta) ->
    @person.update(delta)
