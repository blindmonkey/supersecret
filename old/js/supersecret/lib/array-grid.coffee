lib.load('grid', ->
  lib.export('ArrayGrid', class ArrayGrid extends Grid
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
      key = 0
      for i in [1..coords.length]
        coord = coords[i-1]
        for j in [1..i]
          coord *= @size[j-1]
        key += coord
      return key
  )
)
