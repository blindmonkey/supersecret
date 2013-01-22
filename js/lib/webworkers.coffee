worker = {}
worker.fromURL = (url) ->
  return new Worker(url)
worker.fromJS = (code) ->
  blob = new Blob([code])
  url = window.URL.createObjectURL(blob)
  return worker.fromURL(url)
worker.fromCoffee = (deps, code) ->
  if not code
    code = deps
    deps = undefined
  getext = (s) -> s.split('.').slice(-1)

  baseURL = location.href.split('#')[0].split('?')[0].split('/')[0..-2].join('/') + '/'
  prependText = """
    self.supersecret = {}
    self.baseURL = '#{baseURL}'
    self.window = self
    self.inWorker = true

  """
  appendText = ''
  dependencies =
    js: []
    coffee: []
    lib: []
  adddep = (dep) ->
    ext = getext(dep)
    ext = 'lib' if ext not of dependencies
    dependencies[ext].push dep
    return ext
  depexists = (dep) ->
    ext = getext(dep)
    ext = 'lib' if ext not of dependencies
    return dep in dependencies[ext]

  if deps
    adddep(dep) for dep in deps

  requirements = []

  if dependencies.coffee.length > 0
    requirements.push 'js/coffee-script.js'
    requirements.push 'js/coffee-load.js'

  if dependencies.lib.length > 0
    requirements.push 'js/supersecret/lib-loader.js'

  for requirement in requirements
    adddep(requirement) if not depexists(requirement)

  for dependency in dependencies.js
    prependText += "importScripts(baseURL + '#{dependency}')\n"
  for dependency in dependencies.coffee
    prependText += "CoffeeScript.load('#{dependency}')\n"
  prependText += 'console.log("hello")\n'

  if dependencies.lib.length > 0
    indent = (spaces, text) ->
      lines = text.split('\n')
      outlines = []
      for line in lines
        outlines.push(spaces + line)
      return outlines.join('\n')

    prependText += 'lib.load(\n'
    for dependency in dependencies.lib
      prependText += "  '#{dependency}'\n"
    prependText += "  ->\n"
    code = indent('    ', code)
    appendText = '\n)'

  code = prependText + code + appendText
  code = CoffeeScript.compile(code)
  console.log(code)
  return worker.fromJS(code)

worker.fromJS = (deps, code) ->
  if not code
    code = deps
    deps = undefined
  getext = (s) -> s.split('.').slice(-1)

  baseURL = location.href.split('#')[0].split('?')[0].split('/')[0..-2].join('/') + '/'
  prependText = """
    self.supersecret = {};
    self.baseURL = '#{baseURL.replace("'", "\\'")}';
    self.window = self;
    self.inWorker = true;
    self.console = {
      log: function() {},
      error: function() {}
    };

  """
  appendText = ''
  dependencies =
    js: []
    coffee: []
    lib: []
  adddep = (dep) ->
    ext = getext(dep)
    ext = 'lib' if ext not of dependencies
    dependencies[ext].push dep
    return ext
  depexists = (dep) ->
    ext = getext(dep)
    ext = 'lib' if ext not of dependencies
    return dep in dependencies[ext]

  if deps
    adddep(dep) for dep in deps

  requirements = []

  if dependencies.coffee.length > 0
    requirements.push 'js/coffee-script.js'
    requirements.push 'js/coffee-load.js'

  if dependencies.lib.length > 0
    requirements.push 'js/supersecret/lib-loader.js'

  for requirement in requirements
    adddep(requirement) if not depexists(requirement)

  for dependency in dependencies.js
    prependText += "importScripts(baseURL + '#{dependency}');\n"
  for dependency in dependencies.coffee
    prependText += "CoffeeScript.load('#{dependency}');\n"
  #prependText += 'console.log("hello");\n'

  if dependencies.lib.length > 0
    indent = (spaces, text) ->
      lines = text.split('\n')
      outlines = []
      for line in lines
        outlines.push(spaces + line)
      return outlines.join('\n')

    prependText += 'lib.load(\n'
    for dependency in dependencies.lib
      prependText += "  '#{dependency}',\n"
    prependText += "  function() {\n"
    appendText = '});'

  code = prependText + code + appendText
  #console.log code
  blob = new Blob([code])
  url = window.URL.createObjectURL(blob)
  return worker.fromURL(url)

worker.fromCoffee = (deps, code) ->
  if not code
    code = deps
    deps = []
  code = CoffeeScript.compile(code)
  return worker.fromJS(deps, code)

exports.webworker = worker
