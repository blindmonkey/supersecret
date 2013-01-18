lib.export('Tracker', class Tracker
  constructor: ->
    @vars = {}

  track: (m) ->
    for p of m
      @vars[p] = {min:Infinity, max:-Infinity} if p not of @vars
      i = @vars[p]
      v = m[p]
      if v < i.min
        i.min = v
      if v > i.max
        i.max = v

  get: (vars...) ->
    out = {}
    for v in vars
      i = @vars[v]
      val =
        min: i.min
        max: i.max
      return val if vars.length == 0
      out[v] = val
    return out
)
