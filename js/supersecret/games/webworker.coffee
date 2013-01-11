lib.load(
  'webworkers'
  -> supersecret.Game.loaded = true)

class supersecret.Game
  @loaded: false
  constructor: (container, width, height) ->
    @container = container

  start: ->
    baseURL = 'https://c9.io/blindmonkey/supersecret/workspace/'

    baseURL = location.href.split('#')[0].split('?')[0].split('/')[0..-2].join('/') + '/'
    console.log('baseURL is #{baseURL}')


    #worker = webworker.fromCoffee(
    """
      self.baseURL = '#{baseURL}'
      importScripts(baseURL + 'js/coffee-script.js')
      importScripts(baseURL + 'js/worker-console.js')
      importScripts(baseURL + 'js/coffee-load.js')
      self.window = self
      self.inWorker = true

      CoffeeScript.load('js/supersecret/game-loader.coffee')

      lib.load('id', ->
        console.log('ID loaded. The id of 123 is ' + generateId(123)))

      self.onmessage = (e) ->
        message = e.data
        if message.type == 'query'
          self.postMessage(message.data)
        else if message.type == 'location'
          #self.postMessage(generateId([1, 2, 3]))
          self.postMessage('LOCATION LOCATION LOCATION')
        else if message.type == 'respond'
          self.postMessage(CoffeeScript.compile('1+1'))
        else
          self.postMessage('Unknown command')
    """#)
    worker = webworker.fromCoffee([
        'js/worker-console.js'
        'js/coffee-script.js'
        'js/supersecret/first-person.coffee'
        #'grid'
      ], """
      console.log('hello, world!')

      self.onmessage = (e) ->
        message = e.data
        if message.type == 'query'
          self.postMessage(message.data)
        else if message.type == 'location'
          #self.postMessage(generateId([1, 2, 3]))
          self.postMessage('LOCATION LOCATION LOCATION')
        else if message.type == 'respond'
          self.postMessage(CoffeeScript.compile('1+1'))
        else
          self.postMessage('Unknown command')
    """)

    worker.onmessage = console.handleConsoleMessages('worker1', (e) ->
      console.log('from worker: ', e.data)
    )
    worker.onerror = (e) ->
      console.error(e)
    worker.postMessage({
      type: 'location'
    })
    worker.postMessage({
      type: 'query'
      data: 'hey hi'
    })
    worker.postMessage({
      type: 'respond'
      data: 'hey hi'
    })
