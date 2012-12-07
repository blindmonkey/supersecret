lib.load('noisegenerator', 'voxels/coords')

lib.export('WorldGenerator', class WorldGenerator
  constructor: (chunkSize) ->
    @chunkSize = chunkSize
    @seaLevel = @chunkSize[1] / 2
    @scale = [2, 1, 2]
    @noise = new NoiseGenerator(new SimplexNoise(), [{
        scale: 1 / 32
      }, {
        scale: 1 / 64
        multiplier: 1 / 2
      }, {
        scale: 1 / 128
        multiplier: 1 / 3
      }, {
        scale: 1 / 256
        multiplier: 1 / 4
        }])

  getVoxel: (x, y, z) ->
    [cx, cy, cz] = getChunkCoords(@chunkSize, x, y, z)
    # [lx, ly, lz] = getLocalCoords(@chunkSize, x, y, z)
    n = @noise.noise3D(
      x / @scale[0],
      y / @scale[1],
      z / @scale[2]) - (y + cy * @chunkSize[1] - @seaLevel) / 32

    return if n < 0 then null else {
      smooth: true
      color: if n < .2 then 0xff0000 else if n < .4 then 0xffff00 else if n < .6 then 0x0000ff else 0x00ff00
    }
)
