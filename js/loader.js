(function() {
  var contextEval = function(code, context) {
    var oldValues = {};
    for (var name in context) {
      oldValues[name] = window[name];
      window[name] = context[name];
    }
    var ret = eval(code);
    for (var name in oldValues) {
      window[name] = oldValues[name];
    }
    return ret;
  };

  var LinkedList = function() {
    this.head = this.tail = null;
    this.length = 0;
  };
  LinkedList.prototype.pushOnly_ = function(item) {
    if (this.head !== null || this.tail !== null) {
      throw "Push only only works on empty lists."
    }
    this.head = this.tail = {
      first: item,
      rest: null
    };
  };
  LinkedList.prototype.push = function(item) {
    if (this.length == 0) {
      this.pushOnly_(item);
    } else {
      this.tail.rest = {
        first: item,
        rest: null
      };
      this.tail = this.tail.rest;
    }
    this.length++;
  };
  LinkedList.prototype.pushFront = function(item) {
    if (this.length == 0) {
      this.pushOnly_(item);
    } else {
      var oldhead = this.head;
      this.head = {
        first: item,
        rest: oldhead
      };
    }
    this.length++;
  };
  LinkedList.prototype.pop = function() {
    if (this.length <= 0) {
      throw "Can't pop an empty list";
    }
    var item = this.head.first;
    if (this.head === this.tail) {
      this.tail = null;
    }
    this.head = this.head.rest;
    this.length--;
    return item;
  };
  LinkedList.prototype.popBack = function() {
    throw "Unsupported";
  };
  LinkedList.prototype.toArray = function() {
    var array = [];
    var current = this.head;
    while (current !== null) {
      array.push(current.first);
      current = current.rest;
    }
    return array;
  }

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
    if (file in this.pending) {
      delete this.pending[file];
    }
  };
  DependencyTree.prototype.loaded = function(file) {
    var i;
    var seen = {};
    var queue = [file];
    while (queue.length > 0) {
      file = queue.pop()
      if (file in seen) continue;
      if (!(file in this.nodes)) return false;
      seen[file] = true;
      var node = this.nodes[file];
      for (i = 0; i < node.dependencies.length; i++) {
        queue.push(node.dependencies[i]);
      }
    }
    return true;
  };
  DependencyTree.prototype.construct = function(file) {
    var original = file;
    var seen = {};
    var order = new LinkedList();
    var queue = new LinkedList();
    var graph = {};
    queue.push(file);
    while (queue.length > 0) {
      var file = queue.pop();
      if (file in seen) continue;
      var node = this.nodes[file];
      seen[file] = node;
      for (var i = 0; i < node.dependencies.length; i++) {
        queue.push(node.dependencies[i]);
      }
    }

    var visited = {};
    var visit = function(file) {
      if (!(file in visited)) {
        visited[file] = true;
        var node = seen[file];
        for (var i = 0; i < node.dependencies.length; i++) {
          node[i]
        }
      }
    };
    for (var file in seen) {

    }

    console.log('construct finished');
    var exports = {};
    while (order.length > 0) {
      var file = order.pop();
      if (file in exports) continue;
      lib.log("Executing file " + file)
      var node = this.nodes[file];
      var context = {};
      if (node.dependencies) {
        for (var i = 0; i < node.dependencies.length; i++) {
          var dependency = node.dependencies[i];
          if (!(dependency in exports)) {
            throw "A circular dependency was found between '" + file + "' and '" + dependency + "'.";
          }
          var e = exports[dependency];
          for (var name in e) {
            context[name] = e[name];
          }
        }
      }
      exports[file] = contextEval(node.code + '()', context);
    }
    return exports[original];
  };

  var tree = new DependencyTree();
  var lib = {};
  lib.log = function() { console.log.apply(console, arguments); };

  var urlRegex = /[a-zA-Z]+:\/\//;
  var getDependencyURL = function(dependency) {
    var ext = dependency.slice(-3);
    if (ext === '-js' || ext === '_js' || ext === '.js') {
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
    var requireContentRegex = / *require *\( *['"]?(.+?)['"]? *\) *;? */;
    var deps = code.match(requireRegex);

    var requires = [];
    if (deps) {
      for (var d = 0; d < deps.length; d++) {
        var m = deps[d].match(requireContentRegex);
        requires.push(m[1]);
      }
    }

    code = '(function() {\n' +
        'var exports={};\n' +
        '(function(exports) {\n' +
          code.replace(requireRegex, '') + '\n' +
        '})(exports);\n' +
        'return exports;\n' +
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
    tree.pending[dependency] = true;
    $.ajax(url, {
      dataType: 'text',
      success: function(data, status, xhr) {
        console.log("Dependency '" + dependency + "' has been loaded successfully.");
        if (url.slice(-7) == '.coffee') {
          data = CoffeeScript.compile(data);
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
    loadDependency(file, function() {
      if (tree.loaded(file)) {
        console.log('LOADED!')
        console.log(tree.construct(file));
      }
    });
  };

  window.lib = lib;
})();
