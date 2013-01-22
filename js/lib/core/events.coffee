exports.Events = class EventManagedObject
  constructor: ->
    @events = {}

  handleEvent: (event, handler) ->
    if event not of @events
      @events[event] = []
    @events[event].push handler

  fireEvent: (event, args...) ->
    if event of @events
      (handler(args...) for handler in @events[event])
