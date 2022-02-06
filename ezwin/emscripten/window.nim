import api, scancodes
import ../windowlogic
import ../mouselogic
import ../keyboardlogic

when defined(emscripten):
  {.passL: "-s EXPORTED_RUNTIME_METHODS=ccall".}
  {.passL: "-s EXPORTED_FUNCTIONS=_main,_mouseReleaseFn".}

type
  Window* = ref object of WindowLogic
    mouse*: MouseLogic
    keyboard*: KeyboardLogic
    webGlContext: EMSCRIPTEN_WEBGL_CONTEXT_HANDLE

var window = Window()
window.mouse = MouseLogic()
window.keyboard = KeyboardLogic()

var attributes: EmscriptenWebGLContextAttributes
emscripten_webgl_init_context_attributes(attributes.addr)
attributes.stencil = true.EM_BOOL
attributes.depth = true.EM_BOOL
window.webGlContext = emscripten_webgl_create_context("#canvas", attributes.addr)

func pollEvents*(window: Window) = discard
func swapBuffers*(window: Window) = discard

func makeContextCurrent*(window: Window) =
  discard emscripten_webgl_make_context_current(window.webGlContext)

# template ifWindowExists(address: pointer, code: untyped): untyped =
#   if pointerToWindowTable.contains(address):
#     var window {.inject.} = pointerToWindowTable[address]
#     code

# proc mouseMoveFn(eventType: cint, mouseEvent: ptr EmscriptenMouseEvent, userData: pointer): EM_BOOL {.cdecl.} =
#   ifWindowExists(userData):
#     window.mouse.processMove(mouseEvent.clientX.float, mouseEvent.clientY.float)

# proc mousePressFn(eventType: cint, mouseEvent: ptr EmscriptenMouseEvent, userData: pointer): EM_BOOL {.cdecl.} =
#   ifWindowExists(userData):
#     window.mouse.processPress(toMouseButton(mouseEvent.button))

# proc mouseReleaseFn(eventType: cint, mouseEvent: ptr EmscriptenMouseEvent, userData: pointer): EM_BOOL {.cdecl.} =
#   ifWindowExists(userData):
#     window.mouse.processRelease(toMouseButton(mouseEvent.button))

# proc mouseScrollFn(eventType: cint, wheelEvent: ptr EmscriptenWheelEvent, userData: pointer): EM_BOOL {.cdecl.} =
#   ifWindowExists(userData):
#     window.mouse.processScroll(wheelEvent.deltaX / 100.0, wheelEvent.deltaY / 100.0)

proc mouseReleaseFn(button: int) {.exportc.} =
  window.mouse.processRelease(toMouseButton(button))

emscripten_run_script("""
function onMouseRelease(e) {
  Module.ccall('mouseReleaseFn', null, ['number'], [e.button]);
}
window.addEventListener("mouseup", onMouseRelease);
""")

proc newWindow*(title = "Window",
                x, y = 0,
                width = 1024, height = 768,
                parent: int = 0): Window =
  result = window