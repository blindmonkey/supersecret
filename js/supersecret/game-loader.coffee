getQueryParams = ->
  query = window.location.href.split('?').splice(1).join('?')
  components = query.split('&')
  params = {}
  for component in components
    s = component.split('=')
    continue if s.length == 0
    if s.length == 1
      params[s] = true
    else
      key = s[0]
      v = s.splice(1).join('=')
      params[s] = v
  return params

window.lib = {
  cache: {}
  loading: {}
  callbacks: []
}

window.lib.export = (name, object) ->
  window[name] = object

window.lib.load = (names..., callback) ->
  if typeof callback == 'string'
    names.push callback
  else
    lib.callbacks.push callback
  for name in names
    continue if name of window.lib.cache or name of window.lib.loading
    console.log("Loading " + name)
    #console.log("Requesting " + name + '.coffee')
    lib.loading[name] = true
    CoffeeScript.load('js/supersecret/lib/' + name + '.coffee',
      do (name) -> ->
        console.log('Loaded ' + name)
        delete lib.loading[name]
        lib.cache[name] = true
        allLoaded = true
        for n of lib.loading
          console.log(name + ": still loading " + n)
          allLoaded = false
          break
        if allLoaded
          console.log("Loading complete. Callbacks called from load request for " + names)
          for cb in lib.callbacks
            cb()
    )



$.ajax('js/supersecret/game-list.json').done((gamelist) ->
  games = (if typeof(gamelist) == 'string' then JSON.parse(gamelist) else gamelist).games
  params = getQueryParams()
  gameIndex = games.indexOf(params.game)
  if gameIndex >= 0
    CoffeeScript.load('js/supersecret/games/' + params.game + '.coffee', ->
      console.log('Game loaded');
    )
  else
   console.error('Game ' + params.game + ' not found')
)
