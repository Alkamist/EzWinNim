import
  std/[tables, options, unicode],
  pixie, winim/lean,
  input

export input

proc windowProc(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.}

template toPixels(inches, dpi): untyped = (inches * dpi).toInt
template toInches(pixels, dpi): untyped = pixels.float / dpi

type
  Window* = ref object
    image*: pixie.Image
    context*: pixie.Context
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
    position: (float, float)
    dimensions: (float, float)
    clientPosition: (float, float)
    clientDimensions: (float, float)
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

proc position*(window: Window): (float, float) {.inline.} = window.position
proc dimensions*(window: Window): (float, float) {.inline.} = window.dimensions
proc x*(window: Window): float {.inline.} = window.position[0]
proc y*(window: Window): float {.inline.} = window.position[1]
proc width*(window: Window): float {.inline.} = window.dimensions[0]
proc height*(window: Window): float {.inline.} = window.dimensions[1]
proc left*(window: Window): float {.inline.} = window.x
proc right*(window: Window): float {.inline.} = window.x + window.width
proc top*(window: Window): float {.inline.} = window.y
proc bottom*(window: Window): float {.inline.} = window.y + window.height

proc clientPosition*(window: Window): (float, float) {.inline.} = window.clientPosition
proc clientDimensions*(window: Window): (float, float) {.inline.} = window.clientDimensions
proc clientX*(window: Window): float {.inline.} = window.clientPosition[0]
proc clientY*(window: Window): float {.inline.} = window.clientPosition[1]
proc clientWidth*(window: Window): float {.inline.} = window.clientDimensions[0]
proc clientHeight*(window: Window): float {.inline.} = window.clientDimensions[1]
proc clientLeft*(window: Window): float {.inline.} = window.clientX
proc clientRight*(window: Window): float {.inline.} = window.clientX + window.clientWidth
proc clientTop*(window: Window): float {.inline.} = window.clientY
proc clientBottom*(window: Window): float {.inline.} = window.clientY + window.clientHeight

proc shouldClose*(window: Window): bool {.inline.} = window.shouldClose

proc `title=`*(window: Window, value: string) {.inline.} =
  SetWindowText(window.hWnd, value)

proc setBounds*(window: Window,
                x = window.x, y = window.y,
                width = window.width, height = window.height) {.inline.} =
  SetWindowPos(
    window.hWnd,
    GetParent(window.hWnd),
    x.toPixels(window.dpi).int32,
    y.toPixels(window.dpi).int32,
    width.toPixels(window.dpi).int32,
    height.toPixels(window.dpi).int32,
    SWP_NOACTIVATE,
  )

proc pollEvents*(window: Window) {.inline.} =
  var msg: MSG
  while PeekMessage(msg, window.hWnd, 0, 0, PM_REMOVE) != 0:
    TranslateMessage(msg)
    DispatchMessage(msg)

proc enableTimer*(window: Window, loopEvery: cint) {.inline.} =
  SetTimer(window.hWnd, timerId, loopEvery.UINT, nil)
  window.hasTimer = true

proc disableTimer*(window: Window) {.inline.} =
  if window.hasTimer:
    KillTimer(window.hWnd, timerId)
    window.hasTimer = false

proc redraw*(window: Window) {.inline.} =
  InvalidateRect(window.hWnd, nil, 1)

proc resizeImage(window: Window) {.inline.} =
  window.image.width = window.clientWidth.toPixels(window.dpi).int
  window.image.height = window.clientHeight.toPixels(window.dpi).int
  window.image.data.setLen(window.image.width * window.image.height)

proc drawImage(window: Window) {.inline.} =
  let
    w = window.image.width.int32
    h = window.image.height.int32
    dc = GetDC(window.hWnd)

  var info = BITMAPINFO()
  info.bmiHeader.biBitCount = 32
  info.bmiHeader.biWidth = w
  info.bmiHeader.biHeight = h
  info.bmiHeader.biPlanes = 1
  info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER).DWORD
  info.bmiHeader.biSizeImage = w * h * 4
  info.bmiHeader.biCompression = BI_RGB

  var bgrBuffer = newSeq[uint8](window.image.data.len * 4)

  # Convert to BGRA.
  for i, c in window.image.data:
    bgrBuffer[i*4+0] = c.b
    bgrBuffer[i*4+1] = c.g
    bgrBuffer[i*4+2] = c.r

  StretchDIBits(
    dc,
    0,
    h - 1,
    w,
    -h,
    0,
    0,
    w,
    h,
    bgrBuffer[0].addr,
    info,
    DIB_RGB_COLORS,
    SRCCOPY
  )
  ReleaseDC(window.hWnd, dc)

proc updatePositionAndDimensions(window: Window) {.inline.} =
  var windowRect, clientRect: lean.RECT

  GetClientRect(window.hWnd, clientRect.addr)
  window.clientPosition = (
    clientRect.left.toInches(window.dpi),
    clientRect.top.toInches(window.dpi),
  )
  window.clientDimensions = (
    (clientRect.right - clientRect.left).toInches(window.dpi),
    (clientRect.bottom - clientRect.top).toInches(window.dpi),
  )

  GetWindowRect(window.hWnd, windowRect.addr)
  window.position = (
    windowRect.left.toInches(window.dpi),
    windowRect.top.toInches(window.dpi),
  )
  window.dimensions = (
    (windowRect.right - windowRect.left).toInches(window.dpi),
    (windowRect.bottom - windowRect.top).toInches(window.dpi),
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

    windowClassCount.dec
    if windowClassCount == 0:
      UnregisterClass(windowClass.lpszClassName, windowClass.hInstance)

  of WM_TIMER:
    ifWindow:
      if window.onTimer != nil:
        window.onTimer()

  of WM_SIZE:
    ifWindow:
      window.updatePositionAndDimensions()
      window.resizeImage()
      if window.onResize != nil:
        window.onResize()
      window.redraw()

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
      # var
      #   paintStruct = PAINTSTRUCT()
      #   hdc = window.hWnd.BeginPaint(paintStruct.addr)
      # FillRect(hdc, paintStruct.rcPaint.addr, cast[HBRUSH](COLOR_WINDOW + 1))
      # window.hWnd.EndPaint(paintStruct.addr)
      window.image.fill(rgba(16, 16, 16, 255))
      if window.onDraw != nil:
        window.onDraw()
      window.drawImage()

  of WM_MOUSEMOVE:
    ifWindow:
      window.input.previousMousePosition[0] = window.input.mousePosition[0]
      window.input.previousMousePosition[1] = window.input.mousePosition[1]
      window.input.mousePosition[0] = GET_X_LPARAM(lParam).toInches(window.dpi)
      window.input.mousePosition[1] = GET_Y_LPARAM(lParam).toInches(window.dpi)
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
                x, y = 0.0,
                width, height = 4.0,
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
    x = x.toPixels(result.dpi).int32,
    y = y.toPixels(result.dpi).int32,
    nWidth = width.toPixels(result.dpi).int32,
    nHeight = height.toPixels(result.dpi).int32,
    hWndParent = parent,
    hMenu = 0,
    hInstance = windowClass.hInstance,
    lpParam = nil,
  )

  result.hWnd = hWnd
  hWndToWindowTable[hWnd] = result

  result.updatePositionAndDimensions()
  result.image = newImage(result.clientWidth.toPixels(result.dpi),
                          result.clientHeight.toPixels(result.dpi))
  result.context = newContext(result.image)

  ShowWindow(hWnd, SW_SHOWDEFAULT)
  UpdateWindow(hWnd)
  InvalidateRect(hWnd, nil, 1)