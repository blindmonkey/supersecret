p.provide('requestAnimationFrame', (->
    return (window.mozRequestAnimationFrame or \
      window.msRequestAnimationFrame or \
      window.webkitRequestAnimationFrame or \
      ((callback) -> setTimeout(callback, 1000 / 60)))
  )())
