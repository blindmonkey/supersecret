window.getQueryParams = function(opt_query) {
  var query = opt_query || window.location.href.split('#')[0].split('?').splice(1).join('?');
  var components = query.split('&');
  var params = {};
  for (var i = 0; i < components.length; i++) {
    var component = components[i];
    var s = component.split('=');
    if (s.length === 0) continue;
    if (s.length == 1)
      params[s[0]] = true
    else {
      var key = s[0];
      var v = s.splice(1).join('=');
      params[key] = v;
    }
  }
  return params;
};