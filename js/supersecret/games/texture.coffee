lib.load(
  'firstperson'
  'pixels'
  'polygons'
  'worker'
  -> supersecret.Game.loaded = true)

class Physics
  @gravity = 9 # u / s

class CubePhysics
  constructor: (mesh) ->
    if not mesh.geometry.boundingBox
      mesh.geometry.computeBoundingBox()
    @center = new THREE.Vector3().add(mesh.geometry.boundingBox.min, mesh.geometry.boundingBox.max).divideScalar(2)
    @mesh = mesh
    @xtilt = 0
    @ztilt = 0
    @position = new THREE.Vector3(0, 1000, 0)
    @velocity = new THREE.Vector3(0, 0, 0)

  update: (delta) ->
    @velocity.y += @gravity
    @position.addSelf(@velocity.clone().multiplyScalar(delta / 1000))
    @mesh.position.set(@position.x, @position.y, @position.z)

generateTexture = ->
  canvas = document.createElement('canvas')
  canvas.width = 512
  canvas.height = 256
  cx = canvas.width / 2
  cy = canvas.height / 2
  context = canvas.getContext('2d')
  pixels = new Pixels(context)
  noise = new SimplexNoise()

  worker = new NestedForWorker([[0, canvas.width - 1], [0, canvas.height - 1]], (x, y) ->
    n = noise.noise2D(x / 32, y / 32)
    color = if n > 0 then new Color(255, 0, 0) else new Color(0, 128, 0)
    pixels.set(x, y, color)
  )
  worker.synchronous = true
  worker.run()
  pixels.update()

  $('body').append(canvas)

  texture = new THREE.Texture(canvas)
  texture.needsUpdate = true
  return texture

distance2 = (x, y) ->
  Math.sqrt(x*x + y*y)

latLongFrom3D = (x, y, z) ->
  long = Math.atan2(z, x)
  lat = Math.atan2(y, distance2(x, z))
  return [lat, long]
  PI2 = Math.PI * 2
  while long < 0
    long += PI2
  while long > PI2
    long -= PI2
  while lat < 0
    lat += PI2
  while lat > PI2
    lat -= PI2


  return [lat - Math.PI / 2, long - Math.PI]



supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)

    @setTransform 'iterations', parseInt

  initGeometry: ->

    console.log(@watch)
    geometry = new polygons.sphere(10, @watched.iterations)

    for faceIndex in [0..geometry.faces.length-1]
      face = geometry.faces[faceIndex]
      va = geometry.vertices[face.a]
      vb = geometry.vertices[face.b]
      vc = geometry.vertices[face.c]
      alatlng = latLongFrom3D(va.x, va.y, va.z)
      blatlng = latLongFrom3D(vb.x, vb.y, vb.z)
      clatlng = latLongFrom3D(vc.x, vc.y, vc.z)
      geometry.faceVertexUvs[ 0 ].push( [
          new THREE.UV( alatlng[0] / Math.PI / 4, alatlng[1] / Math.PI / 2 ),
          new THREE.UV( blatlng[0] / Math.PI / 4, blatlng[1] / Math.PI / 2 ),
          new THREE.UV( clatlng[0] / Math.PI / 4, clatlng[1] / Math.PI / 2 )
      ] );
    geometry.computeCentroids()
    geometry.computeVertexNormals()
    geometry.computeFaceNormals()
    # geometry.normalsNeedUpdate = true

    @setTransform 'speed', parseFloat
    @watch 'speed', (v) =>
      debugger
      @person.speed = v

    texture = generateTexture()

    mesh = new THREE.Mesh(
      geometry
      new THREE.MeshBasicMaterial({
        # color: 0xbb6030,
        shading: THREE.Smooth
        map: texture})
      # new THREE.LineBasicMaterial({color: 0x801020})
    )
    @cubePhysics = new CubePhysics(mesh)
    @scene.add mesh
    DEBUG.expose('mesh', mesh)
    DEBUG.expose('camera', @camera)

  initLights: ->
    @scene.add new THREE.AmbientLight(0x404040)
    # light = new THREE.DirectionalLight(0xffffff, .1)
    # light.position.set(((Math.random()-0.5) for x in [0..2])...)
    # @scene.add light
    # console.log(light.position)

  update: (delta) ->
    #@cubePhysics.update(delta)
    #console.log(@cubePhysics.position)

    @person.update(delta)
