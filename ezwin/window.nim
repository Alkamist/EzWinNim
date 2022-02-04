{.experimental: "overloadableEnums".}

import std/[tables, exitprocs, unicode]
import staticglfw as glfw
import input

export input

func pollEvents*() =
  glfw.pollEvents()

type
  Window* = ref object
    onMove*: proc()
    onResize*: proc()
    onFocus*: proc()
    onLoseFocus*: proc()
    onMouseMove*: proc()
    onMousePress*: proc()
    onMouseRelease*: proc()
    onMouseScroll*: proc()
    onKeyPress*: proc()
    onKeyRelease*: proc()
    onCharacter*: proc()
    input*: InputState
    x*, y*: int
    xPrevious*, yPrevious*: int
    xChange*, yChange*: int
    width*, height*: int
    widthPrevious*, heightPrevious*: int
    widthChange*, heightChange*: int
    glfwWindow: glfw.Window
    title: string
    shouldClose: bool

var glfwInitialized = false
var glfwToWindowTable = initTable[glfw.Window, Window]()

func shouldClose*(window: Window): bool =
  glfw.windowShouldClose(window.glfwWindow).bool

proc `shouldClose=`*(window: Window, v: bool) =
  window.glfwWindow.setWindowShouldClose(v.cint)

func makeContextCurrent*(window: Window) =
  window.glfwWindow.makeContextCurrent()

func swapBuffers*(window: Window) =
  window.glfwWindow.swapBuffers()

template ifWindowExists(glfwWindow: glfw.Window, code: untyped): untyped =
  if glfwToWindowTable.contains(glfwWindow):
    var window {.inject.} = glfwToWindowTable[glfwWindow]
    code

proc closeFn(glfwWindow: glfw.Window) {.cdecl.} =
  if glfwToWindowTable.contains(glfwWindow):
    glfwToWindowTable.del(glfwWindow)
  glfwWindow.destroyWindow()

proc moveFn(glfwWindow: glfw.Window, x, y: cint) {.cdecl.} =
  ifWindowExists(glfwWindow):
    window.xPrevious = window.x
    window.yPrevious = window.y
    window.x = x
    window.y = y
    window.xChange = window.x - window.xPrevious
    window.yChange = window.y - window.yPrevious
    if window.onMove != nil: window.onMove()

proc resizeFn(glfwWindow: glfw.Window, width, height: cint) {.cdecl.} =
  ifWindowExists(glfwWindow):
    window.widthPrevious = window.width
    window.heightPrevious = window.height
    window.width = width
    window.height = height
    window.widthChange = window.width - window.widthPrevious
    window.heightChange = window.height - window.heightPrevious
    if window.onResize != nil: window.onResize()

proc focusFn(glfwWindow: glfw.Window, focused: cint) {.cdecl.} =
  ifWindowExists(glfwWindow):
    case focused:
    of glfw.TRUE:
      if window.onFocus != nil: window.onFocus()
    of glfw.FALSE:
      if window.onLoseFocus != nil: window.onLoseFocus()
    else: discard

proc mouseMoveFn(glfwWindow: glfw.Window, x, y: cdouble) {.cdecl.} =
  ifWindowExists(glfwWindow):
    window.input.mouseXPrevious = window.input.mouseX
    window.input.mouseYPrevious = window.input.mouseY
    window.input.mouseX = x
    window.input.mouseY = y
    window.input.mouseXChange = window.input.mouseX - window.input.mouseXPrevious
    window.input.mouseYChange = window.input.mouseY - window.input.mouseYPrevious
    if window.onMouseMove != nil: window.onMouseMove()

proc mouseButtonFn(glfwWindow: glfw.Window, button, action, mods: cint) {.cdecl.} =
  ifWindowExists(glfwWindow):
    let mouseButton = button.toMouseButton
    if mouseButton.isSome:
      case action:
      of glfw.RELEASE:
        window.input.mouseRelease = mouseButton.get
        if window.onMouseRelease != nil: window.onMouseRelease()
      of glfw.PRESS:
        window.input.mousePress = mouseButton.get
        if window.onMousePress != nil: window.onMousePress()
      else: discard

proc mouseScrollFn(glfwWindow: glfw.Window, xoffset, yoffset: cdouble) {.cdecl.} =
  ifWindowExists(glfwWindow):
    window.input.mouseWheelX = xoffset
    window.input.mouseWheelY = yoffset
    if window.onMouseScroll != nil: window.onMouseScroll()

proc keyFn(glfwWindow: glfw.Window, key, scancode, action, modifiers: cint) {.cdecl.} =
  ifWindowExists(glfwWindow):
    let keyboardKey = key.toKeyboardKey
    if keyboardKey.isSome:
      case action:
      of glfw.RELEASE:
        window.input.keyRelease = keyboardKey.get
        if window.onKeyRelease != nil: window.onKeyRelease()
      of glfw.PRESS:
        window.input.keyPress = keyboardKey.get
        if window.onKeyPress != nil: window.onKeyPress()
      else: discard

proc characterFn(glfwWindow: glfw.Window, character: cuint) {.cdecl.} =
  ifWindowExists(glfwWindow):
    window.input.character = cast[Rune](character).toUTF8
    if window.onCharacter != nil: window.onCharacter()

proc newWindow*(): Window =
  result = Window()
  result.input = newInputState()

  if not glfwInitialized:
    if glfw.init() == 0:
      raise newException(Exception, "Failed to Initialize GLFW.")
    glfwInitialized = true
    addExitProc proc = glfw.terminate()

  result.glfwWindow = glfw.createWindow(800, 600, "Window", nil, nil)

  glfwToWindowTable[result.glfwWindow] = result

  discard glfw.setWindowCloseCallback(result.glfwWindow, closeFn)
  discard glfw.setWindowPosCallback(result.glfwWindow, moveFn)
  discard glfw.setWindowSizeCallback(result.glfwWindow, resizeFn)
  discard glfw.setWindowFocusCallback(result.glfwWindow, focusFn)

  discard glfw.setMouseButtonCallback(result.glfwWindow, mouseButtonFn)
  discard glfw.setScrollCallback(result.glfwWindow, mouseScrollFn)
  discard glfw.setCursorPosCallback(result.glfwWindow, mouseMoveFn)
  discard glfw.setKeyCallback(result.glfwWindow, keyFn)
  discard glfw.setCharCallback(result.glfwWindow, characterFn)