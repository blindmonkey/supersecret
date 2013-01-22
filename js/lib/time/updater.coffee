require('time/now')

exports.Updater = class
  constructor: (frequency) ->
    @frequency = frequency
    @updates = {}

  setFrequency: (id_or_frequency, maybe_frequency) ->
    frequency = id_or_frequency or 5000
    id = null
    if maybe_frequency
      id = id_or_frequency
      frequency = maybe_frequency
    if id?
      if id not of @updates
        @updates[id] = {
          updated: 0
        }
      @updates[id].frequency = frequency
    else
      @frequency = frequency

  update: (id, message...) ->
    if id not of @updates
      @updates[id] = {frequency: @frequency, updated: 0}
    if now() - @updates[id].updated > @updates[id].frequency
      realMessage = []
      for m in message
        if m instanceof Function
          m = m()
          if m
            realMessage.push m
        else
          realMessage.push m
      console.log(id + ':', realMessage...)
      @updates[id].updated = now()
