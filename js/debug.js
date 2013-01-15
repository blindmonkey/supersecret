(function() {
var alreadyStopped = false;

var DEBUG = {
  expose: function(name, f) {
    DEBUG.debugObject[name] = f
  },
  breakpoint: function(condition) {
    if (condition === undefined || condition)
      debugger;
  },
  breakpointOnce: function() {
    if (alreadyStopped) {
      return;
    }
    alreadyStopped = true;
    debugger;
  },
  debugObject: {}
};

window.DEBUG = DEBUG;
window.d = DEBUG.debugObject;

})();
