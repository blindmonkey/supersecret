exports.Queue = class Queue
  constructor: ->
    @head = null
    @tail = null
    @length = 0

  forEach: (f) ->
    p = @head
    while p
      f(p.first)
      p = p.rest

  toString: ->
    return JSON.stringify(@head)

  push: (item) ->
    if not @head?
      @head =
        first: item
        rest: null
      @tail = @head
    else
      newtailrest =
        first: item
        rest: null
      @tail.rest = newtailrest
      @tail = @tail.rest
    @length++

  pushFront: (item) ->
    if @length > 0
      @head =
        first: item
        rest: @head
      @length++
    else
      @push item

  pop: ->
    item = @head.first
    @head = @head.rest
    if not @head? or not @head.rest?
      @tail = @head
    @length--
    return item
