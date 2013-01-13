console.log('====== NOISEGENERATOR LOADINGGGS')

lib.export('NoiseGenerator', class NoiseGenerator
  constructor: (noise, description) ->
    @noise = noise
    @description = description

  getMaxValue: ->
    s = 0
    for layer in @description
      s += (layer.multiplier or 1)
    return s

  noise2D: (x, y) ->
    s = 0
    for layer in @description
      scale = layer.scale or 1
      offset = layer.offset or 0
      multiplier = layer.multiplier or 1
      n = @noise.noise2D(x * scale, y * scale) * multiplier - offset
      if layer.op
        s = layer.op(s, n)
      else
        s += n
    return s

  noise3D: (x, y, z) ->
    s = 0
    for layer in @description
      scale = layer.scale or 1
      offset = layer.offset or 0
      multiplier = layer.multiplier or 1
      s += @noise.noise3D(x * scale, y * scale, z * scale) * multiplier - offset
    return s

  noise4D: (x, y, z, w) ->
    s = 0
    for layer in @description
      scale = layer.scale or 1
      offset = layer.offset or 0
      multiplier = layer.multiplier or 1
      s += @noise.noise3D(x * scale, y * scale, z * scale, w * scale) * multiplier - offset
    return s
)
