lib.load(
  'webworkers'
  'worker-comm'
  -> supersecret.Game.loaded = true)

class supersecret.Game
  @loaded: false
  constructor: (container, width, height) ->
    @container = container

  start: ->
    baseURL = 'https://c9.io/blindmonkey/supersecret/workspace/'

    baseURL = location.href.split('#')[0].split('?')[0].split('/')[0..-2].join('/') + '/'
    console.log('baseURL is #{baseURL}')
    worker = webworker.fromCoffee([
        #'js/worker-console.js'
        'js/coffee-script.js'
        #'js/test/simple.coffee'
        #'js/supersecret/first-person.coffee'
        'grid'
        'worker-comm'
      ], """
      #console.log('hello, world!')
      
      comm = new WorkerComm(self, {
        test: (a, b) ->
          comm.console.log('in test');
          return a + b
      });
      comm.ready()
      comm.console.log('worker is ready')
      comm.call('test2', 4, 5, (result) ->
        comm.console.log('IN WORKER, result came in: ' + result)
      )
    """)

    worker.onmessage = console.handleConsoleMessages('worker1')
    
    comm = new WorkerComm(worker, {
      test2: (a, b) ->
        return a * b
    })
    comm.handleReady(->
      comm.ready()
      comm.call('test', 1, 2, (result) ->
        console.log('Callback for test' + result)
      )
    )
    #worker.onerror = (e) ->
      #console.error(e)
    #worker.postMessage({
      #type: 'location'
    #})
    #worker.postMessage({
      #type: 'query'
      #data: 'hey hi'
    #})
    #worker.postMessage({
      #type: 'respond'
      #data: 'hey hi'
    #})
