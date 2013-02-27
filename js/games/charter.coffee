require('two/base')
require('producers/producers')
require('util/set')
require('util/map')

charter = {}
###
charter.Data = class Data
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
      if name not of transforms
        transforms[name] = []
      # If the transform is a string or an array, it's a dependency
      transforms[name].push new Transform(definitions, transform)

    addDefinition(name, definition) for name, definition of @definitions
    addDefinition(name, charterData.spec) for name, charterData of data

    addTransform(name, transform) for name, transform of @transforms

    for name, transformList of transforms
      do (name, transformList) ->
        dependencies = new Set()
        for transform in transformList
          dependencies.unionThis new Set(transform.dependencies)
        dependencies = dependencies.toArray()
        graph.add name, dependencies, (args...) ->
          depObj = {}
          dataIndices = []
          for arg, index in args
            dataIndices.push(index) if arg instanceof charter.Data
            depObj[dependencies[index].path[0]]
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
###

charter.Type =
  NUMBER: 'number'
  STRING: 'string'
  OBJECT: 'object'

# A definition is an object with a set of properties that have certain types
# and other constraints.
# Nested properties are not allowed.
# Among the primitive types,
charter.Definition = class Definition
  class Description
    constructor: (type) ->
      @type = type

    getType: ->
      return @type

    setType: (type) ->
      @type = type

  constructor: ->
    @properties = {}
    @keys =
      primary: Set()
      foreign: Set()

  @isPrimitiveType: (type) ->
    for t, s of charter.Type
      return true if type is s
    return false

  @isValuePrimitive: (value) ->
    return typeof value is 'number' or typeof value is 'string'

  @getValueType: (value) ->
    if typeof value is 'string'
      return charter.Type.STRING
    else if typeof value is 'number'
      return charter.Type.NUMBER
    else
      return charter.Type.OBJECT

  isCorrectType: (property, value) ->
    propertyType = @properties[property].getType()
    propertyIsPrimitive = Definition.isPrimitiveType(propertyType)
    return (typeof value is 'object' and not propertyIsPrimitive) or \
        (propertyIsPrimitive and Definition.isValuePrimitive(value))

  propertyExists: (name) ->
    return name of @properties

  setPropertyType: (property, type) ->
    @properties[property] = new Description() if not @propertyExists(property)
    @properties[property].setType(type)
    return @

  getPropertyType: (property) ->
    return @properties[property]

  setPrimaryKey: ->
  check: ->

charter.Data = class Data
  constructor: (data) ->
    @data = []
    @index = {}
    @spec = new charter.Definition()
    if data?
      for item in data
        @add(item)

  setSpec: (spec) ->
    @spec = spec
    return @

  isValid: (item) ->
    return @checkAgainstSpec(item).invalidType is 0

  checkAgainstSpec: (item) ->
    report =
      invalidType: 0
      extraProperties: 0
    for property, value of item
      if not @spec.propertyExists(property)
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
        if Definition.isValuePrimitive(value)
          @spec.setPropertyType(prop, Definition.getValueType(value))
        else
          throw "Invalid type for property: #{value}"
      valueIndices = @index[prop].get(value) or []
      valueIndices.push(@data.length)
      @index[prop].put(value, valueIndices)
    @data.push item
    return @

  getValues: (property) ->
    values = @index[property]
    return undefined if not values
    return values.keys()

  getIndices: (property, value) ->
    return @index[property].get(value)

  getRow: (index) ->
    return @data[index]

  getSize: ->
    return @data.length

# A transform is a function with a set of dependencies that outputs a certain
# definition.
charter.Transform = class Transform
  constructor: (outputType, dependencies) ->
    @outputType = outputType
    @dependencies = dependencies
    @transform = undefined

  setTransform: (transform) ->
    @transform = transform
    return @

  apply: (args...) ->
    dependencies = {}
    for dependency, index in dependencies
      dependencies[dependency] = args[index]

    return @transform dependencies


charter.Charter = class Charter
  constructor: (renderer) ->
    @graph = new producers.Graph()
    @bindings = {}
    @transforms = {}
    @definitions = {}
    @renderer = renderer

  addBinding: (name, binding) ->
    @bindings[name] = binding

  addDefinition: (name, definition) ->
    @definitions[name] = definition

  addTransform: (transform) ->
    @transforms[transform.outputType] = [] if transform.outputType not of @transforms
    @transforms[transform.outputType].push transform

  render: (data) ->
    definitions = {}
    for definition of @definitions
      definitions[definition] = @definitions[definition]

    bindings = {}
    for bindingName, binding of @bindings
      bindings[bindingName] = binding

    for name, table of data
      if table not instanceof charter.Data
        if table instanceof Array
          if typeof table[0] is 'object'
            source = table
            table = new charter.Data(data)
          else
            throw "You can't have an array of non objects"
      bindings[name] = table

    supportedTypes = new Set(@renderer.getSupported())
    targetTypes = []
    for definition of definitions
      if supportedTypes.contains(definition)
        targetTypes.push definition

    transforms = @transforms
    # TODO: Add transforms to the render method

    addTransformToGraph = (outputType, allTransformDependencies) =>
      @graph.add outputType, allTransformDependencies, (args...) ->
        dependencies = {}
        for dependency, index in allTransformDependencies
          dependencies[dependency] = args[index]

        dataDependencies = new Set()
        for dependencyName, dependency of dependencies
          if dependency instanceof charter.Data
            dataDependencies.add dependencyName

        # If there are no data dependencies, this object will be a
        # singleton.
        if dataDependencies.length is 0
          output = {}
        else
          output = []

        if dataDependencies.length > 1
          throw "Error"

        calcTransformArgs = (transform) ->
          return (dependencies[dependency] for dependency in transform.dependencies)

        debugger
        if dataDependencies.length is 0
          for transform in transforms[outputType]
            transformArgs = calcTransformArgs(transforms)
            transformOutput = transform.transform(transformArgs...)
            (output[p] = v for p, v of transformOutput)
        else
          dataDependencyName = dataDependencies.toArray()[0]
          dataDependency = dependencies[dataDependencyName]
          for dataIndex in [0..dataDependency.getSize() - 1]
            dataObject = dataDependency.getRow(dataIndex)
            outputObject = {}
            for transform in transforms[outputType]
              transformArgs = calcTransformArgs(transform)
              dataDependencyArgIndex = transformArgs.indexOf(dataDependency)
              if dataDependencyArgIndex >= 0
                transformArgs[dataDependencyArgIndex] = dataObject
              transformOutput = transform.transform(outputObject, transformArgs...)
              (outputObject[p] = v for p, v of transformOutput)
            output.push outputObject

        return new charter.Data(output) if output instanceof Array
        return output

    for outputType of transforms
      allTransformDependencies = new Set()
      for transform in transforms[outputType]
        for dependency in transform.dependencies
          allTransformDependencies.add dependency
      addTransformToGraph outputType, allTransformDependencies.toArray()

    for bindingName, binding of bindings
      @graph.bind bindingName, binding

    for outputType in targetTypes
      graphOutput = @graph.run outputType
      if graphOutput instanceof charter.Data
        for i in [0..graphOutput.getSize() - 1]
          @renderer.render outputType, graphOutput.getRow(i)
      else if graphOutput instanceof Array
        @renderer.render outputType, item for item in graphOutput
      else
        @renderer.render outputType, graphOutput

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

    debugger

    data =
      data1: new charter.Data().setSpec(new Definition()
        .setPropertyType('x', charter.Type.NUMBER)
        .setPropertyType('y', charter.Type.NUMBER)).add({
          x: 3
          y: 4
        }).add({
          x: 4
          y: 4.5
        })

    @renderQueue = []
    @charter = new Charter({
      getSupported: -> ['Circle']
      render: (type, object) =>
        @renderQueue.push [type, object]
    })

    @charter.addDefinition 'Point', new Definition()
        .setPropertyType('x', charter.Type.NUMBER)
        .setPropertyType('y', charter.Type.NUMBER)

    @charter.addDefinition 'Circle', new Definition()
        .setPropertyType('x', charter.Type.NUMBER)
        .setPropertyType('y', charter.Type.NUMBER)
        .setPropertyType('radius', charter.Type.NUMBER)
        .setPropertyType('color', charter.Type.STRING)

    # @charter.

    @charter.addDefinition('Axis', new Definition())
    @charter.addTransform new Transform('Circle', ['Point']).setTransform((myself, point) ->
      return {
        x: point.x
        y: point.y
        size: 5
      }
    )
    @charter.addTransform new Transform('Point', ['data1']).setTransform((myself, data1) ->
      return {
        x: data1.x
        y: data1.y
      }
    )
    @charter.render data



  update: (delta) ->
    @context.fillStyle = '#000'
    @context.fillRect(0,0,@context.canvas.width, @context.canvas.height)
    for [renderType, renderObject] in @renderQueue
      @context.fillStyle = '#0f0'
      @context.fillRect(renderObject.x, renderObject.y, renderObject.size, renderObject.size)

