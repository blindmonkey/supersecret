(function() {

var DEBUG = {
  expose: function(name, f) {
    DEBUG.debugObject[name] = f
  },
  breakpoint: function(condition) {
    if (condition === undefined || condition)
      debugger;
  },
  breakpointOnce: function() {
    var alreadyStopped = false;
    return function() {
      if (!alreadyStopped) {
        alreadyStopped = true;
        debugger;
      }
    };
  },
  debugObject: {}
};

window.DEBUG = DEBUG;
window.d = DEBUG.debugObject;

})();
