require('util/id')
require('util/set')
require('util/queue')

exports.Graph = class Graph
  constructor: ->
    @nodes = {}

  existsId: (id) ->
    return id of @nodes

  exists: (node) ->
    id = generateId(node)
    return @existsId(id)

  contains: (node) ->
    @exists(node)

  add: (node) ->
    id = generateId(node)
    throw "Node already exists." if @existsId(id)
    @nodes[id] =
      node: node
      edges: new Set()
      back: new Set()

  getById: (id) ->
    return @nodes[id]

  edgesById: (id) ->
    return @nodes[id].edges

  edges: (node) ->
    @edgesById(generateId(node))


  get: (node) ->
    return @nodes[generateId(node)]

  link: (node1, node2) ->
    node1id = generateId(node1)
    node2id = generateId(node2)
    @add(node1) if not @existsId(node1id)
    @add(node2) if not @existsId(node2id)
    node1 = @getById(node1id)
    node2 = @getById(node2id)
    node1.edges.add node2
    node2.back.add node1

  unlink: (node1, node2) ->
    node1id = generateId(node1)
    node2id = generateId(node2)
    return if not @existsId(node1id) or not @existsId(node2id)
    node1 = @getById(node1id)
    node2 = @getById(node2id)
    node1.edges.remove node2
    node2.back.remove node1

  traverse: (start, f) ->
    seen = new Set()
    queue = new Queue()
    queue.push start
    while queue.length > 0
      node = queue.pop()
      continue if seen.contains(node)
      seen.add(node)
      inode = @get(node)
      if not inode
        console.error(node)
        throw "A node that is depended upon (#{inode}) could not be found."
      return if f(node) is false
      inode.edges.forEach (edge) ->
        queue.push edge.node

  sort: (start) ->
    g = {}
    maybeCreateNode = (node) ->
      id = generateId(node)
      if id not of g
        g[id] =
          indegrees: 0
          edges: []
    nodePlusOne = (node) ->
      maybeCreateNode node
      id = generateId(node)
      g[id].indegrees++
    addEdge = (node, node2) ->
      maybeCreateNode node
      id = generateId(node)
      g[id].edges.push node2
    getG = (node) ->
      id = generateId(node)
      return g[id]

    unprocessed = new Queue()
    nodeCount = 0
    @traverse start, (node) =>
      nodeCount++
      unprocessed.push node
      maybeCreateNode node
      @edges(node).forEach (edge) ->
        addEdge node, edge.node
        nodePlusOne edge.node

    processed = new Queue()
    queue = new Queue()
    remaining = new Queue()
    while processed.length < nodeCount
      while unprocessed.length > 0
        node = unprocessed.pop()
        if getG(node).indegrees is 0
          queue.push node
        else
          remaining.push node

      [remaining, unprocessed] = [unprocessed, remaining]
      if queue.length is 0
        throw "There is a cycle"
      node = queue.pop()
      edges = getG(node).edges
      for edge in edges
        getG(edge).indegrees--
      processed.pushFront node

    return processed

exports.main = ->
  g1 = new Graph()
  g1.add 'node1'
  g1.add 'node2'
  g1.link 'node1', 'node2'
  debugger
  console.log(g1.sort('node1'))



