lib.export('random', {
  random: Math.random
  range: (start, end) ->
    if not end?
      end = start
      start = 0
    return Math.floor(Math.random() * (end - start)) + start
  choice: (l) -> l[Math.floor(Math.random() * l.length)]
  shuffle: (l) ->
    newl = (i for i in l)
    swaps = 10
    for swap in [swaps..0]
      i = Math.floor(Math.random() * newl.length)
      j = Math.floor(Math.random() * newl.length)
      if i != j
        t = newl[i]
        newl[i] = newl[j]
        newl[j] = t
    return newl
})
