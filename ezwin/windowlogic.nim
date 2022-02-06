type
  WindowLogic* = ref object of RootObj
    onClose*: proc()
    onMinimize*: proc()
    onMaximize*: proc()
    onFocus*: proc()
    onLoseFocus*: proc()
    onMove*: proc()
    onResize*: proc()
    x*, y*: float
    xPrevious*, yPrevious*: float
    xChange*, yChange*: float
    width*, height*: float
    widthPrevious*, heightPrevious*: float
    widthChange*, heightChange*: float

proc processClose*(window: WindowLogic) =
  if window.onClose != nil: window.onClose()

proc processMinimize*(window: WindowLogic) =
  if window.onMinimize != nil: window.onMinimize()

proc processMaximize*(window: WindowLogic) =
  if window.onMaximize != nil: window.onMaximize()

proc processFocus*(window: WindowLogic) =
  if window.onFocus != nil: window.onFocus()

proc processLoseFocus*(window: WindowLogic) =
  if window.onLoseFocus != nil: window.onLoseFocus()

proc processMove*(window: WindowLogic, x, y: float) =
  window.xPrevious = window.x
  window.yPrevious = window.y
  window.x = x
  window.y = y
  window.xChange = window.x - window.xPrevious
  window.yChange = window.y - window.yPrevious
  if window.onMove != nil: window.onMove()

proc processResize*(window: WindowLogic, width, height: float) =
  window.widthPrevious = window.width
  window.heightPrevious = window.height
  window.width = width
  window.height = height
  window.widthChange = window.width - window.widthPrevious
  window.heightChange = window.height - window.heightPrevious
  if window.onResize != nil: window.onResize()