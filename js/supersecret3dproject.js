(function() {

window.init = function(exposeDebug) {
  var $container = $('#container');
  var WIDTH = window.innerWidth;
  var HEIGHT = window.innerHeight;
  console.log(WIDTH, HEIGHT);

  var gameLoadState = 0;
  var canvas = document.createElement('canvas');
  var doResize = function() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  };
  doResize();
  var context = canvas.getContext('2d');
  $container.append(canvas);
  
  var doRedraw = function() {
    context.fillStyle = '#fff';
    context.fillRect(0, 0, canvas.width, canvas.height);
    var barWidth = canvas.width * 0.6;
    var barHeight = Math.min(canvas.height, 50);
    context.strokeStyle = '#000';
    context.strokeRect(canvas.width / 2 - barWidth / 2, canvas.height / 2 - barHeight / 2,
      barWidth, barHeight);
    context.fillStyle = '#000';
    context.fillRect(canvas.width / 2 - barWidth / 2, canvas.height / 2 - barHeight / 2,
      barWidth * window.lib.percentage(), barHeight);
    
    if (gameLoadState > 0) {
      var message = gameLoadState == 1 ? 'Game is loading...' : 'Game is loaded';
      var width = context.measureText(message).width;
      context.fillStyle = '#000';
      context.fillText(message, canvas.width / 2 - width / 2, canvas.height / 2 + barHeight);
    }
  };
  
  window.lib.handle('loaded', function() {
    doRedraw()
  });
  
  window.addEventListener('resize', function() {
    doResize();
    doRedraw();
  }, false);
  
  var params = window.getQueryParams();
  window.doWhen(function() { return window.supersecret && window.supersecret.BaseGame; },
    function() {
      gameLoadState = 1;
      doRedraw();
      window.CoffeeScript.load('js/supersecret/games/' + params.game + '.coffee', function() {
        gameLoadState = 2;
        doRedraw();
        console.log('Game loaded');
      });
    });

  var loadGame = function() {
    $(canvas).remove();
    console.log('Game loaded!');
    var game = new window.supersecret.Game($container, WIDTH, HEIGHT);
    console.log("Game created! Starting!");
    game.start();
  };
  
  window.doWhen(function() {
    return window.supersecret.Game && (window.supersecret.Game.loaded === undefined || window.supersecret.Game.loaded);
    }, function() {
      loadGame();
    });
};

})();