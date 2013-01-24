exports.lang =
  compile: (sexpr) ->
    [callee, args...] = sexpr
    s = ''
    switch callee
      when 'define'
        [defname, defdef] = args
        if defname.length
          [fname, fargs...] = defname
          fbody = defdef
          s = "function #{fname} {\n"
          if fbody.length < 1
            throw "Defined functions cannot have empty bodes"
          if fbody.length > 1
            throw "Sorry, can't define more than one body yet =)"
          if fbody[0] != 'return'
            s = "return "
          s += "#{exports.lang.compile(fbody)}\n}\n"
        else
          s = "var #{defname} = #{exports.lang.compile(defdef)};\n"

      when 'return'
        s = "return #{args[0]}"
      when '+', '-', '*', '/'
        for arg in args
          if s
            s += ' #{callee} '
          s += "#{arg}"
        s = "(#{s})"
      when 'if'
        if args.length < 1 or args.length > 3
          throw "Invalid number of arguments"
        s  = "(#{exports.lang.compile(args[0])}) ?"
        s += " #{exports.lang.compile(args[1])}"
        if args.length == 3
          s += " : "
          s += "#{exports.lang.compile(args[2])}"
        s = "(#{s})"
      else
        for arg in args
          if not s
            s = "(#{callee}("
          else
            s += ", "
          s += exports.lang.compile(arg)


  l:
    t: true
    f: false
    define: (args...) -> ['define'].concat(args)
    return: (arg) -> ['return', arg]
    add: (args...) -> ['+'].concat(args)
    sub: (args...) -> ['-'].concat(args)
    mul: (args...) -> ['*'].concat(args)
    div: (args...) -> ['/'].concat(args)





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

l.define(['helper', 'n', 'acc']
  l.if(['zero?', 'n']
    'acc'
    ['helper', l.sub('n', 1), l.mul('acc', 'n'), l.s('hello')]))
['define', ['helper', 'n', 'acc']
  ['if', ['zero?', 'n']
    'acc'
    ['helper', ['-', 'n', 1], ['*', 'acc', 'n']]]]

l.define(['fact', 'n']
  l.e('helper', 'n', 1))
