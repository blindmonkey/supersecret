lib.load(
  'firstperson'
  'pixels'
  'polygons'
  'tracker'
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
  canvas.width = 2048
  canvas.height = 1024
  cx = canvas.width / 2
  cy = canvas.height / 2
  context = canvas.getContext('2d')
  pixels = new Pixels(context)
  noise = new SimplexNoise()

  worker = new NestedForWorker([[0, canvas.width - 1], [0, canvas.height - 1]], (xx, yy) ->
    [x, y, z] = vectorFromLatLng(yy / canvas.height * Math.PI, xx / canvas.width * Math.PI * 2)
    n = noise.noise3D(x / 2, y / 2, z / 2)
    color = if n > 0 then new Color(255, 0, 0) else new Color(0, 128, 0)
    # color = new Color((n + 1) / 2 * 255, 0, 0)
    pixels.set(xx, yy, color)
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

modulus = (n, r) ->
  while n < 0
    n += r
  while n > r
    n -= r
  return n

latLongFrom3D = (x, y, z) ->
  long = Math.atan2(z, x)
  d = distance2(x, z)
  lat = Math.atan2(y, d)
  return [(lat + Math.PI / 2) / Math.PI, (long + Math.PI) / Math.PI / 2]

vectorFromLatLng = (lat, lng) ->
  r = Math.cos(lat)
  y = Math.sin(lat)
  x = Math.cos(lng) * r
  z = Math.sin(lng) * r
  return [x, y, z]

cap = (n, r1, r2) ->
  return n if r1 <= n <= r2
  return r1 if n < r1
  return r2 if n > r2


supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)

    @setTransform 'iterations', parseInt

  initGeometry: ->

    console.log(@watch)
    geometry = new polygons.sphere(10, @watched.iterations)
    console.log('dhsfkhadkshfkah', latLongFrom3D(0, 1, 0))
    tracker = new Tracker()

    debugger
    for faceIndex in [0..geometry.faces.length-1]
      face = geometry.faces[faceIndex]
      va = geometry.vertices[face.a]
      vb = geometry.vertices[face.b]
      vc = geometry.vertices[face.c]
      alatlng = latLongFrom3D(va.x, va.y, va.z)
      blatlng = latLongFrom3D(vb.x, vb.y, vb.z)
      clatlng = latLongFrom3D(vc.x, vc.y, vc.z)

      # console.log( ayn, byn, cyn)
      tracker.track({'lat': alatlng[0]})
      tracker.track({'lat': blatlng[0]})
      tracker.track({'lat': clatlng[0]})
      tracker.track({'lng': alatlng[1]})
      tracker.track({'lng': blatlng[1]})
      tracker.track({'lng': clatlng[1]})
      abdiff = -> Math.abs(alatlng[1] - blatlng[1])
      acdiff = -> Math.abs(alatlng[1] - clatlng[1])
      bcdiff = -> Math.abs(blatlng[1] - clatlng[1])
      while abdiff() > 0.6 or acdiff() > 0.6 or bcdiff() > 0.6
        if abdiff() > 0.6
          if alatlng[1] < blatlng[1]
            alatlng[1] += 1
          else
            blatlng[1] += 1
        if acdiff() > 0.6
          if alatlng[1] < clatlng[1]
            alatlng[1] += 1
          else
            clatlng[1] += 1
        if bcdiff() > 0.6
          if blatlng[1] < clatlng[1]
            blatlng[1] += 1
          else
            clatlng[1] += 1
      tracker.track({'lngspread': acdiff()})
      tracker.track({'lngspread': bcdiff()})
      tracker.track({'lngspread': abdiff()})

      geometry.faceVertexUvs[ 0 ].push( [
          new THREE.UV( alatlng[1], alatlng[0]),
          new THREE.UV( blatlng[1], blatlng[0]),
          new THREE.UV( clatlng[1], clatlng[0])
      ] );
    console.log(tracker.get('lat', 'lng', 'lngspread'))


    # face = geometry.faces[0]
    # va = geometry.vertices[face.a]
    # @scene.add m = new THREE.Mesh(
    #   new THREE.SphereGeometry(.01, 4, 4),
    #   new THREE.LineBasicMaterial({color: 0xff0000}))
    # m.position = va
    # vb = geometry.vertices[face.b]
    # @scene.add m = new THREE.Mesh(
    #   new THREE.SphereGeometry(.01, 4, 4),
    #   new THREE.LineBasicMaterial({color: 0xff0000}))
    # m.position = vb
    # vc = geometry.vertices[face.c]
    # alatlng = latLongFrom3D(va.x, va.y, va.z)
    # blatlng = latLongFrom3D(vb.x, vb.y, vb.z)
    # clatlng = latLongFrom3D(vc.x, vc.y, vc.z)
    # geometry.faceVertexUvs[0].push([
    #   new THREE.UV(0, 0)
    #   new THREE.UV(0, 1)
    #   new THREE.UV(1, 1)
    # ])

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
        # vertexColors: THREE.VertexColors})
        color: 0xffffff,
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
