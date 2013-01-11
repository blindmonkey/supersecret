(function() {
  var inWorker = false;
  try {
    var w = window;
  } catch (error) {
    inWorker = true;
  }
  
  var argumentsToArray = function(args) {
    var array = [];
    for (var i = 0; i < args.length; i++) {
      array.push(args[i]);
    }
    return array;
  };
  
  var LOG_TYPE = '__console.log',
      ERROR_TYPE = '__console.error';
  if (inWorker) {
    var console = {}
    console.log = function() {
      self.postMessage({type: LOG_TYPE, message: argumentsToArray(arguments)})
    };
    console.error = function() {
      self.postMessage({type: ERROR_TYPE, message: argumentsToArray(arguments)});
    }
    self.console = console;
  } else {
    console = window.console;
    
    var concatArrayLike = function(name, arrayLike) {
      
    };
    
    window.console.handleConsoleMessages = function(name, otherwise) {
      if (!otherwise) {
        otherwise = name;
        name = 'WORKER';
      }
      return function(event) {
        var data = event.data;
        if (data.type && data.type === LOG_TYPE) {
          console.log.apply(console, [name + ':'].concat(data.message));
        } else if (data.type && data.type === ERROR_TYPE) {
          console.error.apply(console, [name + ':'].concat(data.message));
        } else {
          otherwise(event);
        }
      };
    };
  }
})();