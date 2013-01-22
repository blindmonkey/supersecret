require('core/params');

lib.load('/js/games/' + Params.get('game'), function(e) {
  console.log('loaded', e);
  var $container = $('#container');
  var WIDTH = window.innerWidth;
  var HEIGHT = window.innerHeight;
  var game = new e.Game($container, WIDTH, HEIGHT);
  game.start();
})
