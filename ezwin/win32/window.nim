{.experimental: "overloadableEnums".}

import std/[tables, exitprocs, unicode]
import scancodes
import ../input
import winim/lean

export input

func pollEvents*() =
  var msg: MSG
  while PeekMessage(msg, 0, 0, 0, PM_REMOVE) != 0:
    TranslateMessage(msg)
    DispatchMessage(msg)

type
  Window* = ref object
    onClose*: proc()
    onMinimize*: proc()
    onMaximize*: proc()
    onMove*: proc()
    onResize*: proc()
    # onFocus*: proc()
    # onLoseFocus*: proc()
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
    shouldClose*: bool
    title: string
    hwnd: HWND
    hdc: HDC
    hglrc: HGLRC

proc windowProc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.}

var
  hwndToWindowTable = initTable[HWND, Window]()
  windowClassIsRegistered = false
  windowClass = WNDCLASSEX(
    cbSize: WNDCLASSEX.sizeof.UINT,
    style: CS_CLASSDC,
    lpfnWndProc: windowProc,
    cbClsExtra: 0,
    cbWndExtra: 0,
    hInstance: GetModuleHandle(nil),
    hIcon: 0,
    hCursor: LoadCursor(0, IDC_ARROW),
    hbrBackground: CreateSolidBrush(RGB(0, 0, 0)),
    lpszMenuName: nil,
    lpszClassName: "Default Window Class",
    hIconSm: 0,
  )

func title*(window: Window): string = window.title
func `title=`*(window: Window, value: string) =
  window.title = value
  SetWindowText(window.hwnd, value)

func makeContextCurrent*(window: Window) =
  var pfd = PIXELFORMATDESCRIPTOR(
    nSize: PIXELFORMATDESCRIPTOR.sizeof.WORD,
    nVersion: 1,
  )
  pfd.dwFlags = PFD_DRAW_TO_WINDOW or
                PFD_SUPPORT_OPENGL or
                PFD_SUPPORT_COMPOSITION or
                PFD_DOUBLEBUFFER
  pfd.iPixelType = PFD_TYPE_RGBA
  pfd.cColorBits = 32
  pfd.cAlphaBits = 8
  pfd.iLayerType = PFD_MAIN_PLANE

  window.hdc = GetDC(window.hwnd)
  let format = ChoosePixelFormat(window.hdc, pfd.addr)
  if format == 0:
    raise newException(OSError, "ChoosePixelFormat failed.")

  if SetPixelFormat(window.hdc, format, pfd.addr) == 0:
    raise newException(OSError, "SetPixelFormat failed.")

  var activeFormat = GetPixelFormat(window.hdc)
  if activeFormat == 0:
    raise newException(OSError, "GetPixelFormat failed.")

  if DescribePixelFormat(window.hdc, format, pfd.sizeof.UINT, pfd.addr) == 0:
    raise newException(OSError, "DescribePixelFormat failed.")

  if (pfd.dwFlags and PFD_SUPPORT_OPENGL) != PFD_SUPPORT_OPENGL:
    raise newException(OSError, "PFD_SUPPORT_OPENGL check failed.")

  window.hglrc = wglCreateContext(window.hdc)
  if window.hglrc == 0:
    raise newException(OSError, "wglCreateContext failed.")

  wglMakeCurrent(window.hdc, window.hglrc)

func swapBuffers*(window: Window) =
  SwapBuffers(window.hdc)

func updateBounds(window: Window) =
  var windowRect: RECT
  GetWindowRect(window.hwnd, windowRect.addr)

  var clientScreenCoords: POINT
  ClientToScreen(window.hwnd, clientScreenCoords.addr)

  let titleBarHeight = clientScreenCoords.y - windowRect.top
  let fullWindowWidth = windowRect.right - windowRect.left
  let fullWindowHeight = windowRect.top - windowRect.bottom

  window.xPrevious = window.x
  window.yPrevious = window.y
  window.widthPrevious = window.width
  window.heightPrevious = window.height

  window.x = clientScreenCoords.x
  window.y = clientScreenCoords.y
  window.width = fullWindowWidth
  window.height = fullWindowHeight - titleBarHeight

template ifWindowExists(hwnd: HWND, code: untyped): untyped =
  if hwndToWindowTable.contains(hwnd):
    var window {.inject.} = hwndToWindowTable[hwnd]
    code

proc windowProc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  case msg:
  of WM_INITDIALOG:
    SetFocus(hwnd)

  of WM_CLOSE:
    ifWindowExists(hwnd):
      if window.onClose != nil: window.onClose()
    DestroyWindow(hwnd)

  of WM_DESTROY:
    ifWindowExists(hwnd):
      window.shouldClose = true
    hwndToWindowTable.del(hwnd)

  of WM_SIZE:
    ifWindowExists(hwnd):
      window.updateBounds()
      if window.onResize != nil: window.onResize()

  of WM_MOVE:
    ifWindowExists(hwnd):
      window.updateBounds()
      if window.onResize != nil: window.onMove()

  of WM_SYSCOMMAND:
    ifWindowExists(hwnd):
      case wParam:
      of SC_MINIMIZE:
        window.updateBounds()
        if window.onMinimize != nil: window.onMinimize()
      of SC_MAXIMIZE:
        window.updateBounds()
        if window.onMaximize != nil: window.onMaximize()
      else: discard

  of WM_MOUSEMOVE:
    ifWindowExists(hwnd):
      window.input.mouseXPrevious = window.input.mouseX
      window.input.mouseYPrevious = window.input.mouseY
      window.input.mouseX = GET_X_LPARAM(lParam).float
      window.input.mouseY = GET_Y_LPARAM(lParam).float
      if window.onMouseMove != nil: window.onMouseMove()

  of WM_MOUSEWHEEL:
    ifWindowExists(hwnd):
      window.input.mouseWheelY = GET_WHEEL_DELTA_WPARAM(wParam).float / WHEEL_DELTA.float
      if window.onMouseScroll != nil: window.onMouseScroll()

  of WM_MOUSEHWHEEL:
    ifWindowExists(hwnd):
      window.input.mouseWheelX = GET_WHEEL_DELTA_WPARAM(wParam).float / WHEEL_DELTA.float
      if window.onMouseScroll != nil: window.onMouseScroll()

  of WM_LBUTTONDOWN, WM_LBUTTONDBLCLK,
     WM_MBUTTONDOWN, WM_MBUTTONDBLCLK,
     WM_RBUTTONDOWN, WM_RBUTTONDBLCLK,
     WM_XBUTTONDOWN, WM_XBUTTONDBLCLK:
    ifWindowExists(hwnd):
      SetCapture(hwnd)
      window.input.mousePress = toMouseButton(msg, wParam)
      if window.onMousePress != nil: window.onMousePress()

  of WM_LBUTTONUP, WM_MBUTTONUP, WM_RBUTTONUP, WM_XBUTTONUP:
    ifWindowExists(hwnd):
      ReleaseCapture()
      window.input.mouseRelease = toMouseButton(msg, wParam)
      if window.onMouseRelease != nil: window.onMouseRelease()

  of WM_KEYDOWN, WM_SYSKEYDOWN:
    ifWindowExists(hwnd):
      window.input.keyPress = toKeyboardKey(wParam.int)
      if window.onKeyPress != nil: window.onKeyRelease()

  of WM_KEYUP, WM_SYSKEYUP:
    ifWindowExists(hwnd):
      window.input.keyRelease = toKeyboardKey(wParam.int)
      if window.onKeyRelease != nil: window.onKeyRelease()

  of WM_CHAR, WM_SYSCHAR:
    ifWindowExists(hwnd):
      if wParam > 0 and wParam < 0x10000:
        window.input.character = cast[Rune](wParam).toUTF8
        if window.onCharacter != nil: window.onCharacter()

  else: discard

  DefWindowProc(hwnd, msg, wParam, lParam)

proc newWindow*(title = "Window",
                x, y = 0,
                width = 1024, height = 768,
                parent: HWND = 0): Window =
  result = Window()
  result.input = newInputState()
  result.title = title

  if not windowClassIsRegistered:
    RegisterClassEx(windowClass)
    windowClassIsRegistered = true
    addExitProc(proc =
      UnregisterClass(windowClass.lpszClassName,
                      windowClass.hInstance)
    )

  result.hwnd = CreateWindow(
    lpClassName = windowClass.lpszClassName,
    lpWindowName = title,
    dwStyle = WS_OVERLAPPEDWINDOW,
    x = x.int32,
    y = y.int32,
    nWidth = width.int32,
    nHeight = height.int32,
    hWndParent = parent,
    hMenu = 0,
    hInstance = windowClass.hInstance,
    lpParam = nil,
  )

  hwndToWindowTable[result.hwnd] = result

  ShowWindow(result.hwnd, SW_SHOWDEFAULT)
  UpdateWindow(result.hwnd)
  InvalidateRect(result.hwnd, nil, 1)

  result.updateBounds()