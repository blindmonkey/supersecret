(function() {

var repo = {};
window.p = {}

window.p.provide = function(name, object) {
  console.log('Providing ' + name);
  repo[name] = object;
  object.init && object.init();
};

window.p.require = function(name) {
  console.log('Requiring ' + name);
  return repo[name];
};

var initialized = false;
window.providers = {
  init: function() {
    if (initialized) return;
    initialized = true;
    for (var name in repo) {
      var obj = repo[name];
      obj.onload && obj.onload();
    }
  }
}

})();
