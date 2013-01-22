require('time/now')

exports.Timer = class
  constructor: ->
    @timers = {}

  get: (timer) ->
    t = @timers[timer]
    return t if t is undefined
    if t.going
      return now() - t.start
    return t.end - t.start

  start: (timer) ->
    @timers[timer] = t = {}
    t.start = now()
    t.going = true
    t.total = 0
    t.laps = []

  stop: (timer) ->
    t = @timers[timer]
    return t if t is undefined
    t.going = false
    t.end = now()
    t.total += t.end - t.start
    return t.end - t.start

  total: (timer) ->
    t = @timers[timer]
    return t if t is undefined
    return t.total

  laps: (timer) ->
    return (lap for lap in @timers[timer].laps)

  lap: (timer) ->
    t = @timers[timer]
    return t if t is undefined
    t.laps.push (now() - t.start)
