lib.export('Color', class Color
  constructor: (red, green, blue, alpha) ->
    @red = red
    @green = green
    @blue = blue
    @alpha = alpha or 255

  normalize: ->
    @red = Math.floor(@red)
    @red = 0 if @red < 0
    @red = 255 if @red > 255
    @green = 0 if @green < 0
    @green = 255 if @green > 255
    @blue = 0 if @blue < 0
    @blue = 255 if @blue > 255
    @alpha = 0 if @alpha < 0
    @alpha = 255 if @alpha > 255
)

lib.export('Pixels', class Pixels
  constructor: (context) ->
    @context = context
    @buffer = null
    @updateBuffer()

  updateBuffer: ->
    @buffer = @context.getImageData(0, 0, @context.canvas.width, @context.canvas.height)

  update: ->
    @context.putImageData(@buffer, 0, 0)

  set: (x, y, color) ->
    p = Math.floor(y * @buffer.width + x) * 4
    @buffer.data[p] = color.red
    @buffer.data[p+1] = color.green
    @buffer.data[p+2] = color.blue
    @buffer.data[p+3] = color.alpha
)
