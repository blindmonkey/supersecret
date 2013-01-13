try {
  w = window;
} catch (e) {
  self.window = self;
}

window.lib = {
  cache: {},
  loading: {},
  callbacks: [],
  events: {}
};

window.lib.handle = function(event, handler) {
  if (!(event in window.lib.events)) window.lib.events[event] = [];
  window.lib.events[event].push(handler);
};

window.lib.fire = function() {
  if (arguments.length === 0) return;
  var event = arguments[0];
  var args = [].slice.call(arguments, 1);
  if (!(event in window.lib.events)) return;
  var handlers = window.lib.events[event];
  for (var i = 0; i < handlers.length; i++) {
    var handler = handlers[i];
    if (handler.apply(null, args) === false) return;
  }
};

window.lib.export = function(name, object) {
  window[name] = object;
};

/**
 * Get the loading progress percentage.
 */
window.lib.percentage = function() {
  var n;
  var loadingCount = 0;
  var loadedCount = 0;
  for (n in window.lib.loading) loadingCount++;
  for (n in window.lib.cache) if (window.lib.cache[n]) loadedCount++;
  return loadedCount / (loadingCount + loadedCount);
};

window.lib.load = function() {
  if (arguments.length === 0) return;
  var callback = arguments[arguments.length - 1];
  var names = [].slice.call(arguments, 0, -1);
  if (typeof callback == 'string') {
    names.push(callback);
  } else {
    window.lib.handle('done', callback);
  }
  
  var callbackForName = function(name) {
    return function() {
      console.log('Loaded ' + name);
      delete window.lib.loading[name];
      window.lib.cache[name] = true;
      window.lib.fire('loaded', name);
      var allLoaded = true;
      for (var n in window.lib.loading) {
        allLoaded = false;
        break;
      }
      if (allLoaded) {
        console.log("Loading complete. Callbacks called from load request for " + names);
        window.lib.fire('done');
      }
    };
  };
  
  window.lib.fire('request', names);
  for (var i = 0; i < names.length; i++) {
    var name = names[i];
    if (name in window.lib.cache || name in window.lib.loading) continue;
    console.log("Loading " + name);
    window.lib.loading[name] = true;
    var url = 'js/supersecret/lib/' + name + '.coffee';
    if (window.baseURL) {
      url = window.baseURL + url;
    }
    CoffeeScript.load(url, callbackForName(name));
  }
};
