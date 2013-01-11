CoffeeScript.load = function(url, callback) {
  var s = url.split('://');
  if (s != 'http' && s != 'https' && baseURL)
    url = baseURL + url;
  var xmlhttp = new XMLHttpRequest();
  xmlhttp.open('GET', url, false);
  xmlhttp.send();
  if (xmlhttp.status == 200)
    eval(CoffeeScript.compile(xmlhttp.responseText));
  else
    console.error('Could not load ' + url);
  callback && callback();
};