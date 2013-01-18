inWorker = false
try
  w = window
catch e
  inWorker = true
  self.window = self

window.lib = {
  cache: {}
  loading: {}
  callbacks: []
  events: {}
}

window.lib.handle = (event, handler) ->
  window.lib.events[event] = [] if event not of window.lib.events
  window.lib.events[event].push handler

window.lib.fire = (event, args...) ->
  return if event not of window.lib.events
  for handler in window.lib.events[event]
    return if handler(args...) is false

window.lib.export = (name, object) ->
  window[name] = object

window.lib.percentage = ->
  loadingCount = 0
  loadedCount = 0
  for n of window.lib.loading
    loadingCount++
  for n of window.lib.cache
    loadedCount++ if window.lib.cache[n]
  return loadedCount / (loadingCount + loadedCount)

window.lib.load = (names..., callback) ->
  if typeof callback == 'string'
    names.push callback
  else
    window.lib.callbacks.push callback
  window.lib.fire('request', names)
  for name in names
    continue if name of window.lib.cache or name of window.lib.loading
    console.log("Loading " + name)
    #console.log("Requesting " + name + '.coffee')
    window.lib.loading[name] = true
    CoffeeScript.load('js/supersecret/lib/' + name + '.coffee',
      do (name) -> ->
        console.log('Loaded ' + name)
        delete window.lib.loading[name]
        window.lib.cache[name] = true
        window.lib.fire('loaded', name)
        allLoaded = true
        for n of window.lib.loading
          allLoaded = false
          break
        if allLoaded
          console.log("Loading complete. Callbacks called from load request for " + names)
          for cb in window.lib.callbacks
            cb()
    )
