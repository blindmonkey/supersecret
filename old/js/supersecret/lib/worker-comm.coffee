lib.export('WorkerComm', class WorkerComm
  constructor: (worker, finterface) ->
    console.log("Workercomm constructed in worker: ", !!window.inWorker)
    @worker = worker
    @finterface = finterface
    @pending = {}
    @isReady = false
    @queue = []
    @nextId = 0
    @i = {}


    worker.addEventListener('message', (event) =>
      #console.log('Event came in!', event.data)
      data = event.data
      @handle(data)
    );

    @console = {
      log: (args...) =>
        @send({
          action: 'console'
          type: 'log'
          args: args
        })
      error: (args...) =>
        @send({
          action: 'console'
          type: 'error'
          args: args
        })
    }

    @onready = []

  exposeMethod: (name, method) ->
    @finterface[name] = method

  ready: ->
    message =
      action: 'ready'
      methods: (n for n of @finterface)
    @worker.postMessage(message);

  handleReady: (handler) ->
    @onready.push(handler)

  send: (data) ->
    if @isReady
      @worker.postMessage(data)
    else
      @queue.push data

  handle: (data) ->
    handleMethod = (methodName) =>
      @i[methodName] = (args..., callback) =>
          @call(methodName, args..., callback)
    if data.action == 'ready' and not @isReady
      @isReady = true
      if @queue.length > 0
        for item in @queue
          @send(item)
        @queue = []
      if data.methods
        for methodName in data.methods
          handleMethod(methodName)
      handler() for handler in @onready
      return

    if data.action == 'call'
      func = @finterface[data.name]
      if not func
        console.error("Function #{data.name} not found")
      else
        @respond(data.id, func(data.args...))
    else if data.action == 'expose'
      handleMethod(data.name)
    else if data.action == 'response'
      if data.id of @pending
        @pending[data.id](data.value)
        delete @pending[data.id]
    else if data.action == 'console'
      window.console[data.type]('WORKER:', data.args...)

  respond: (id, value) ->
    @send({
      id: id
      action: 'response'
      value: value
    })

  call: (name, args..., callback) ->
    messageId = @nextId++
    if typeof callback == 'function'
      @pending[messageId] = callback
    else
      args.push callback
    @send({
      action: 'call'
      name: name
      id: messageId
      args: args
    })
)
