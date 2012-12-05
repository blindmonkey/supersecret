lib.export('Updater', class Updater
  constructor: (frequency) ->
    @frequency = frequency
    @updates = {}

  setFrequency: (id_or_frequency, maybe_frequency) ->
    frequency = id_or_frequency
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
      #console.log(@updates[id].frequency, @updates[id].updated)
      console.log('id', message...)
      @updates[id].updated = now()

)
