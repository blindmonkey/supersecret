(function() {
  var contextEval = function(code, context) {
    var args = [];
    wrapperTop = null;
    for (var name in context) {
      args.push(context[name])
      if (!wrapperTop) {
        wrapperTop = '(function(' + name
      } else {
        wrapperTop += ', ' + name
      }
    }
    if (!wrapperTop) {
      wrapperTop = '(function(';
    }
    wrapperTop += ') {\n';
    wrapperTop += 'return ';
    wrapperBottom = ';})';
    // lib.log(wrapperTop + code + wrapperBottom)
    ret = eval(wrapperTop + code + wrapperBottom)
    return ret.apply(null, args);
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
      if (node.dependencies) {
        for (i = 0; i < node.dependencies.length; i++) {
          queue.push(node.dependencies[i]);
        }
      }
    }
    return true;
  };
  DependencyTree.prototype.traverse = function(file, f) {
    /* Starting from the node 'file', visits it and all of its children and
     * indirect children exactly once.
     */
    var queue = new LinkedList();
    var seen = {};
    queue.push(file);
    while (queue.length > 0) {
      var name = queue.pop();
      if (name in seen) continue;
      seen[name] = true;
      var node = this.nodes[name];
      if (!node) {
        throw "A node that is depended upon (" + name + ") could not be found."
      }
      if (f(name, node) === false) return;
      if (node.dependencies) {
        for (var i = 0; i < node.dependencies.length; i++) {
          queue.push(node.dependencies[i]);
        }
      }
    }
  };
  DependencyTree.prototype.construct = function(file) {
    //    Copyright 2012 Rob Righter (@robrighter)
    //
    //    Licensed under the Apache License, Version 2.0 (the "License");
    //    you may not use this file except in compliance with the License.
    //    You may obtain a copy of the License at
    //
    //        http://www.apache.org/licenses/LICENSE-2.0
    //
    //    Unless required by applicable law or agreed to in writing, software
    //    distributed under the License is distributed on an "AS IS" BASIS,
    //    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    //    See the License for the specific language governing permissions and
    //    limitations under the License.
    //
    // The code in this function has been adapted from a version written by
    // Rob Righter and was found on https://github.com/robrighter/javascript-topological-sort.
    var original = file;
    var graph = {};
    var maybeCreateNode = function(name) {
      if (!(name in graph)) {
        graph[name] = {
          indegrees: 0,
          edges: []
        };
      }
    }
    var nodePlusOne = function(name) {
      maybeCreateNode(name);
      graph[name].indegrees++;
    }
    var unprocessed = new LinkedList();
    var numberOfNodes = 0;
    this.traverse(file, function(name, node) {
      numberOfNodes++;
      unprocessed.push(name);
      maybeCreateNode(name);
      if (node.dependencies) {
        for (var i = 0; i < node.dependencies.length; i++) {
          var dependency = node.dependencies[i];
          graph[name].edges.push(dependency);
          nodePlusOne(dependency);
        }
      }
    })

    var processed = new LinkedList();
    var queue = new LinkedList();
    var remaining = new LinkedList();
    while (processed.length < numberOfNodes) {
      while (unprocessed.length > 0) {
        var name = unprocessed.pop();
        if (graph[name].indegrees === 0) {
          queue.push(name);
        } else {
          remaining.push(name);
        }
      }
      var t = remaining;
      remaining = unprocessed;
      unprocessed = t;

      if (queue.length == 0) {
        throw "There is a cycle in the graph."
      }
      name = queue.pop();
      var edges = graph[name].edges;
      for (var i = 0; i < edges.length; i++) {
        var edge = edges[i];
        graph[edge].indegrees--;
      }
      processed.pushFront(name);
    }

    var exports = {};
    // while (order.length > 0) {
    //   var file = order.pop();
    while (processed.length > 0) {
      var file = processed.pop();
    // for (var processedIndex = 0; processedIndex < processed.length; processedIndex++) {
    //   var file = processed[processedIndex];
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

  /**
   * LLLLL            IIIIIIIII   BBBBBBB
   *  LLL             IIIIIIIII   BBBBBBBBB
   *  LLL                III      BBB   BBBB
   *  LLL                III      BBB    BBB
   *  LLL                III      BBBBBBBBB
   *  LLL                III      BBBBBBBBBB
   *  LLL         L      III      BBB    BBBB
   *  LLL        LL      III      BBB     BBB
   *  LLLLLLLLLLLLL   IIIIIIIII   BBBBBBBBBBB
   * LLLLLLLLLLLLLL   IIIIIIIII   BBBBBBBBB
   */

  var tree = new DependencyTree();
  var lib = {};
  lib.log = function() { console.log.apply(console, arguments); };
  // lib.log = function(){};

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
    var requireRegex = /^ *require *\( *.+ *\) *;? */gm;
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

  var ajax = function(url, options) {
    try {
      return $.ajax(url, options);
    } catch (e) {
      var XHRState = {
        UNSENT: 0,
        OPENED: 1,
        HEADERS_RECEIVED: 2,
        LOADING: 3,
        DONE: 4
      };
      var xhr = new XMLHttpRequest();
      xhr.open('GET', url, options.async || true);
      xhr.onreadystatechange = function() {
        if (xhr.readyState != XHRState.DONE) { return; }
        var response = xhr.responseText;
        if (xhr.status == 200)
          options && options.success && options.success(response, xhr.status, xhr);
        else
          options && options.error && options.error(xhr, xhr.status, null);
      };
      xhr.send();
    }
  };

  lib.init = function(rootURL, baseURL) {
    lib.ROOT = rootURL;
    lib.BASE = baseURL;
  };

  var loadDependency = function(dependency, callback, source) {
    if (tree.contains(dependency)) {
      lib.log("Dependency '" + dependency + "' was requested, but has already been loaded.");
      return;
    }
    lib.log("Loading '" + dependency + "'.")
    var url = getDependencyURL(dependency);
    tree.pending[dependency] = true;
    ajax(url, {
      dataType: 'text',
      success: function(data, status, xhr) {
        lib.log("Dependency '" + dependency + "' has been loaded successfully.");
        if (url.slice(-7) == '.coffee') {
          data = 'return ' + CoffeeScript.compile(data);
        }
        var data = doLoad(data);
        data.code = '/* ' + dependency + ' */ ' + data.code
        lib.log("Dependencies for " + dependency + " calculated to be " + data.requires)
        tree.add(dependency, data.requires, data.code);
        if (data.requires) {
          for (var i = 0; i < data.requires.length; i++) {
            var req = data.requires[i];
            loadDependency(req, callback, dependency);
          }
        }
        callback && callback();
      },
      error: function(xhr, status, error) {
        console.error("An error occurred while requesting '" + dependency + "' from " + source + "." + status, error);
      },
      complete: function(xhr, status) {}
    });
  };

  lib.load = function() {
    var callback = arguments[arguments.length - 1];
    var files = [].slice.call(arguments, 0,-1);
    if (typeof callback !== 'function') {
      files.push(callback);
      callback = undefined;
    }
    var cb = function() {
      var allloaded = true;
      for (var i = 0; i < files.length; i++) {
        var file = files[i];
        if (!tree.loaded(file)) {
          console.log(file[i])
          allloaded = false;
          break;
        }
      }
      if (allloaded) {
        var exports = {};
        for (var i = 0; i < files.length; i++) {
          var e = tree.construct(files[i]);
          for (var p in e) {
            exports[p] = e[p];
          }
        }
        callback && callback(exports);
      }
    };
    for (var i = 0; i < files.length; i++) {
      var file = files[i];
      loadDependency(file, cb);
    }
  };

  window.lib = lib;
})();
