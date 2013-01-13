CoffeeScript.load = function(url, callback) {
  console.log('sadfjakjsdfk')
  console.log('CoffeeLoading ' + url)
  var s = url.split('://');
  if (s != 'http' && s != 'https' && baseURL)
    url = baseURL + url;
  console.log('CoffeeLoading ' + url)
  var xmlhttp = new XMLHttpRequest();
  xmlhttp.open('GET', url, false);
  console.log('whoa')
  xmlhttp.send();
  if (xmlhttp.status == 200) {
    compiled = CoffeeScript.compile(xmlhttp.responseText)
    console.log('evaluating', compiled)
    try {
      eval(compiled);
      console.log('evaluated')
    } catch (error) {
      console.error('An error occurred while evaluating ' + url)
      console.error(error.message);
    }
  } else
    console.error('Could not load ' + url);
  callback && callback();
};
