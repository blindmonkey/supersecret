Renderer = p.require('Renderer')
FirstPerson = p.require('FirstPerson')
BaseGame = p.require('BaseGame')

class ChunkManager
  constructor: (scene, chunkSize, tileSize) ->
    @scene = scene
    @noise = new SimplexNoise()
    @chunkSize = chunkSize
    @tileSize = tileSize

    @spacingZ = @tileSize + Math.cos(2 * Math.PI / 6) - Math.cos(2 * Math.PI / 6 * 2)
    @spacingX = @tileSize * Math.cos(Math.PI / 6) / 2
    @totalWidth = @tileSize / 2 * @spacingZ * @chunkSize.width
    @totalHeight = @tileSize / 2 * @spacingX * @chunkSize.height

    @chunks = {}

  sanitizeChunkPosition: (x, y) ->
    return [Math.floor(x), Math.floor(y)]

  getChunkId: (x, y) ->
    [x, y] = @sanitizeChunkPosition(x, y)
    return x + '/' + y

  chunkExists: (x, y) ->
    chunkId = @getChunkId(x, y)
    chunk = @chunks[chunkId]
    if chunk is undefined
      return false
    if chunk is false
      return false
    return chunk

  getChunk: (x, y, callback) ->
    chunkId = @getChunkId(x, y)
    if chunkId not of @chunks
      @chunks[chunkId] = false
      setTimeout((->
        console.log("Created chunk at " + x + ', ' + y)
        @generateChunk(x, y, ((chunk) ->
          callback(@chunks[chunkId] = chunk)
        ).bind(this))
      ).bind(this))
    if @chunks[chunkId] is false
      return {meshes: []}
    return @chunks[chunkId]

  generateNoise: (x, y) ->
    makeNoise = ((scale, multiplier) ->
      @noise.noise2D(x / scale, y / scale) * multiplier
    ).bind(this)
    #n = (@noise.noise2D(xPosition / 80, zPosition / 80) + 1) * 10
    return makeNoise(80, 10) + makeNoise(40, 5) + makeNoise(20, 2.5) + 20

  generateChunk: (x, y, callback) ->
    [chunkX, chunkY] = @sanitizeChunkPosition(x, y)

    geometry = new THREE.Geometry()
    data = []
    ondone = ->
      console.log("COMPLETE" + x + ',' + y)
      geometry.computeFaceNormals()
      chunk = {}
      chunk.meshes = [new THREE.Mesh(
        geometry,
        new THREE.MeshPhongMaterial({color: 0x55ff55})
        #new THREE.LineBasicMaterial({color: 0xff0000})
        )]
      callback(chunk)

    continueX = ((xx) ->
      lastCalled = new Date().getTime()
      console.log("Continue from " + xx)
      for x in [xx..@chunkSize.height]
        #console.log(x)
        width = @chunkSize.width - (if x % 2 then 1 else 0)
        offset = if z % 2 then @spacingZ / 2 else 0
        dataRow = []
        for z in [0..width]
          zPosition = z * @spacingZ + offset - @totalWidth / 2 + @totalWidth * chunkX
          xPosition = x * @spacingX - @totalHeight / 2 + (@totalHeight + @spacingX / 2) * chunkY
          value = @generateNoise(xPosition, zPosition)
          dataRow.push(value)

          baseVectors = []
          vectors = []
          rstep = Math.PI * 2 / 6
          for r in [0..Math.PI * 2 - rstep] by rstep
            vectors.push new THREE.Vector3(
              xPosition + Math.sin(r) * @tileSize / 2,
              value,
              zPosition + Math.cos(r) * @tileSize / 2)
            baseVectors.push new THREE.Vector3(
              xPosition + Math.sin(r) * @tileSize / 2,
              0,
              zPosition + Math.cos(r) * @tileSize / 2)

          for v in baseVectors
            geometry.vertices.push v
          for v in vectors
            geometry.vertices.push v

          l = geometry.vertices.length
          geometry.faces.push new THREE.Face3(l-6, l-5, l-4)
          geometry.faces.push new THREE.Face3(l-6, l-4, l-3)
          geometry.faces.push new THREE.Face3(l-6, l-3, l-2)
          geometry.faces.push new THREE.Face3(l-6, l-2, l-1)

          geometry.faces.push new THREE.Face3(l-6, l-12, l-11)
          geometry.faces.push new THREE.Face3(l-5, l-6, l-11)

          geometry.faces.push new THREE.Face3(l-5, l-11, l-10)
          geometry.faces.push new THREE.Face3(l-4, l-5, l-10)

          geometry.faces.push new THREE.Face3(l-4, l-10, l-9)
          geometry.faces.push new THREE.Face3(l-3, l-4, l-9)

          geometry.faces.push new THREE.Face3(l-3, l-9, l-8)
          geometry.faces.push new THREE.Face3(l-2, l-3, l-8)

          geometry.faces.push new THREE.Face3(l-2, l-8, l-7)
          geometry.faces.push new THREE.Face3(l-1, l-2, l-7)

          geometry.faces.push new THREE.Face3(l-1, l-7, l-12)
          geometry.faces.push new THREE.Face3(l-6, l-1, l-12)
        data.push(dataRow)
        if x < @chunkSize.height and new Date().getTime() - lastCalled > 100
          console.log("Setting timeout for " + (x+1))
          setTimeout((->
            console.log("I AM that settimeout")
            continueX(x + 1)
          ).bind(this))
          return
      console.log("out of the loop")
      ondone()
    ).bind(this)
    continueX(0)





class HexGame extends BaseGame
  constructor: (container, width, height, opt_scene, opt_camera) ->
    @chunkSize =
      height: 59
      width: 20
    @chunkManager = new ChunkManager(@scene, @chunkSize, 2)

    super(container, width, height, opt_scene, opt_camera)

    DEBUG.expose('scene', @scene)

    @person = new FirstPerson(container, @camera)
    @person.updateCamera()


  initGeometry: ->
    #@scene.add new THREE.Mesh(new THREE.SphereGeometry(1, 8, 8), new THREE.LineBasicMaterial({color: 0xff0000}))
    @terrain = []

  initLights: ->
    #@scene.add new THREE.AmbientLight(0x505050, 1, 50)
    light = new THREE.PointLight(0xffffff, 1, 50)
    light.position.x = 0
    light.position.z = 0
    light.position.y = 20
    @scene.add light
    DEBUG.expose('light', light)

    light2 = new THREE.PointLight(0xff0000, 1, 50)
    light2.position.x = 0
    light2.position.z = 10
    light2.position.y = 20
    @scene.add light2
    DEBUG.expose('light2', light2)

    @scene.add @dlight = new THREE.DirectionalLight(0xffffff, .5)
    @dlight.position.y = Math.sin(Math.PI / 4)
    @dlight.position.z = Math.cos(Math.PI / 4)
    DEBUG.expose('dlight', @dlight)

    @scene.add @dlightSphere = new THREE.Mesh(new THREE.SphereGeometry(1, 8, 8), new THREE.LineBasicMaterial({color: 0xffff00}))
    @dlightSphere.position.y = @dlight.position.y * 20
    @dlightSphere.position.z = @dlight.position.z * 20

  maybeMakeChunk: (chunkX, chunkY) ->
    if not @chunkManager.chunkExists(chunkX, chunkY)
      console.log("Creating chunk " + chunkX + ', ' + chunkY)
      chunk = @chunkManager.getChunk(chunkX, chunkY, ((chunk) ->
        for mesh in chunk.meshes
          @scene.add mesh
      ).bind(this))
      for mesh in chunk.meshes
        @scene.add mesh

  render: (delta) ->
    @person.update(delta)

    chunkX = Math.floor((@camera.position.z + @chunkManager.totalWidth / 2) / @chunkManager.totalWidth)
    chunkY = Math.floor((@camera.position.x + @chunkManager.totalHeight / 2) / @chunkManager.totalHeight)
    @maybeMakeChunk(chunkX, chunkY)
    # @maybeMakeChunk(chunkX+1, chunkY)
    # @maybeMakeChunk(chunkX+1, chunkY+1)
    # @maybeMakeChunk(chunkX, chunkY+1)
    # @maybeMakeChunk(chunkX-1, chunkY+1)
    # @maybeMakeChunk(chunkX-1, chunkY)
    # @maybeMakeChunk(chunkX-1, chunkY-1)
    # @maybeMakeChunk(chunkX, chunkY-1)
    # @maybeMakeChunk(chunkX+1, chunkY-1)

    @renderer.renderer.render(@scene, @camera)

p.provide('HexGame', HexGame)
