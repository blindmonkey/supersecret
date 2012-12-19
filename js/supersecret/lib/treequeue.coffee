lib.export('TreeDeque', class TreeDeque
  constructor: ->
    @length = 0
    @listSize = 200
    @data = []

  forEach: (f) ->
    for list in @data
      for item in list
        f(item)

  push: (item) ->
    if @data.length == 0
      @data.push([item])
    else
      lastList = @data[@data.length-1]
      if lastList.length == @listSize
        @data.push([item])
      else
        lastList.push(item)
    @length++

  pop: ->
    throw 'Cannot pop from an empty queue.' if @data.length == 0
    item = null
    list = @data[@data.length-1]
    if list.length == 1
      item = list[0]
      @data.pop()
    else
      item = list.pop()
    @length--
    return item

  pushFront: (item) ->
    if @data.length == 0
      @data.push([item])
    else
      list = @data[0]
      if list.length == @listSize
        @data.splice(0, 0, [item])
      else
        list.splice(0, 0, item)
    @length++

  popFront: ->
    throw 'Cannot pop from an empty queue.' if @data.length == 0
    item = null
    list = @data[0]
    if list.length == 1
      item = list[0]
      @data.shift()
    else
      item = list.shift()
    @length--
    return item

)
