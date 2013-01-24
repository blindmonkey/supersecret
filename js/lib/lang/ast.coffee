exports.lang =
  compile: (sexpr, transforms) ->
    return sexpr.value if sexpr.type
    return sexpr if typeof sexpr is 'string' or typeof sexpr is 'number'
    return sexpr if not sexpr.length and sexpr.length isnt 0
    [callee, args...] = sexpr
    s = ''
    switch callee
      when 'define'
        [defname, defdef] = args
        if defname.length
          [fname, fargs...] = defname
          fbody = defdef
          s = "function #{fname} {\n"
          if fbody[0] != 'return'
            s += "return "
          s += "#{exports.lang.compile(fbody, transforms)}\n}\n"
        else
          s = "var #{defname} = #{exports.lang.compile(defdef, transforms)};\n"

      when 'return'
        s = "return #{args[0]}"
      when '+', '-', '*', '/'
        for arg in args
          if s
            s += " #{callee} "
          s += "#{arg}"
        s = "(#{s})"
      when 'if'
        if args.length < 1 or args.length > 3
          throw "Invalid number of arguments"
        s  = "#{exports.lang.compile(args[0], transforms)} ?"
        s += " #{exports.lang.compile(args[1], transforms)}"
        if args.length == 3
          s += " : "
          s += "#{exports.lang.compile(args[2], transforms)}"
        s = "(#{s})"
      else
        for transform in transforms
          result = transform(sexpr...)
          return result if typeof result is 'string'
          return exports.land.compile(result, transforms) if result instanceof Array

        for arg in args
          if not s
            s = "(#{callee}("
          else
            s += ", "
          s += exports.lang.compile(arg, transforms)
        s += '))'


  l:
    t: true
    f: false
    if: (condition, thenexpr, elseexpr) -> ['if', condition, thenexpr, elseexpr]
    s: (content) -> {type:'string', value: content}
    n: (value) -> {type: 'number', value: value}
    define: (args...) -> ['define'].concat(args)
    return: (arg) -> ['return', arg]
    add: (args...) -> ['+'].concat(args)
    sub: (args...) -> ['-'].concat(args)
    mul: (args...) -> ['*'].concat(args)
    div: (args...) -> ['/'].concat(args)

transforms = [
  (f, args...) -> if f is 'zero?' then (args.join(' === ') + ' === 0')
]

exports.Game = class
  constructor: ->
    console.log('Hello!')
  start: ->


# (define (helper n acc)
#     (if (zero? n)
#       acc
#       (helper (- n 1) (* acc n))))
# (define (fact n)
#   (helper n 1))

helper = (n, acc) ->
  if isZero(n)
    return acc
  else
    helper(n - 1, acc *n)

lang = exports.lang
l = lang.l


e = l.define(['helper', 'n', 'acc']
  l.if(['zero?', 'n']
    'acc'
    ['helper', l.sub('n', 1), l.mul('acc', 'n'), l.s('hello')]))
console.log(e)
debugger
console.log(lang.compile(e, transforms))
