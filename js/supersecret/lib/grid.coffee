GridID = 0

lib.load('events', ->
  lib.export('Grid', class Grid extends EventManagedObject
    constructor: (dim, opt_size) ->
      super()
      @id = GridID++
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

    getCoordsFromCellKey: (key) ->
      return (parseInt(coord) for coord in key.split('/'))

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

    forEachInRange: (f, ranges...) ->
      if ranges.length != @dimensions
        throw "Invalid number of ranges"
      forEachRange = ((dimIndex, dimList) ->
        range = null
        if ranges[dimIndex] != Infinity
          range = ranges[dimIndex]
        else if @size[dimIndex] != Infinity
          range = @size[dimIndex]
        else
          range = @limits[dimIndex]
        if typeof range == 'number'
          range =
            min: 0
            max: range - 1
        else if range instanceof Array
          range =
            min: range[0]
            max: range[1]
        for c in [range.min..range.max]
          if dimIndex < @dimensions - 1
            forEachRange(dimIndex + 1, dimList.concat([c]))
          else
            f(dimList.concat([c])...)
      ).bind(this)
      forEachRange(0, [])



    updateLimits: (coords...) ->
      for c in [0..coords.length - 1]
        coord = coords[c]
        @limits[c].min = coord if coord < @limits[c].min
        @limits[c].max = coord if coord > @limits[c].max

    forEachChunk: (f) ->
      for cid of @grid
        coords = @getCoordsFromCellKey(cid)
        return if f(coords...) is false

    forEach: (f) ->
      forEachForCoord = ((coordIndex, coordList) ->
        for c in [@limits[coordIndex].min..@limits[coordIndex].max]
          if coordIndex < @limits.length - 1
            forEachForCoord(coordIndex + 1, coordList.concat([c]))
          else
            f(coordList.concat([c])...)
      ).bind(this)
      forEachForCoord(0, [])

    forEachAsync: (f, callback) ->
      lastUpdated = new Date().getTime()
      forEachForCoord = ((coordIndex, coordList, start) ->
        for c in [start..@limits[coordIndex].max]
          if coordIndex < @limits.length - 1
            forEachForCoord(coordIndex + 1, coordList.concat([c]))
          else
            f(coordList.concat([c])...)
          if new Date().getTime() - lastUpdated > 100 and @limits[coordIndex].max - c > 10
            lastUpdated = new Date().getTime()
            setTimeout(-> forEachForCoord(coordIndex, coordList, c + 1))
            return
        callback()
      ).bind(this)
      forEachForCoord(0, [], 0)

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

    keyExists: (key) ->
      return key of @grid

    get: (coords...) ->
      if not @isInfinite and not @isValid(coords...)
        throw 'Coordinate is out of bounds'
      key = @getCellKey(coords...)
      if not @keyExists(key)
        @fireEvent('missing', coords...)
      return @grid[key]

    set_: (data, coords...) ->
      if not @isInfinite and not @isValid(coords...)
        throw 'Coordinate is out of bounds'
      @hasData_ = true
      @updateLimits(coords...)
      key = @getCellKey(coords...)
      previousValue = @grid[key]
      @grid[key] = data
      return previousValue

    set: (data, coords...) ->
      previousValue = @set_(data, coords...)
      @fireEvent('set', previousValue, data, coords...)
      return previousValue

    exists: (coords...) ->
      key = @getCellKey(coords...)
      return key of @grid
  ))
