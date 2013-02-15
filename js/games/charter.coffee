require('two/base')
require('producers/producers')
require('util/set')
require('util/map')

charter = {}
class charter.Data
  constructor: (data) ->
    @data = []
    @index = {}
    @spec = new charter.Spec()
    if data?
      for item in data
        @add(item)

  setSpec: (spec) ->
    @spec = spec

  isValid: (item) ->
    return @checkAgainstSpec(item).invalidType is 0

  checkAgainstSpec: (item) ->
    report =
      invalidType: 0
      extraProperties: 0
    for property, value of item
      if not @spec.isDefined(property)
        report.extraProperties++
      else if not @spec.isCorrectType(property, value)
        report.invalidType++
    return report

  add: (item) ->
    throw "Invalid data for #{item}" if not @isValid(item)
    for prop, value of item
      if prop not of @index
        @index[prop] = new Map()
      if prop not of @spec
        if typeof value is 'number' or typeof value is 'string'
          @spec.set(prop, {type: typeof value})
        else
          throw "Invalid type for property: #{value}"
      valueIndices = @index[prop].get(value) or []
      valueIndices.push(@data.length)
      @index[prop].put(value, valueIndices)
    @data.push item

  getValues: (property) ->
    values = @index[property]
    return undefined if not values
    return values.keys()

  getIndices: (property, value) ->
    return @index[property].get(value)

  getRow: (index) ->
    return @data[index]

class charter.Spec
  constructor: (spec) ->
    @spec = {}
    @set p, v for p, v of spec

  assertKnownTypeName: (name) ->
    throw "Unknown type name: #{name}" if not (name is 'number' or name is 'string')

  assertKnownType: (item) ->
    @assertKnownTypeName typeof item

  isCorrectType: (property, item) ->
    spec = @spec[property]
    return undefined if not spec or not spec.type
    return typeof item is spec.type

  isDefined: (property) ->
    return property of @spec

  set: (property, spec) ->
    return if not spec.type
    @assertKnownType(spec.type)
    @spec[property] =
      type: spec.type

  get: (property, opt_attr) ->
    return @spec[property] and @spec[property][opt_attr]

class charter.Charter
  constructor: (definitions, transforms) ->
    @definitions = definitions
    @transforms = transforms

  @getDeps: (transform) ->
    deps = new Set()
    for prop, value of transform
      if typeof value is 'string'
        svalue = value.split('.')[0..-2].join('.')
      else if typeof value is 'object'
        subdeps = Charter.getDeps(value)
        deps.unionThis(subdeps)
      else
        throw "Unknown definition type for " + value
    return deps

  render: (outputTypes, inputData, dataMap, dataRelationships) ->
    data = {}
    for dataName, dataArray of inputData
      data[dataName] = if dataArray instanceof charter.Data then\
        dataArray else new charter.Data(dataArray)

    knownNames = new Set()
    knownNames.add Object.keys(@definitions)...
    knownNames.add Object.keys(dataMap)...
    knownNames.add Object.keys(inputData)...
    knownNames.add Object.keys(outputTypes)...

    parseDependency = (name) ->
      splitName = name.split('.')
      for i in [0..splitName.length - 2]
        objectName = splitName[0..i].join('.')
        if knownNames.contains(objectName)
           return [objectName].concat(splitName[i+1..])
      return splitName

    class Reference
      constructor: (path) ->
        if path instanceof Array
          @path = path
        else if typeof path is 'string'
          @path = parseDependency(path)

      @isReference: (maybeReference) ->
        return !!((typeof maybeReference is 'string' and parseDependency(maybeReference)) or path instanceof Array)

    class Transform
      constructor: (definitions, transform) ->
        @definitions = definitions
        @dependencies = Transform.getDependencies(transform)
        # A function that accepts the same number of arguments as it has
        # dependencies; in the same order.
        @transform = (args...) =>
          throw "Error" if args.length isnt @dependencies.length
          dependencies = {}
          for dependency, index in @dependencies
            dependencies[dependency[0]] = args[index]

          object = {}
          for property, dependency of transform
            value = undefined
            if Reference.isReference(dependency)
              ref = new Reference(dependency)
              if ref.path[0] not of dependencies
                throw "Unloaded reference: #{ref.path[0]}"
              value = ref.path[0]
              if ref.path.length > 1
                (value = value[p] if i > 0) for p, i in ref.path

              if not value and @definitions[ref]
            object[property] = value
          return object

      @getDependencies = (transform) ->
        dependencies = new Set()
        for property of transform
          dependency = undefined
          if Reference.isReference(transform[property])
            dependency = new Reference(transform[property])
          else
            throw "Unknown transform type"
          dependencies.add dependency.path[0] if dependency
        return dependencies.toArray()

    # So we need to compile all the definitions that we have.
    graph = new producers.Graph()
    definitions = {}
    transforms = {}
    addDefinition = (name, definition) ->
      graph.add name
      definitions[name] = if definition instanceof charter.Spec then\
          definition else new charter.Spec(definition)
    addTransform = (name, transform) ->
      allTransforms = transforms[name] or []
      # If the transform is a string or an array, it's a dependency
      transform = new Transform(definitions, transform)
      allTransforms.push transform

      transforms[name] = allTransforms


      graph.add name, transform.dependencies, (args...) ->
        dataIndices = []
        for arg, index in args
          dataIndices.push(index) if arg instanceof charter.Data
        if dataIndices.length > 1
          throw "Things can only have one non-singular dependency for now."
        if dataIndices.length is 0
          return transform.transform(args...)

        output = new charter.Data()
        for dataIndex in dataIndices
          data = args[dataIndex]
          for row, index in data.data
            newargs = for arg, argindex in args
              if argindex is dataIndex then row else arg
            output.add transform.transform(newargs...)
        return output

    addDefinition(name, definition) for name, definition of @definitions
    addDefinition(name, charterData.spec) for name, charterData of data

    addTransform(name, transform) for name, transform of @transforms








Charter = charter.Charter

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

    definitions =
      Circle:
        x: 'number'
        y: 'number'
        size: 'number'
      Point:
        x: 'number'
        y: 'number'

    transforms =
      Circle:
        x: ['Point', 'x']
        y: ['Point', 'y']
        size: 5

    map =
      Point:
        x: 'data1.x'
        y: 'data2.y'

    relationships =
      'data1.id': 'data2.id'

    data =
      data1: data1
      data2: data2

    data =
      data1: [{
        x: 3
        y: 4
      }, {
        x: 4
        y: 4.5
      }]

    @charter = new Charter(definitions, transforms)
    # Charter.render(
    #   Array.<string>   A list of things to get
    #
    # )
    @charter.render ['Circle'], data, map, relationships



  update: (delta) ->
    @context.fillStyle = '#000'
    @context.fillRect(0,0,@context.canvas.width, @context.canvas.height)
