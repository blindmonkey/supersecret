window.requestAnimationFrame = window.mozRequestAnimationFrame ||
      window.msRequestAnimationFrame ||
      window.webkitRequestAnimationFrame ||
      (function (callback) { setTimeout(callback, 1000 / 60); });
