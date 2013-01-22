exports.generateId = (obj) ->
  if typeof(obj) == 'number'
    return 'number' + obj
  else if typeof(obj) == 'string'
    return 'string' + obj
  else
    return 'object' + JSON.stringify(obj)
