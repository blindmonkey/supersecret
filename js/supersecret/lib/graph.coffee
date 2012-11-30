lib.load('id', 'set')
lib.export('Graph', class Graph
  constructor: ->
    @nodes = {}

  addNode: (obj) ->
    id = generateId(obj)
    if not @exists(obj)
      @nodes[id] = {data: obj, connections: new Set()}
    return id

  exists: (obj) ->
    id = generateId(obj)
    return id of @nodes

  connect: (obj1, obj2) ->
    id1 = @addNode(obj1)
    id2 = @addNode(obj2)
    @nodes[id1].connections.add(obj2)
    @nodes[id2].connections.add(obj1)

  disconnect: (obj1, obj2) ->
    id1 = generateId(obj1)
    id2 = generateId(obj2)
    @nodes[id1].connections.remove(obj2)
    @nodes[id2].connections.remove(obj1)

  connected: (obj1, obj2) ->
    id1 = generateId(obj1)
    id2 = generateId(obj2)
    return id1 of @nodes and id2 of @nodes and @nodes[id1].connections.contains(obj2)

  connections: (obj) ->
    id = generateId(obj)
    out = []
    return out if id not of @nodes
    @nodes[id].connections.forEach((item) ->
      out.push item)
    return out)
