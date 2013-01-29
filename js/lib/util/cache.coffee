require('id')

exports.cached = (f) ->
  cache = {}
  return (args...) ->
    # try
    argsId = generateId(args)
    # catch e
    #   console.error('Error with ', args...)
    #   argsId = undefined

    if argsId
      return cache[argsId] if argsId of cache
      return cache[argsId] = f(args...)
    else
      f(args...)
