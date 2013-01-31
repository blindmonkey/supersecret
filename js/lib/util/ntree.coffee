exports.NTreeNode = (dim) ->
  class TreeNode
    constructor: (parent, size, offset...) ->
      @parent = parent
      @size = size
      @offset = offset
      @removeChildren()
      @data = undefined

    removeChildren: ->
      @forChild (child) ->
        child.parent = undefined
      @children = (undefined for i in [1..Math.pow(2, dim)])
      @hasChildren = false

    forEveryChild: (f) ->
      queue = new Queue()
      queue.push this
      while queue.length > 0
        node = queue.pop()
        node.forChild (child) ->
          queue.push child
        if node isnt this
          return if f(node) is false

    getIndex: (coords...) ->
      s = 0
      for i in [1..coords.length]
        s += coords[i-1] * Math.pow(2, i-1)
      return s

    forChild: (f, allChildren) ->
      return if not @hasChildren
      for child in @children
        f(child) if child or allChildren

    addChild: (coords...) ->
      for coord in coords
        if coord < 0 or coord > 1
          throw "Invalid child coordinate #{coord}"
      @hasChildren = true
      p = []
      for i in [1..coords.length]
        p.push @offset[i-1] + @size / 2 * coords[i]
      @children[@getIndex(coords...)] = new TreeNode(this, @size/2, p...)

    getChild: (coords...) ->
      @children[@getIndex(coords...)]
