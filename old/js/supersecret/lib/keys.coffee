lib.export('KeyManager', class KeyManager
  constructor: ->
    @keymap = {}
    @down = {}

    $(document).keydown (e) =>
      @pushDown e.keyCode

    $(document).keyup (e) =>
      @pushUp e.keyCode

  getAction: (key) ->
    action = @keymap[key]
    if action not of @down
      @down[action] =
        map: {}
        length: 0
    return @down[action]

  pushDown: (key) ->
    action = @getAction(key)
    if key not of action.map
      action.map[key] = true
      action.length++

  pushUp: (key) ->
    action = @getAction(key)
    if key of action.map
      delete action.map[key]
      action.length--

  bind: (keys..., action) ->
    for key in keys
      @keymap[key] = action

  unbind: (keys...) ->
    for key in keys
      delete @keymap[key]

  isActive: (action) ->
    return false if action not of @down
    return @down[action].length > 0
)