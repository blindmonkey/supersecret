assert = (message, expr) ->
  if not expr
    expr = message
    message = null
  if not expr
    s = "Assertion failed"
    if message
      s += ": #{message}"
    throw s

class Expr
  constructor: ->
    @postprocess and @postprocess()

  negate: ->
    return new Neg(this)

class NaryOperator extends Expr
  constructor: (components...) ->
    @components = components
    super()

  simplify: ->
    @components = (formula.simplify(component) for component in @components)
    return this

  compose: ->
    throw "Not implemented."

class UnaryOperator extends NaryOperator
  constructor: (component) ->
    assert component
    super(component)



class Call extends NaryOperator
  constructor: (name, components...) ->
    super(components...)
    @name = name

  negative: -> false

  compose: ->
    return "#{@name}(#{(formula.compose(c) for c in @components).join(', ')})"

class Neg extends UnaryOperator
  simplify: ->
    super()
    assert @components.length == 1
    if @components[0] instanceof Neg
      return @components[0].components[0]
    return @

  negate: ->
    return @components[0]

  negative: ->
    return @simplify() instanceof Neg

  compose: ->
    return '-' + formula.compose(@components[0])


class Eq extends NaryOperator
  compose: ->
    (formula.compose(c) for c in @components).join(' = ')

class Add extends NaryOperator
  postprocess: ->
    newcomponents = []
    for component in @components
      if component instanceof Add
        newcomponents.push component.components...
      else
        newcomponents.push component
    @components = newcomponents

  negative: -> false

  compose: ->
    s = ''
    for component in @components
      isNegative = formula.negative(component)
      if s and isNegative
        s += ' - '
        component = component.components[0]
      else if s
        s += ' + '
      s += formula.compose(component)
    return s


class Mul extends NaryOperator
  postprocess: ->
    newcomponents = []
    for component in @components
      if component instanceof Mul
        newcomponents.push component.components...
      else
        newcomponents.push component
    @components = newcomponents

  simplify: ->
    super()
    negCount = 0
    newcomponents = []
    constant = 1
    for component in @components
      if formula.negative(component)
        component = formula.negate(component)
        negCount++
      if formula.number(component)
        constant *= component
        component = null
      if component
        newcomponents.push component
    newcomponents.splice(0, 0, constant) if constant isnt 1

    r = new Mul(newcomponents...)
    if negCount % 2
      r = new Neg(r)
    return r

  negative: ->
    negCount = 0
    for component in @components
      if formula.negative(component)
        negCount++
    return !!(negCount % 2)

  compose: ->
    (formula.compose(c) for c in @components).join(' * ')




f =
  eq: (args...) -> new Eq(args...)
  add: (args...) -> new Add(args...)
  mul: (args...) -> new Mul(args...)
  neg: (arg) -> new Neg(arg)
  call: (name, args...) -> new Call(name, args...)



formula =
  f: f
  negative: (expr) ->
    return expr < 0 if typeof expr is 'number'
    return expr[0] == '-' if typeof expr is 'string'
    return expr.negative()
  negate: (expr) ->
    return -expr if typeof expr is 'number' and expr < 0
    return f.neg(expr) if typeof expr is 'number' or typeof expr is 'string'
    return expr.negate()

  number: (expr) ->
    return typeof expr is 'number'

  simple: (expr) ->
    return typeof expr is 'number' or typeof expr is 'string'
  simplify: (expr) ->
    if formula.simple(expr)
      if typeof expr is 'number' and expr < 0
        return new Neg(-expr)
      if typeof expr is 'string' and expr[0] is '-'
        return new Neg(expr.slice(1))
      return expr
    return expr.simplify()
  compose: (expr) ->
    return String(expr) if formula.simple(expr)
    return expr.compose()

exports.formula = formula

# examples:
assert "---3 must compose to '-3'", formula.compose(formula.simplify(f.neg(f.neg(f.neg(3))))) is '-3'
console.log formula.compose(f.add(1, 2))
console.log formula.compose(f.add(-1, -2).simplify())
console.log formula.compose(f.add(1, -2).simplify())
console.log formula.compose formula.simplify f.eq('y', f.add(3, '-x', f.call('exp', 3)))
console.log formula.compose formula.simplify f.mul(2, 4)
console.log formula.compose formula.simplify f.add(5, f.mul(2, -4, 'x'))
# console.log(f.eq('y', f.add(3, f.mul(3, 'x'))).simplify())
# console.log(f.eq('y', f.mul(3, 'x')).simplify())
