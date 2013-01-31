worker = {}
worker.fromURL = (url) ->
  return new Worker(url)

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
    importScripts("#{baseURL}" + 'js/lib/workers/console.js');
    importScripts("#{baseURL}" + 'js/coffee-script.js');
    importScripts("#{baseURL}" + 'js/coffee-load.js');
    importScripts("#{baseURL}" + "js/lib/simplex.js");
    importScripts("#{baseURL}" + "js/loader.js");

    lib.init("#{lib.ROOT}", "#{lib.BASE}");


  """
  appendText = ''

  prependText += 'lib.load(\n'
  for dependency in deps
    prependText += "  '#{dependency}',\n"
  prependText += "  function(e) {\n"
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
