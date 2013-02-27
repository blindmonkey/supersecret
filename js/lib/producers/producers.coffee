require('util/graph')

producers =
  nodes: {}
  graph: new Graph()

class ProducerGraph
  constructor: ->
    @bound = {}
    @nodes = {}
    @graph = new Graph()

  add: (name, deps, func) ->
    throw "Node #{name} already exists" if name of @nodes
    @graph.add name if not @graph.exists name

    for dep in deps
      @graph.link name, dep
    @nodes[name] =
      deps: deps
      func: func

  bind: (name, value) ->
    @bound[name] = value

  run: (name) ->
    sorted = @graph.sort(name)
    sorted.forEach (name) =>
      return if name of @bound
      node = @nodes[name]
      if not node
        console.log(name)
        throw "No node by name #{name} and this name was not bound."
      hasAllDeps = false
      args = []
      for dep in node.deps
        if dep not of @bound
          throw "Something went wrong"
        args.push @bound[dep]
      @bound[name] = node.func(args...)
    return @bound[name]

exports.producers = producers
exports.producers.Graph = ProducerGraph

exports.main = ->
  g = new producers.Graph()
  g.add('p4', ['p5'], (p5) ->
    return 3 + p5
  )
  g.add('p3', ['p4'], (p4) ->
    return p4 * 3)
  g.add('p2', [], ->
    return 7)
  g.add('p1', ['p2', 'p3'], (p2, p3) ->
    return p2 * p3
  )

  g.bind('p5', 1)
  console.log g.run('p1')
