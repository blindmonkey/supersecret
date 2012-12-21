lib.load('events')

lib.export('MouseManager', class MouseManager extends EventHandledObject
  constructor: (container) ->
    @last = null
    @dragging = false
    $(container).mousedown((e) =>
      @dragging = true
      @last = [e.clientX, e.clientY]
      @fireEvent('mouse-down', @last...)
    )
    $(container).mouseup((e) =>
      @dragging = false
      @fireEvent('mouse-up', @last...)
      @last = null
    )
    $(container).mousemove((e) =>
      if @dragging
        [lx, ly] = lastMouse
        @last = [e.clientX, e.clientY]
        @fireEvent('mouse-drag', [lx, ly], @last)
    )
)
