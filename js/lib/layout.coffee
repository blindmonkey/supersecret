layout = {}

class NotImplemented extends Error
  constructor: ->
    super("Not implemented.")

class layout.Position
  constructor: (x, y) ->
    @x = x
    @y = y

class layout.Size
  constructor: (width, height) ->
    @width = width
    @height = height

class layout.Rect
  constructor: (position, size) ->
    @position = position
    @size = size

class layout.Base
  getSize: ->
    throw new NotImplemented
  getPosition: ->
    throw new NotImplemented
  getStyle: ->
    throw new NotImplemented
  layout: (renderer, size) ->
    throw new NotImplemented

class layout.Text extends layout.Base
  constructor: (text, style) ->
    @text = text
    @style = style


