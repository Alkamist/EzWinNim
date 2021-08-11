import
  std/[tables, options],
  winim/lean,
  input

export input

proc windowProc(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.}

template toPixels(inches, dpi): untyped = (inches * dpi).toInt
template toInches(pixels, dpi): untyped = pixels.float / dpi

type
  Window* = ref object
    input*: input.Input
    onClose*: proc()
    onTimer*: proc()
    onDraw*: proc()
    onResize*: proc()
    onMove*: proc()
    onMouseMove*: proc()
    onMousePress*: proc()
    onMouseRelease*: proc()
    onKeyPress*: proc()
    onKeyRelease*: proc()
    hWnd: HWND
    hdc: HDC
    rect: RECT
    clientRect: RECT
    title: string
    dpi: float
    shouldClose: bool
    hasTimer: bool

const timerId = 2
var
  hWndToWindowTable = initTable[HWND, Window]()
  windowClassCount = 0
  windowClass = WNDCLASSEX(
    cbSize: WNDCLASSEX.sizeof.UINT,
    style: CS_CLASSDC,
    lpfnWndProc: windowProc,
    cbClsExtra: 0,
    cbWndExtra: 0,
    hInstance: GetModuleHandle(nil),
    hIcon: 0,
    hCursor: 0,
    hbrBackground: 0,
    lpszMenuName: nil,
    lpszClassName: "Default Window Class",
    hIconSm: 0,
  )

proc title*(window: Window): string {.inline.} = window.title
proc left*(window: Window): float {.inline.} = window.rect.left.toInches(window.dpi)
proc right*(window: Window): float {.inline.} = window.rect.right.toInches(window.dpi)
proc top*(window: Window): float {.inline.} = window.rect.top.toInches(window.dpi)
proc bottom*(window: Window): float {.inline.} = window.rect.bottom.toInches(window.dpi)
proc x*(window: Window): float {.inline.} = window.left
proc y*(window: Window): float {.inline.} = window.top
proc position*(window: Window): (float, float) {.inline.} = (window.x, window.y)
proc width*(window: Window): float {.inline.} = abs(window.right - window.left)
proc height*(window: Window): float {.inline.} = abs(window.bottom - window.top)
proc dimensions*(window: Window): (float, float) {.inline.} = (window.width, window.height)
proc bounds*(window: Window): ((float, float), (float, float)) {.inline.} = (window.position, window.dimensions)
proc clientLeft*(window: Window): float {.inline.} = window.clientRect.left.toInches(window.dpi)
proc clientRight*(window: Window): float {.inline.} = window.clientRect.right.toInches(window.dpi)
proc clientTop*(window: Window): float {.inline.} = window.clientRect.top.toInches(window.dpi)
proc clientBottom*(window: Window): float {.inline.} = window.clientRect.bottom.toInches(window.dpi)
proc clientX*(window: Window): float {.inline.} = window.clientLeft
proc clientY*(window: Window): float {.inline.} = window.clientRight
proc clientPosition*(window: Window): (float, float) {.inline.} = (window.clientX, window.clientY)
proc clientWidth*(window: Window): float {.inline.} = abs(window.clientRight - window.clientLeft)
proc clientHeight*(window: Window): float {.inline.} = abs(window.clientBottom - window.clientTop)
proc clientDimensions*(window: Window): (float, float) {.inline.} = (window.clientWidth, window.clientHeight)
proc clientBounds*(window: Window): ((float, float), (float, float)) {.inline.} = (window.clientPosition, window.clientDimensions)
proc shouldClose*(window: Window): bool {.inline.} = window.shouldClose

proc `title=`*(window: Window, value: string) {.inline.} =
  SetWindowText(window.hWnd, value)

proc `bounds=`*(window: Window, value: ((float, float), (float, float))) {.inline.} =
  SetWindowPos(
    window.hWnd,
    GetParent(window.hWnd),
    value[0][0].toPixels(window.dpi).int32,
    value[0][1].toPixels(window.dpi).int32,
    value[1][0].toPixels(window.dpi).int32,
    value[1][1].toPixels(window.dpi).int32,
    SWP_NOACTIVATE,
  )

proc pollEvents*(window: Window) {.inline.} =
  var msg: MSG
  while PeekMessage(msg, window.hWnd, 0, 0, PM_REMOVE):
    TranslateMessage(msg)
    DispatchMessage(msg)

proc enableTimer*(window: Window, loopEvery: cint) =
  SetTimer(window.hWnd, timerId, loopEvery.UINT, nil)
  window.hasTimer = true

proc disableTimer*(window: Window) =
  if window.hasTimer:
    KillTimer(window.hWnd, timerId)
    window.hasTimer = false

proc updateBounds(window: Window) {.inline.} =
  GetClientRect(window.hWnd, window.clientRect.addr)
  GetWindowRect(window.hWnd, window.rect.addr)

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

  of WM_CLOSE:
    ifWindow:
      if window.onClose != nil:
        window.onClose()
    DestroyWindow(hWnd)

  of WM_DESTROY:
    ifWindow:
      window.shouldClose = true
    hWndToWindowTable.del(hWnd)

    windowClassCount.dec
    if windowClassCount == 0:
      UnregisterClass(windowClass.lpszClassName, windowClass.hInstance)

  of WM_MOUSEMOVE:
    ifWindow:
      window.input.previousMousePosition[0] = window.input.mousePosition[0]
      window.input.previousMousePosition[1] = window.input.mousePosition[1]
      window.input.mousePosition[0] = GET_X_LPARAM(lParam).toInches(window.dpi)
      window.input.mousePosition[1] = GET_Y_LPARAM(lParam).toInches(window.dpi)
      if window.onMouseMove != nil:
        window.onMouseMove()

  of WM_TIMER:
    ifWindow:
      if window.onTimer != nil:
        window.onTimer()

  of WM_SIZE:
    ifWindow:
      window.updateBounds()
      if window.onResize != nil:
        window.onResize()

  of WM_MOVE:
    ifWindow:
      window.updateBounds()
      if window.onMove != nil:
        window.onMove()

  of WM_PAINT:
    ifWindow:
      var paintStruct = PAINTSTRUCT()
      window.hdc = window.hWnd.BeginPaint(paintStruct.addr)
      if window.onDraw != nil:
        window.onDraw()
      window.hWnd.EndPaint(paintStruct.addr)

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

  else:
    discard

  DefWindowProc(hWnd, msg, wParam, lParam)

proc newWindow*(title: string,
                bounds: ((float, float), (float, float)),
                parent: HWND = 0): Window =
  result = Window()
  result.input = newInput()
  result.dpi = 96.0

  if windowClassCount == 0:
    RegisterClassEx(windowClass)

  windowClassCount.inc

  let hWnd = CreateWindow(
    lpClassName = windowClass.lpszClassName,
    lpWindowName = title,
    dwStyle = WS_OVERLAPPEDWINDOW,
    x = bounds[0][0].toPixels(result.dpi).int32,
    y = bounds[0][1].toPixels(result.dpi).int32,
    nWidth = bounds[1][0].toPixels(result.dpi).int32,
    nHeight = bounds[1][1].toPixels(result.dpi).int32,
    hWndParent = parent,
    hMenu = 0,
    hInstance = windowClass.hInstance,
    lpParam = nil,
  )

  result.hWnd = hWnd
  hWndToWindowTable[hWnd] = result

  ShowWindow(hwnd, SW_SHOWDEFAULT)
  UpdateWindow(hwnd)