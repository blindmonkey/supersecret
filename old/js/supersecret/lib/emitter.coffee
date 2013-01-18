lib.load(
  'events'
  ->
    lib.export('Emitter', class Emitter extends EventManagedObject
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
        console.log('adding particle', @pool.length)
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
            shouldDie.push(i-1) if data.kill
          if shouldDie.length > 0
            for i in [shouldDie.length..1]
              @killParticle shouldDie[i - 1]
          @geometry.verticesNeedUpdate = true
    )
)