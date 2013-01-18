(function() {
  var DependencyTree = function() {
    this.nodes = {};
  };
  DependencyTree.prototype.contains = function(file) {
    return file in this.nodes;
  };
  DependencyTree.prototype.add = function(file, deps, code) {
    if (file in this.nodes) {
      throw "File '" + file + "' is already loaded.";
    }
    this.nodes[file] = {
      deps: deps,
      code: code
    };
  };
  
  var tree = new DependencyTree();
  var lib = {};
  
  var urlRegex = /[a-zA-Z]+:\/\//;
  var getDependencyURL = function(dependency) {
    if (dependency.slice(-3) === '_js') {
      dependency = dependency.slice(0,-3) + '.js';
    } else {
      dependency += '.coffee';
    }
    
    if (dependency.slice(0,2) == '//' || urlRegex.test(dependency)) {
    } else if (dependency[0] == '/') {
      dependency = lib.ROOT + dependency;
    } else {
      dependency = lib.ROOT + lib.BASE + dependency;
    }
    
    return dependency;
  };
  
  var doLoad = function(code) {
    var requireRegex = /^ *require *\( *.+ *\) *;? *$/;
    var requires = code.match(requireRegex);
    code = code.replace(requireRegex, '');
    return {
      requires: requires,
      code: code
    };
  };
  
  lib.init = function(rootURL, baseURL) {
    
  };
  
  var loadDependency = function(dependency, callback) {
    if (tree.contains(dependency)) {
      console.log("Dependency '" + dependency + "' was requested, but has already been loaded.");
      return;
    }
    console.log("Loading '" + dependency + "'.")
    var url = getDependencyURL(dependency);
    $.ajax(url, {
      success: function(data, status, xhr) {
        console.log("Dependency '" + dependency + "' has been loaded successfully.");
        var data = doLoad(data);
        
      },
      error: function(xhr, status, error) {},
      complete: function(xhr, status) {}
    });
  };
  
  lib.load = function() {
    var dependencies = [];
    var callback;
    for (var i = 0; i < arguments.length; i++) {
      var arg = arguments[i];
      if (i < arguments.length - 1 || typeof arg !== 'function') {
        dependencies.push(arg);
      } else {
        callback = arg;
      }
    }
  };
  
})();