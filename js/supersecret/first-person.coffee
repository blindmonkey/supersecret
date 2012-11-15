class FirstPerson
  constructor: (camera) ->
    @camera = camera
    @rotation = 0
    @pitch = 0
  rotateY: (degrees) ->
    radians = degrees * Math.PI / 180
    @rotation += radians
    while @rotation < 0
      @rotation += Math.PI * 2
    while @rotation > Math.PI * 2
      @rotation -= Math.PI * 2
    @updateCamera()
  
  updateCamera: ->
    targetX = @camera.position.x + Math.cos(@rotation)
    targetY = @camera.position.y - Math.sin(@pitch)
    targetZ = @camera.position.z + Math.sin(@rotation)
    @camera.lookAt(new THREE.Vector3(targetX, targetY, targetZ))
  
  rotatePitch: (degrees) ->
    radians = degrees * Math.PI / 180
    @pitch += radians
    while @pitch < 0
      @pitch += Math.PI * 2
    while @pitch > Math.PI * 2
      @pitch -= Math.PI * 2
    @updateCamera()
    
  walkForward: (speed) ->
    speed = speed or 10
    @camera.position.x = @camera.position.x + Math.cos(@rotation) * speed
    @camera.position.z = @camera.position.z + Math.sin(@rotation) * speed

p.provide('FirstPerson', FirstPerson)