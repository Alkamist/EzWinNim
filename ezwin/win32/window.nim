import std/[tables, options, unicode, exitprocs]
import winim/lean
import ../input

proc windowProc(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.}

type
  Window* = ref object
    input*: input.Input
    onClose*: proc()
    onTimer*: proc()
    onDraw*: proc()
    onResize*: proc()
    onMove*: proc()
    onMaximize*: proc()
    onMinimize*: proc()
    onMouseMove*: proc()
    onMouseLeave*: proc()
    onMouseWheel*: proc()
    onMouseHWheel*: proc()
    onMousePress*: proc()
    onMouseRelease*: proc()
    onChar*: proc()
    onKeyPress*: proc()
    onKeyRelease*: proc()
    hWnd: HWND
    position: (int, int)
    dimensions: (int, int)
    clientPosition: (int, int)
    clientDimensions: (int, int)
    title: string
    dpi: float
    shouldClose: bool
    hasTimer: bool

const timerId = 2
var
  hWndToWindowTable = initTable[HWND, Window]()
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

proc handle*(window: Window): HWND = window.hWnd
proc title*(window: Window): string = window.title
proc dpi*(window: Window): float = window.dpi

proc position*(window: Window): (int, int) = window.position
proc dimensions*(window: Window): (int, int) = window.dimensions
proc x*(window: Window): int = window.position[0]
proc y*(window: Window): int = window.position[1]
proc width*(window: Window): int = window.dimensions[0]
proc height*(window: Window): int = window.dimensions[1]
proc left*(window: Window): int = window.x
proc right*(window: Window): int = window.x + window.width
proc top*(window: Window): int = window.y
proc bottom*(window: Window): int = window.y + window.height
proc aspectRatio*(window: Window): float = window.width / window.height

proc clientPosition*(window: Window): (int, int) = window.clientPosition
proc clientDimensions*(window: Window): (int, int) = window.clientDimensions
proc clientX*(window: Window): int = window.clientPosition[0]
proc clientY*(window: Window): int = window.clientPosition[1]
proc clientWidth*(window: Window): int = window.clientDimensions[0]
proc clientHeight*(window: Window): int = window.clientDimensions[1]
proc clientLeft*(window: Window): int = window.clientX
proc clientRight*(window: Window): int = window.clientX + window.clientWidth
proc clientTop*(window: Window): int = window.clientY
proc clientBottom*(window: Window): int = window.clientY + window.clientHeight
proc clientAspectRatio*(window: Window): float = window.clientWidth / window.clientHeight

proc shouldClose*(window: Window): bool = window.shouldClose

proc `title=`*(window: Window, value: string) =
  SetWindowText(window.hWnd, value)

proc setBounds*(window: Window,
                x = window.x, y = window.y,
                width = window.width, height = window.height) =
  SetWindowPos(
    window.hWnd,
    GetParent(window.hWnd),
    x.int32, y.int32,
    width.int32, height.int32,
    SWP_NOACTIVATE,
  )

proc pollEvents*(window: Window) =
  var msg: MSG
  while PeekMessage(msg, window.hWnd, 0, 0, PM_REMOVE) != 0:
    TranslateMessage(msg)
    DispatchMessage(msg)

proc enableTimer*(window: Window, loopEvery: int) =
  SetTimer(window.hWnd, timerId, loopEvery.UINT, nil)
  window.hasTimer = true

proc disableTimer*(window: Window) =
  if window.hasTimer:
    KillTimer(window.hWnd, timerId)
    window.hasTimer = false

proc redraw*(window: Window) =
  InvalidateRect(window.hWnd, nil, 1)

proc updatePositionAndDimensions(window: Window) =
  var windowRect, clientRect: lean.RECT

  GetClientRect(window.hWnd, clientRect.addr)
  window.clientPosition = (
    clientRect.left.int,
    clientRect.top.int,
  )
  window.clientDimensions = (
    (clientRect.right - clientRect.left).int,
    (clientRect.bottom - clientRect.top).int,
  )

  GetWindowRect(window.hWnd, windowRect.addr)
  window.position = (
    windowRect.left.int,
    windowRect.top.int,
  )
  window.dimensions = (
    (windowRect.right - windowRect.left).int,
    (windowRect.bottom - windowRect.top).int,
  )

proc windowProc(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  template ifWindow(code: untyped): untyped =
    if hWndToWindowTable.contains(hWnd):
      var window {.inject.} = hWndToWindowTable[hWnd]
      code

  template getMouseButtonKind(): untyped =
    case msg:
    of WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK: some(Left)
    of WM_MBUTTONDOWN, WM_MBUTTONUP, WM_MBUTTONDBLCLK: some(Middle)
    of WM_RBUTTONDOWN, WM_RBUTTONUP, WM_RBUTTONDBLCLK: some(Right)
    of WM_XBUTTONDOWN, WM_XBUTTONUP, WM_XBUTTONDBLCLK:
      if HIWORD(wParam) == 1: some(Side1)
      else: some(Side2)
    else: none(MouseButton)

  case msg:

  of WM_INITDIALOG:
    SetFocus(hWnd)

  of WM_KILLFOCUS:
    ifWindow:
      for state in window.input.keyStates.mitems:
        state = false

  of WM_CLOSE:
    ifWindow:
      if window.onClose != nil:
        window.onClose()
    DestroyWindow(hWnd)

  of WM_DESTROY:
    ifWindow:
      window.shouldClose = true
    hWndToWindowTable.del(hWnd)

  of WM_TIMER:
    ifWindow:
      if window.onTimer != nil:
        window.onTimer()

  of WM_SIZE:
    ifWindow:
      window.updatePositionAndDimensions()
      if window.onResize != nil:
        window.onResize()

  of WM_MOVE:
    ifWindow:
      window.updatePositionAndDimensions()
      if window.onMove != nil:
        window.onMove()

  of WM_SYSCOMMAND:
    ifWindow:
      case wParam:
      of SC_MINIMIZE:
        if window.onMinimize != nil:
          window.onMinimize()
      of SC_MAXIMIZE:
        if window.onMaximize != nil:
          window.onMaximize()
      else:
        discard

  of WM_PAINT:
    ifWindow:
      if window.onDraw != nil:
        window.onDraw()

  of WM_MOUSEMOVE:
    ifWindow:
      window.input.previousMousePosition[0] = window.input.mousePosition[0]
      window.input.previousMousePosition[1] = window.input.mousePosition[1]
      window.input.mousePosition[0] = GET_X_LPARAM(lParam)
      window.input.mousePosition[1] = GET_Y_LPARAM(lParam)
      if window.onMouseMove != nil:
        window.onMouseMove()

  of WM_MOUSELEAVE:
    ifWindow:
      if window.onMouseLeave != nil:
        window.onMouseLeave()

  of WM_MOUSEWHEEL:
    ifWindow:
      window.input.mouseWheel = GET_WHEEL_DELTA_WPARAM(wParam).float / WHEEL_DELTA.float
      if window.onMouseWheel != nil:
        window.onMouseWheel()

  of WM_MOUSEHWHEEL:
    ifWindow:
      window.input.mouseHWheel = GET_WHEEL_DELTA_WPARAM(wParam).float / WHEEL_DELTA.float
      if window.onMouseHWheel != nil:
        window.onMouseHWheel()

  of WM_LBUTTONDOWN, WM_LBUTTONDBLCLK,
     WM_MBUTTONDOWN, WM_MBUTTONDBLCLK,
     WM_RBUTTONDOWN, WM_RBUTTONDBLCLK,
     WM_XBUTTONDOWN, WM_XBUTTONDBLCLK:
    ifWindow:
      let button = getMouseButtonKind()
      if button.isSome:
        SetCapture(window.hWnd)
        window.input.mouseButtonStates[button.get] = true
        if window.onMousePress != nil:
          window.input.lastMousePress = button.get
          window.input.lastMousePressWasDoubleClick = msg in [WM_LBUTTONDBLCLK,
                                                              WM_MBUTTONDBLCLK,
                                                              WM_RBUTTONDBLCLK,
                                                              WM_XBUTTONDBLCLK]
          window.onMousePress()

  of WM_LBUTTONUP, WM_MBUTTONUP, WM_RBUTTONUP, WM_XBUTTONUP:
    ifWindow:
      let button = getMouseButtonKind()
      if button.isSome:
        ReleaseCapture()
        window.input.mouseButtonStates[button.get] = false
        if window.onMouseRelease != nil:
          window.input.lastMouseRelease = button.get
          window.onMouseRelease()

  of WM_KEYDOWN, WM_SYSKEYDOWN:
    ifWindow:
      let key = wParam.int.toKeyboardKey
      if key.isSome:
        window.input.keyStates[key.get] = true
        if window.onKeyPress != nil:
          window.input.lastKeyPress = key.get
          window.onKeyPress()

  of WM_KEYUP, WM_SYSKEYUP:
    ifWindow:
      let key = wParam.int.toKeyboardKey
      if key.isSome:
        window.input.keyStates[key.get] = false
        if window.onKeyRelease != nil:
          window.input.lastKeyRelease = key.get
          window.onKeyRelease()

  of WM_CHAR, WM_SYSCHAR:
    ifWindow:
      if wParam > 0 and wParam < 0x10000:
        window.input.lastChar = cast[Rune](wParam).toUTF8
        if window.onChar != nil:
          window.onChar()

  else:
    discard

  DefWindowProc(hWnd, msg, wParam, lParam)

proc newWindow*(title: string,
                x, y = 0,
                width = 1024, height = 768,
                parent: HWND = 0): Window =
  result = Window()
  result.input = newInput()
  result.dpi = 96.0

  if not windowClassIsRegistered:
    RegisterClassEx(windowClass)
    windowClassIsRegistered = true
    addExitProc(proc =
      UnregisterClass(windowClass.lpszClassName,
                      windowClass.hInstance)
    )

  let hWnd = CreateWindow(
    lpClassName = windowClass.lpszClassName,
    lpWindowName = title,
    dwStyle = WS_OVERLAPPEDWINDOW,
    x = x.int32, y = y.int32,
    nWidth = width.int32, nHeight = height.int32,
    hWndParent = parent,
    hMenu = 0,
    hInstance = windowClass.hInstance,
    lpParam = nil,
  )

  result.hWnd = hWnd
  hWndToWindowTable[hWnd] = result

  result.updatePositionAndDimensions()

  ShowWindow(hWnd, SW_SHOWDEFAULT)
  UpdateWindow(hWnd)
  InvalidateRect(hWnd, nil, 1)