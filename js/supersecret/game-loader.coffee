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

$.ajax('js/supersecret/game-list.json').done((gamelist) ->
  games = gamelist.games
  params = getQueryParams()
  gameIndex = games.indexOf(params.game)
  if gameIndex >= 0
    CoffeeScript.load('js/supersecret/games/' + params.game + '.coffee', ->
      console.log('Game loaded');
    )
  else
   console.error('Game ' + params.game + ' not found')
)
