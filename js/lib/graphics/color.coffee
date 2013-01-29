class Color
  constructor: (r, g, b) ->
    return r if r instanceof Color
    if g is undefined and b is undefined
      if r.length
        [r, g, b] = r
      else
        b = r & 0xff
        g = (r >> 8) & 0xff
        r = (r >> 16) & 0xff
    @red = Math.floor(r)
    @green = Math.floor(g)
    @blue = Math.floor(b)

  hex: ->
    return @blue + (@green << 8) + (@red << 16)

  lerp: (color2, p) ->
    r = (color2.red - @red) * p + @red
    g = (color2.green - @green) * p + @green
    b = (color2.blue - @blue) * p + @blue
    return new Color(r, g, b)

  @lerp: (color1, color2, p) ->
    return new Color(color1).lerp(new Color(color2), p)

try exports.Color = Color
window.Color = Color
