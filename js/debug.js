(function() {

DEBUG = {
  expose: function(name, f) {
    DEBUG.debugObject[name] = f
  },
  debugObject: {}
};

window.DEBUG = DEBUG;
window.d = DEBUG.debugObject;

})();
