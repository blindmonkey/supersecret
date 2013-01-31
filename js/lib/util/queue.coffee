exports.Queue = class Queue
  constructor: ->
    @head = null
    @tail = null
    @length = 0

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

  pop: ->
    item = @head.first
    @head = @head.rest
    if not @head? or not @head.rest?
      @tail = @head
    @length--
    return item
