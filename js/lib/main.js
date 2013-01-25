require('core/params');

lib.load('/js/games/' + Params.get('game'), function(e) {
  console.log('loaded', e);
  var $container = $('#container');
  var WIDTH = window.innerWidth;
  var HEIGHT = window.innerHeight;
  if (e.Game) {
    var game = new e.Game($container, WIDTH, HEIGHT);
    game.start();
  } else if (e.main) {
    e.main($container, WIDTH, HEIGHT);
  } else {
    console.log('No execution hook found.');
  }
})
