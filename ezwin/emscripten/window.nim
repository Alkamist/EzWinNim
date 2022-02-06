import std/tables
import api, scancodes
import ../windowlogic
import ../mouselogic
import ../keyboardlogic

type
  Window* = ref object of WindowLogic
    mouse*: MouseLogic
    keyboard*: KeyboardLogic
    webGlContext: EMSCRIPTEN_WEBGL_CONTEXT_HANDLE

var pointerToWindowTable = newTable[pointer, Window]()

func pollEvents*(window: Window) = discard
func swapBuffers*(window: Window) = discard

func makeContextCurrent*(window: Window) =
  discard emscripten_webgl_make_context_current(window.webGlContext)

template ifWindowExists(address: pointer, code: untyped): untyped =
  if pointerToWindowTable.contains(address):
    var window {.inject.} = pointerToWindowTable[address]
    code

proc mouseMoveFn(eventType: cint, mouseEvent: ptr EmscriptenMouseEvent, userData: pointer): EM_BOOL {.cdecl.} =
  ifWindowExists(userData):
    window.mouse.processMove(mouseEvent.clientX.float, mouseEvent.clientY.float)

proc mousePressFn(eventType: cint, mouseEvent: ptr EmscriptenMouseEvent, userData: pointer): EM_BOOL {.cdecl.} =
  ifWindowExists(userData):
    window.mouse.processPress(toMouseButton(mouseEvent.button))

proc mouseReleaseFn(eventType: cint, mouseEvent: ptr EmscriptenMouseEvent, userData: pointer): EM_BOOL {.cdecl.} =
  ifWindowExists(userData):
    window.mouse.processRelease(toMouseButton(mouseEvent.button))

proc mouseScrollFn(eventType: cint, wheelEvent: ptr EmscriptenWheelEvent, userData: pointer): EM_BOOL {.cdecl.} =
  ifWindowExists(userData):
    window.mouse.processScroll(wheelEvent.deltaX / 100.0, wheelEvent.deltaY / 100.0)

proc newWindow*(title = "Window",
                x, y = 0,
                width = 1024, height = 768,
                parent: int = 0): Window =
  result = Window()
  result.mouse = MouseLogic()
  result.keyboard = KeyboardLogic()

  var attributes: EmscriptenWebGLContextAttributes
  emscripten_webgl_init_context_attributes(attributes.addr)
  attributes.stencil = true.EM_BOOL
  attributes.depth = true.EM_BOOL
  result.webGlContext = emscripten_webgl_create_context("#canvas", attributes.addr)

  pointerToWindowTable[result.addr] = result

  discard emscripten_set_mousemove_callback("#canvas", result.addr, true.EM_BOOL, mouseMoveFn)
  discard emscripten_set_mousedown_callback("#canvas", result.addr, true.EM_BOOL, mousePressFn)
  discard emscripten_set_mouseup_callback("#canvas", result.addr, true.EM_BOOL, mouseReleaseFn)
  discard emscripten_set_wheel_callback("#canvas", result.addr, true.EM_BOOL, mouseScrollFn)