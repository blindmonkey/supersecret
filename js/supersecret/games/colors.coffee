lib.load(
  'firstperson'
  -> supersecret.Game.loaded = true)

supersecret.Game = class NewGame extends supersecret.BaseGame
  @loaded: false

  postinit: ->
    @person = new FirstPerson(container, @camera)
    # @camera.position.z = -128
    @person.updateCamera()

  createHistogram: (colors, buckets=16) ->
    getBucket = (color, n) ->
      b = ((color & 0xff)) / n
      g = ((color & 0xff00) >> 8) / n
      r = ((color & 0xff0000) >> 16) / n
      (Math.floor(r)*n << 16) + (Math.floor(g)*n << 8) + Math.floor(b)*n


    o = new THREE.Object3D()
    counts = {}
    max = 0
    for color in colors
      bucket = getBucket(color, buckets)
      if bucket not of counts
        counts[bucket] = 0
      v = ++counts[bucket]
      if v > max
        max = v
    for color of counts
      # console.log(color)
      b = color & 0xff
      g = (color & 0xff00) >> 8
      r = (color & 0xff0000) >> 16
      r -= 128
      g -= 128
      b -= 128
      # console.log r, g, b
      geometry = new THREE.SphereGeometry(counts[color] / max * .25, 8, 8)
      material = new THREE.LineBasicMaterial({color: parseInt(color)})
      m = new THREE.Mesh(geometry, material)
      # m.position.x = 2
      m.position.x = r / buckets
      m.position.y = g / buckets
      m.position.z = b / buckets
      o.add m
    # console.log(o)
    return o

  initGeometry: ->
    # @scene.add new THREE.Mesh(
    #   new THREE.SphereGeometry(1, 16, 16),
    #   new THREE.LineBasicMaterial({color: 0xff0000})
    #   )
    randomColor1 = ->
      return Math.floor(Math.random() * Math.pow(2, 24))
    randomColor2 = ->
      r = Math.floor(Math.random() * 256)
      g = Math.floor(Math.random() * 256)
      b = Math.floor(Math.random() * 256)
      return (r<<16) + (g<<8) + b

    DEBUG.expose('scene', @scene)
    @colors = []
    @colors2 = []
    for x in [0..1500]
      @colors.push randomColor1()
      @colors2.push randomColor2()
    @scene.add m = @createHistogram(@colors, 32)
    m.position.x = -1
    @scene.add m = @createHistogram(@colors2, 32)
    m.position.x = 11


  update: (delta) ->
    @person.update(delta)
