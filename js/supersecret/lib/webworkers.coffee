worker = {}
worker.fromURL = (url) ->
  return new Worker(url)
worker.fromJS = (code) ->
  blob = new Blob([code])
  url = window.URL.createObjectURL(blob)
  return worker.fromURL(url)
worker.fromCoffee = (code, printCompiled) ->
  code = CoffeeScript.compile(code)
  console.log(code) if printCompiled
  return worker.fromJS(code)

lib.export('webworker', worker)