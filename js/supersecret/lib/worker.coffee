lib.load('now', 'timer')

lib.export('WorkerPool', class WorkerPool
  @__instance: null
  @get: ->
    if not WorkerPool.__instance?
      WorkerPool.__instance = new WorkerPool(100, 10)
    return WorkerPool.__instance

  @setCycleTime: (newCycleTime) ->
    @get().cycle = newCycleTime

  @setPauseTime: (newPauseTime) ->
    @get().pause = newPauseTime

  constructor: (cycleTime, pauseTime) ->
    @workers = []
    @cycle = cycleTime
    @pause = pauseTime
    @scheduleNext()
    @timer = new Timer()

  scheduleNext: ->
    setTimeout(@doWork.bind(this), @pause)

  doWork: ->
    start = now()
    cycleEndTime = start + @cycle
    while now() < cycleEndTime
      return if @workers.length == 0
      i = Math.floor(Math.random() * @workers.length)
      worker = @workers.splice(i, 1)[0]
      if not worker.running
        worker.start()
      workerEndTime = if worker.cycle then (start + worker.cycle) else cycleEndTime
      worker.doWork(workerEndTime)
      if not worker.done
        @workers.push worker
    #console.log('Scheduling next')
    @scheduleNext()

  start: (worker) ->
    @workers.push worker
)


class Worker
  constructor: (callbacks) ->
    @done = false
    @running = false

    @pool = WorkerPool.get()
    @callbacks = callbacks or {}
    @state = null

  run: ->
    @pool.start(this)

  doWork: (endtime) ->
    @callbacks.oncontinue and @callbacks.oncontinue(@state)
    @work(endtime)
    if @done
      @callbacks.ondone and @callbacks.ondone(@state)
    else
      @callbacks.onpause and @callbacks.onpause(@state)

  work: (endtime) ->
    throw 'Not implemented'

  start: ->
    if @done
      throw 'Cannot start a finished worker'
    @running = true
    @state = {}


lib.export('WhileWorker', class WhileWorker extends Worker
  constructor: (loopFunctions, callbacks) ->
    @loop = loopFunctions
    super(callbacks)

  work: (endtime) ->
    while @loop.condition(@state)
      @loop.work(@state)
      @loop.progress and @loop.progress(@state)
      return if now() > endtime
    @done = true

  start: ->
    super
    @loop.init and @loop.init(@state)
)


lib.export('ForWorker', class ForWorker extends WhileWorker
  constructor: (range, work, callbacks) ->
    throw 'Invalid range length' if range.length != 2 and range.length != 3
    super({
      init: (state) ->
        state.variable = range[0]
      condition: (state) ->
        return state.variable < range[1]
      progress: (state) ->
        state.variable += (if range.length == 3 then range[2] else 1)
      work: (state) ->
        work(state.variable)
    }, callbacks)
)


lib.export('NestedForWorker', class NestedForWorker extends WhileWorker
  constructor: (ranges, work, callbacks) ->
    ranges = ((r for r in range) for range in ranges)
    for range in ranges
      throw 'Invalid range length' if range.length != 2 and range.length != 3
    super({
      init: (state) ->
        state.variables = (range[0] for range in ranges)
      condition: (state) ->
        return state.variables[0] < ranges[0][1]
      progress: (state) ->
        for i in [state.variables.length - 1..0]
          range = ranges[i]
          state.variables[i] += (if range.length == 3 then range[2] else 1)
          if state.variables[i] < ranges[i][1]
            break
          else if i > 0
            state.variables[i] = range[0]
      work: (state) ->
        work(state.variables...)
    }, callbacks)
)
