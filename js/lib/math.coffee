random =
  seed: (seed) ->
    oldrandom = Math.random
    Math.seedrandom(seed)
    random.random = Math.random
    Math.random = oldrandom
  mrandom: Math.random
  random: Math.random
  float: (a, b) ->
    if b
      start = a
      end = b
    else
      start = 0
      end = a
    return (end - start) * random.random() + start
  int: (a, b) ->
    return Math.floor(random.float(a, b))
  bool: ->
    return if random.int(2) then true else false
  choice: (list, opt_indexContainer) ->
    index = random.int(list.length)
    opt_indexContainer.index = index if opt_indexContainer
    return list[index]

exports.math = {
  distance: (args...) ->
    throw "Invalid number of arguments to distance" if args.length < 2
    allNumbers = do ->
      for arg in args
        if typeof arg isnt 'number'
          return false
      return true
    throw "You must specify arguments to distance" if args.length == 0
    throw "Invalid number of arguments: is odd (#{args.length})" if allNumbers and args.length % 2 isnt 0
    throw "Invalid number of arguments" if not allNumbers and args.length isnt 2
    throw "" if not allNumbers and (not args[0].length or not args[1].length or args[0].length != args[1].length)

    getVectorSize = if allNumbers then (-> args.length / 2) else -> args[0].length
    getVectorA = if allNumbers then ((i) -> args[i]) else (i) -> args[0][i]
    getVectorB = if allNumbers then ((i, size) -> args[i+size]) else (i) -> args[1][i]

    sum = 0
    length = getVectorSize()
    for i in [1..length]
      v1 = getVectorA(i-1, length)
      v2 = getVectorB(i-1, length)
      console.log(v1, v2)
      diff = v2 - v1
      sum += diff * diff
    return Math.sqrt(sum)

  random: random

  patterns:
    spiral: (cx, cy, distance, f) ->
      x = y = 0
      dx = 0
      dy = -1
      for i in [0..distance]
        return if f(cx + x, cy + y) is false
        if x == y or (x < 0 and x == -y) or (x > 0 and x == 1-y)
          [dx, dy] = [-dy, dx]
        x += dx
        y += dy
}
