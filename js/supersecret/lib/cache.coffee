lib.load('id')

lib.export('cached', (f) ->
  cache = {}
  return (args...) ->
    argsId = generateId(args)
    return cache[argsId] if argsId of cache
    return cache[argsId] = f(args...)
)