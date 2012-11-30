lib.load('events', ->
  lib.export('Grid', class Grid extends EventManagedObject
    constructor: (dim, opt_size) ->
      super()
      @dimensions = dim
      @grid = {}
      @isInfinite = false
      if opt_size
        @size = opt_size
        @isInfinite = true
        for size in @size
          if size != Infinity
            @isInfinite = false
      else
        @size = (Infinity for d in [0..dim-1])
        @isInfinite = true
      @limits = ({min: Infinity, max: -Infinity} for d in [0..dim-1])
      @hasData_ = false

    hasData: ->
      return @hasData_

    getCellKey: (coords...) ->
      key = ''
      for coord in coords
        key += '/' if key
        key += coord.toString()
      return key

    isValid: (coords...) ->
      for c in [0..coords.length - 1]
        coord = coords[c]
        size = @size[c]
        continue if size == Infinity
        if size instanceof Object
          return false if coord < size.min or coord > size.max
        else
          return false if coord >= size or coord < 0
      return true

    updateLimits: (coords...) ->
      for c in [0..coords.length - 1]
        coord = coords[c]
        @limits[c].min = coord if coord < @limits[c].min
        @limits[c].max = coord if coord > @limits[c].max

    forEach: (f) ->
      forEachForCoord = ((coordIndex, coordList) ->
        for c in [@limits[coordIndex].min..@limits[coordIndex].max]
          if coordIndex < @limits.length - 1
            forEachForCoord(coordIndex + 1, coordList.concat([c]))
          else
            f(coordList.concat([c])...)
      ).bind(this)
      forEachForCoord(0, [])

    toArray: ->
      mapEachCoord = ((coordIndex, coords) ->
        r = []
        for c in [@limits[coordIndex].min..@limits[coordIndex].max]
          item = null
          if coordIndex < @limits.length - 1
            item = mapEachCoord(coordIndex + 1, coords.concat([c]))
          else
            item = @get(coords...)
          r.push item
        return r
      ).bind(this)
      return mapEachCoord(0, [])

    exists: (coords...) ->
      key = @getCellKey(coords...)
      return key of @grid

    get: (coords...) ->
      if not @isInfinite and not @isValid(coords...)
        throw 'Coordinate is out of bounds'
      if not @exists(coords...)
        @fireEvent('missing', coords...)
      key = @getCellKey(coords...)
      return @grid[key]

    set: (data, coords...) ->
      if not @isInfinite and not @isValid(coords...)
        throw 'Coordinate is out of bounds'
      @hasData_ = true
      @updateLimits(coords...)
      key = @getCellKey(coords...)
      previousValue = @grid[key]
      @grid[key] = data
      @fireEvent('set', data, coords...)
      return previousValue

    exists: (coords...) ->
      key = @getCellKey(coords...)
      return key of @grid
  ))
