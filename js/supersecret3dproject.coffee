
###
window.doRender = (tick) ->
  stopped = false
  
  frameHistory = []
  average = (l) ->
    s = 0
    for i in l
      s += i
    return s / l.length
  maybeUpdate = (->
      lastUpdated = new Date().getTime() - 5000
      return ->
        if new Date().getTime() - lastUpdated > 5000
          console.log('Render loop going well. ' + 1000 / average(frameHistory) + ' frames per second')
          lastUpdated = new Date().getTime())()
  
  lastTime = new Date().getTime()
  f = ->
    now = new Date().getTime()
    tick(now - lastTime)
    afterTickTime = new Date().getTime()
    frameHistory.push(afterTickTime - now)
    maybeUpdate()
    lastTime = now
    if not stopped
      requestAnimationFrame(f)
  f()
  return {
    pause: ->
      stopped = true
    unpause: ->
      stopped = false
      lastTime = new Date().getTime()
      f()
  }


###

Renderer = p.require('Renderer')
FirstPerson = p.require('FirstPerson')


window.init = (exposeDebug) ->
  $container = $('#container')
  WIDTH = screen.availWidth#800
  HEIGHT = screen.availHeight
  
  DEBUG = {
    expose: (name, f) ->
      DEBUG.debugObject[name] = f
    debugObject: {}
  if exposeDebug
    window.DEBUG = DEBUG
  
  $container.append(renderer.domElement)
  
  


  sphereMaterial = new THREE.MeshLambertMaterial({
  #sphereMaterial = new THREE.LineBasicMaterial({
    color: 0xCC0000
  })
  
  ###
  radius = 50
  segments = 16
  rings = 16
  sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial)
  scene.add sphere
  ###
  geometry = new THREE.Geometry();
  width = 11
  length = 11
  getVertexIndex = (x, z) -> (z - 1) + (x - 1) * width
  count = 0
  for xx in [1..width]
    for zz in [1..length]
      x = (xx - 1) * width - Math.floor(width / 2)
      z = (zz - 1) * length - Math.floor(length / 2)
      x *= 50
      z *= 50
      #console.log(++count, x, z, getVertexIndex(x, z))
      geometry.vertices.push(new THREE.Vector3(x, 0, z))
      if xx > 1 and zz > 1
        geometry.faces.push(new THREE.Face3(getVertexIndex(xx - 1, zz - 1), getVertexIndex(xx, zz), getVertexIndex(xx, zz - 1)))
        geometry.faces.push(new THREE.Face3(getVertexIndex(xx, zz), getVertexIndex(xx - 1, zz - 1), getVertexIndex(xx - 1, zz)))
  geometry.computeFaceNormals()
  mesh = new THREE.Mesh(geometry, sphereMaterial)
  DEBUG.expose('mesh', mesh)
  #mesh.position.x = 0
  #mesh.position.y = 0
  #mesh.position.z = 0
  scene.add(mesh)
  
  
  pointLight = new THREE.PointLight(0xFFFFFF, 100, 200)
  DEBUG.expose('pointLight', pointLight)
  
  pointLight.position.x = 10
  pointLight.position.y = 10
  pointLight.position.z = 0
  
  scene.add(pointLight)
  
  ##
  
  dragging = false
  lastPos = null
  camera.position.y = 1
  $container.mousedown (e) ->
    if e.button == 0
      dragging = true
      lastPos = [e.clientX, e.clientY]
  
  $container.mouseup (e) ->
    if e.button == 0
      dragging = false
      lastPos = null
  
  person = new FirstPerson(camera)
  $container.mousemove (e) ->
    if dragging and lastPos != null
      [lx, ly] = lastPos
      [x, y] = [e.clientX, e.clientY]
      
      person.rotateY((x - lx) / -10)
      person.rotatePitch((y - ly) / -10)
      
      lastPos = [x, y]
  
  keys = {
    UP: [38, 87]
    LEFT: 37
    RIGHT: 39
    DOWN: 40
    RISE: 69
  }
      
  
  $(document).keydown((e) ->
    console.log 'down!!' + e.keyCode
    if e.keyCode in keys.UP
      console.log(camera.rotation.y)
      person.walkForward(75)
    else if e.keyCode == keys.RISE
      console.log 'RISE!'
      camera.position.y += 10
  )
  ##
  
  #controls = new THREE.FirstPersonControls(camera)
  
  render = ((delta) ->
    #controls.update(delta / 1000)
    renderer.render(scene, camera))
  doRender(render)
