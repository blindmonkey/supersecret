###
A QuadTree contains cells.
###

NODE = 'node'
LEAF = 'leaf'

class QuadTree
  constructor: (size, density) ->
    [@width, @height] = size
    @data = []
    @initData(@data)

  initData: (data) ->
    for x in [0..1]
      for y in [0..1]
        data[x][y] =
          value: undefined

  initCell: (cell, isLeaf) ->
    if not cell.type
      cell.type = if isLeaf then LEAF else NODE
      cell.data = @initData() if cell.type == NODE
    cell.content = undefined if not cell.content
    return cell

  cellExistsAtLevel: (coord, level) ->
    cell = @getCellAtLevel(coord, level)
    return !!cell

  iterate: (f, coord, maxlevel, createCells) ->
    minx = 0
    miny = 0
    maxx = @width
    maxy = @height
    data = @data
    [x, y] = coord
    maxlevel = 0 if maxlevel < 0
    while maxlevel >= 0
      centerx = (maxx - minx) / 2 + minx
      centery = (maxy - miny) / 2 + miny
      right = x >= centerx
      bottom = y >= centery
      minx = centerx if right
      miny = centery if bottom
      maxx = centerx if not right
      maxy = centery if not bottom
      xc = if right then 1 else 0
      yc = if bottom then 1 else 0
      cell = data[xc][yc]
      if not createCells and not data
        return
      else if not cell or (cell.type == LEAF and maxlevel > 0)
        obj = cell or {}
        cell = data[xc][yc] = @initCell(obj, maxlevel == 0)
      f(cell, {
        min: {x: minx, y: miny}
        max: {x: maxx, y: maxy}
      })

  getCellAtLevel: (coord, level, createCells) ->
    cellout = null
    boundsout = null
    @iterate((cell, bounds) ->
        cellout = cell
        boundsout = bounds
      , coord, level, createCells)
    return [cellout, boundsout]
    minx = 0
    miny = 0
    maxx = @width
    maxy = @height
    data = @data
    [x, y] = coord
    level = 0 if level < 0
    while level >= 0
      centerx = (maxx - minx) / 2 + minx
      centery = (maxy - miny) / 2 + miny
      right = x >= centerx
      bottom = y >= centery
      minx = centerx if right
      miny = centery if bottom
      maxx = centerx if not right
      maxy = centery if not bottom
      xc = if right then 1 else 0
      yc = if bottom then 1 else 0
      cell = data[xc][yc]
      if not createCells and not cell
        return undefined
      else if not cell
        cell = data[xc][yc] = @initCell({}, level == 0)
      if cell.type == LEAF and level > 0
        cell = @initCell(cell, false)
      data = cell.data
    return [cell, {
      min: {x:minx, y:miny}
      max: {x:maxx, y:maxy}
    }]

  setCellAtLevel: (cell, coord, level) ->
    if level <= 0
      bounds =
        min: {x: 0, y: 0}
        max: {x: @width, y: @height}
      data = @data
    else
      [parent, bounds] = @getCellAtLevel(coord, level - 1, true)
      @initCell(parent, false) if parent.type == LEAF
      data = parent.data
    centerx = (bounds.max.x - bounds.min.x) / 2 + bounds.min.x
    centery = (bounds.max.y - bounds.min.y) / 2 + bounds.min.y
    xc = if coord < centerx then 0 else 1
    yc = if coord < centery then 0 else 1
    data[xc][yc] = cell

  getContentAtLevel: (coord, level, createCells) ->
    cell = @getCellAtLevel(coord, level, createCells)
    return cell.content if cell
    return undefined

  setContentAtLevel: (content, coord, level) ->
    cell = @getCellAtLevel(coord, level, true)
    cell.content = content

  setTopLevelRect: (content, bounds) ->












lib.load(
  'base2d'
  'updater'
  ->
    supersecret.Game = class QuadGame extends Base2DGame
      postinit: ->
        @updater = new Updater(1000)
      update: (delta) ->
        @context.fillStyle = '#000'
        @context.fillRect(0,0,@context.canvas.width, @context.canvas.height)
        @updater.update('hi', 'hey')

)
