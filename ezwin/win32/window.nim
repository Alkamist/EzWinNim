import std/[unicode, tables, exitprocs]
import scancodes
import ../windowlogic
import ../mouselogic
import ../keyboardlogic
import winim/lean

proc windowProc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.}

type
  Window* = ref object of WindowLogic
    mouse*: MouseLogic
    keyboard*: KeyboardLogic
    hwnd: HWND
    hdc: HDC
    hglrc: HGLRC

var hwndToWindowTable = newTable[HWND, Window]()
var windowClassIsRegistered = false
var windowClass = WNDCLASSEX(
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

func pollEvents*(window: Window) =
  var msg: MSG
  while PeekMessage(msg, window.hwnd, 0, 0, PM_REMOVE) != 0:
    TranslateMessage(msg)
    DispatchMessage(msg)

func swapBuffers*(window: Window) =
  SwapBuffers(window.hdc)

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

template ifWindowExists(hwnd: HWND, code: untyped): untyped =
  if hwndToWindowTable.contains(hwnd):
    var window {.inject.} = hwndToWindowTable[hwnd]
    code

proc windowProc(hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  case msg:
  of WM_CLOSE:
    ifWindowExists(hwnd):
      window.processClose()
  of WM_SIZE:
    ifWindowExists(hwnd):
      var windowRect: RECT
      GetWindowRect(hwnd, windowRect.addr)
      var clientScreenCoords: POINT
      ClientToScreen(hwnd, clientScreenCoords.addr)
      let titleBarHeight = (clientScreenCoords.y - windowRect.top).float
      let fullWindowWidth = (windowRect.right - windowRect.left).float
      let fullWindowHeight = (windowRect.top - windowRect.bottom).float
      window.processResize(fullWindowWidth, fullWindowHeight - titleBarHeight)
  of WM_MOVE:
    ifWindowExists(hwnd):
      var clientScreenCoords: POINT
      ClientToScreen(hwnd, clientScreenCoords.addr)
      window.processMove(clientScreenCoords.x.float, clientScreenCoords.y.float)
  of WM_SYSCOMMAND:
    ifWindowExists(hwnd):
      case wParam:
      of SC_MINIMIZE:
        window.processMinimize()
      of SC_MAXIMIZE:
        window.processMaximize()
      else: discard
  of WM_MOUSEMOVE:
    ifWindowExists(hwnd):
      window.mouse.processMove(GET_X_LPARAM(lParam).float, GET_Y_LPARAM(lParam).float)
  of WM_MOUSEWHEEL:
    ifWindowExists(hwnd):
      window.mouse.processScroll(0.0, GET_WHEEL_DELTA_WPARAM(wParam).float / WHEEL_DELTA.float)
  of WM_MOUSEHWHEEL:
    ifWindowExists(hwnd):
      window.mouse.processScroll(GET_WHEEL_DELTA_WPARAM(wParam).float / WHEEL_DELTA.float, 0.0)
  of WM_LBUTTONDOWN, WM_LBUTTONDBLCLK,
     WM_MBUTTONDOWN, WM_MBUTTONDBLCLK,
     WM_RBUTTONDOWN, WM_RBUTTONDBLCLK,
     WM_XBUTTONDOWN, WM_XBUTTONDBLCLK:
    ifWindowExists(hwnd):
      SetCapture(hwnd)
      window.mouse.processPress(toMouseButton(msg, wParam))
  of WM_LBUTTONUP, WM_MBUTTONUP, WM_RBUTTONUP, WM_XBUTTONUP:
    ifWindowExists(hwnd):
      ReleaseCapture()
      window.mouse.processRelease(toMouseButton(msg, wParam))
  of WM_KEYDOWN, WM_SYSKEYDOWN:
    ifWindowExists(hwnd):
      window.keyboard.processPress(toKeyboardKey(wParam.int))
  of WM_KEYUP, WM_SYSKEYUP:
    ifWindowExists(hwnd):
      window.keyboard.processRelease(toKeyboardKey(wParam.int))
  of WM_CHAR, WM_SYSCHAR:
    ifWindowExists(hwnd):
      if wParam > 0 and wParam < 0x10000:
        window.keyboard.processCharacter(cast[Rune](wParam).toUTF8)
  else:
    discard

  DefWindowProc(hwnd, msg, wParam, lParam)

proc newWindow*(title = "Window",
                x, y = 0,
                width = 1024, height = 768,
                parent: HWND = 0): Window =
  result = Window()
  result.mouse = MouseLogic()
  result.keyboard = KeyboardLogic()

  if not windowClassIsRegistered:
    RegisterClassEx(windowClass)
    windowClassIsRegistered = true
    addExitProc(proc =
      UnregisterClass(windowClass.lpszClassName, windowClass.hInstance)
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