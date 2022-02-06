type
  MouseButton* = enum
    Unknown
    Left
    Middle
    Right
    Extra1
    Extra2
    Extra3
    Extra4
    Extra5

  MouseLogic* = ref object
    onMove*: proc()
    onPress*: proc()
    onRelease*: proc()
    onScroll*: proc()
    press*: MouseButton
    release*: MouseButton
    x*, y*: float
    xPrevious*, yPrevious*: float
    xChange*, yChange*: float
    wheelX*, wheelY*: float

proc processMove*(mouse: MouseLogic, x, y: float) =
  mouse.xPrevious = mouse.x
  mouse.yPrevious = mouse.y
  mouse.x = x
  mouse.y = y
  mouse.xChange = mouse.x - mouse.xPrevious
  mouse.yChange = mouse.y - mouse.yPrevious
  if mouse.onMove != nil: mouse.onMove()

proc processScroll*(mouse: MouseLogic, x, y: float) =
  mouse.wheelX = x
  mouse.wheelY = y
  if mouse.onScroll != nil: mouse.onScroll()

proc processPress*(mouse: MouseLogic, button: MouseButton) =
  mouse.press = button
  if mouse.onPress != nil: mouse.onPress()

proc processRelease*(mouse: MouseLogic, button: MouseButton) =
  mouse.release = button
  if mouse.onRelease != nil: mouse.onRelease()