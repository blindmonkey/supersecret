lib.load(
  'base2d'
  ->
    supersecret.Game = class LogGrid extends Base2DGame
      update: (delta) ->
        screenPos = (y) =>
          #return y
          y = Math.log(y) * 20
          h = (@context.canvas.height - 20)
          return h - y / 100 * h + 10
        drawLine = (p, c) =>
          @context.beginPath()
          @context.moveTo(0, p)
          @context.lineTo(@context.canvas.width, p)
          @context.closePath()
          @context.strokeStyle = c
          @context.stroke()
        
        @context.fillStyle = '#000'
        @context.fillRect(0, 0, @context.canvas.width, @context.canvas.height)
        minorCount = 10
        grid = [1, 10, 100]
        for i in [0..grid.length - 1]
          g = grid[i]
          gy = screenPos(g)
          drawLine(gy, '#f00')
          continue if i == 0
          pg = grid[i - 1]
          for j in [1..minorCount]
            p = j / (minorCount + 1)
            yy = (g - pg) * p + pg
            
            y = screenPos(yy)
            drawLine(y, '#888')
        return null
)