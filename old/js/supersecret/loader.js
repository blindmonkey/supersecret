(function() {
  var DependencyTree = function() {
    this.nodes = {};
    this.pending = {};
  };
  DependencyTree.prototype.contains = function(file) {
    return file in this.nodes || file in this.pending;
  };
  DependencyTree.prototype.add = function(file, deps, code) {
    if (file in this.nodes) {
      throw "File '" + file + "' is already loaded.";
    }
    this.nodes[file] = {
      dependencies: deps,
      code: code,
    };
  };
  DependencyTree.prototype.loaded = function(file) {
    var i;
    var queue = [file];
    while (queue.length > 0) {
      file = queue.pop()
      if (!this.contains(file)) return false;
      var node = this.nodes[file];
      for (i = 0; i < node.dependencies.length; i++) {
        queue.push(node.dependencies[i]);
      }
    }
  };

  var tree = new DependencyTree();
  var lib = {};
  lib.log = function() { console.log.call(console, arguments); };

  var urlRegex = /[a-zA-Z]+:\/\//;
  var getDependencyURL = function(dependency) {
    var ext = dependency.slice(-3);
    if (ext === '-js' || ext === '_js') {
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
    var requireRegex = / *require *\( *.+ *\) *;? */g;
    var requireContentRegex = / *require *\( *['"]?(.+?)['"] *\) *;? */;
    var deps = code.match(requireRegex);

    var requires = [];
    for (var d = 0; d < deps.length; d++) {
      var m = deps[d].match(requireContentRegex);
      requires.push(m[1]);
    }

    code = '(function() {\n' +
        'var exports={};\n' +
        '(function(exports) {\n' +
          code.replace(requireRegex, '') + '\n' +
        '})(exports);\n' +
        'return exports\n' +
      '})';
    return {
      requires: requires,
      code: code
    };
  };

  lib.init = function(rootURL, baseURL) {
    lib.ROOT = rootURL;
    lib.BASE = baseURL;
  };

  var loadDependency = function(dependency, callback) {
    if (tree.contains(dependency)) {
      console.log("Dependency '" + dependency + "' was requested, but has already been loaded.");
      return;
    }
    console.log("Loading '" + dependency + "'.")
    var url = getDependencyURL(dependency);
    $.ajax(url, {
      dataType: 'text',
      success: function(data, status, xhr) {
        console.log("Dependency '" + dependency + "' has been loaded successfully.");
        if (url.slice(-7) == '.coffee') {
          data = CoffeeScript.
        }
        var data = doLoad(data);
        lib.log("Dependencies for " + dependency + " calculated to be " + data.requires)
        tree.add(dependency, data.requires, data.code);
        if (data.requires) {
          for (var i = 0; i < data.requires.length; i++) {
            var req = data.requires[i];
            loadDependency(req, callback);
          }
        }
        callback && callback();
      },
      error: function(xhr, status, error) {
        console.error("An error occurred while requesting '" + dependency + "'.", error);
      },
      complete: function(xhr, status) {}
    });
  };

  lib.load = function(file, callback) {
    loadDependency(file, callback);
  };

  window.lib = lib;

})();
