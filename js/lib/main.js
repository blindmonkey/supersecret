require('core/params');

lib.load('/js/games/' + Params.get('game'), function(e) {
  console.log('loaded', e);
  var $container = $('#container');
  var WIDTH = window.innerWidth;
  var HEIGHT = window.innerHeight;
  runGame = function() {
    if (e.Game) {
      var game = new e.Game($container, WIDTH, HEIGHT);
      game.start();
    } else if (e.main) {
      e.main($container, WIDTH, HEIGHT);
    } else {
      console.log('No execution hook found.');
    }
  };
  loop = function() {
    if (!window.delayLoad) {
      console.log('running game');
      runGame();
    } else {
      setTimeout(loop, 500);
    }
  };
  console.log('delaying load')
  loop();

})
