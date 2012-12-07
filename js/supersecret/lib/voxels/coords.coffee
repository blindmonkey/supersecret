lib.export('getChunkCoords', (chunkSize, worldX, worldY, worldZ) ->
  return [
    Math.floor(worldX / chunkSize[0])
    Math.floor(worldY / chunkSize[1])
    Math.floor(worldZ / chunkSize[2])]
)


lib.export('getWorldCoords', (chunkSize, x, y, z, chunkX, chunkY, chunkZ) ->
  return [
    x + chunkX * chunkSize[0]
    y + chunkY * chunkSize[1]
    z + chunkZ * chunkSize[2]]
)

lib.export('getLocalCoords', (chunkSize, worldX, worldY, worldZ) ->
  [cx, cy, cz] = getChunkCoords(chunkSize, worldX, worldY, worldZ)
  return [
    worldX - cx * chunkSize[0]
    worldY - cy * chunkSize[1]
    worldZ - cz * chunkSize[2]]
)
