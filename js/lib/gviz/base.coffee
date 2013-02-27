exports.BaseGame = class BaseGame
  constructor: (container, width, height) ->
    @container = container
    @width = width
    @height = height
    lib.load('https://www.google.com/jsapi', ->
      console.log('Complete'))

  start: ->
