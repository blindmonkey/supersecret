(function() {

DEBUG = {
  expose: function(name, f) {
    DEBUG.debugObject[name] = f
  },
  breakpoint: function(condition) {
    if (condition === undefined || condition)
      debugger;
  },
  debugObject: {}
};

window.DEBUG = DEBUG;
window.d = DEBUG.debugObject;

})();
