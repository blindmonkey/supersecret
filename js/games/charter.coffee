require('two/base')
require('producers/producers')
require('util/set')

class Charter
  constructor: (definitions, transforms) ->
    @graph = new producers.Graph()
    @definitions = definitions
    for name, transform of transforms
      deps = Charter.getDeps(transform).toArray()
      @graph.add name, deps, do (name, deps, transform) -> (values...) ->
        throw "blah" if deps.length != values.length
        args = {}
        for dep, i in deps
          value = values[i]
          args[dep] = value

  @getDeps: (transform) ->
    deps = new Set()
    for prop, value of transform
      if typeof value === 'string'
        svalue = value.split('.')[0..-2].join('.')
      else if typeof value === 'object'
        subdeps = Charter.getDeps(value)
        deps.unionThis(subdeps)
      else
        throw "Unknown definition type for " + value
    return deps








exports.Game = class CharterGame extends BaseGame
  postinit: ->
    data1 = [{
      id: 1
      x: 3
    }, {
      id: 2
      x: 4
    }]
    data2 = [{
      id: 1
      y: 4
    }, {
      id: 2
      y: 4.5
    }]

    new producers.Producer 'data', [], ->
      return data

    new producers.Producer 'Circle', ['data'], (data) ->
      return for item in data
        oitem =
          x: item.x
          y: item.y
          size: item.size or 3


  update: (delta) ->
    @context.fillStyle = '#000'
    @context.fillRect(0,0,@context.canvas.width, @context.canvas.height)
