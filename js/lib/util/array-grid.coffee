require('util/grid')

exports.ArrayGrid = class extends Grid
  constructor: (dim, opt_size) ->
    super(dim, opt_size)
    throw "Infinite mode isn't supported for array grids" if @isInfinite
    @grid = []
    size = 1
    for s in @size
      size *= s
    for i in [1..size]
      @grid.push null

  isValid: (coords...) ->
    for c in [0..coords.length - 1]
      coord = coords[c]
      size = @size[c]
      continue if size == Infinity
      if size instanceof Array
        return false if coord < size[0] or coord > size[1]
      else if size instanceof Object
        return false if coord < size.min or coord > size.max
      else
        return false if coord >= size or coord < 0
    return true

  getCellKey: (coords...) ->
    ###
    1d: ar[x]
    2d: ar[y*w + x]
    3d: ar[z*w*h + y*w + x]
    #COPOUT
    ###
    # if @dim == 1
    #   return coords[0]
    # else if @dim == 2
    #   return coords[1] * @size[0] + coords[0]
    # else if @dim == 3
    #   return coords[2] * @size[1] * @size[0] + coords[1] * @size[0] + coords[0]

    key = 0
    for i in [1..coords.length]
      coord = coords[i-1]
      for j in [0..i-1]
        coord *= @size[j]
      key += coord
    return key
