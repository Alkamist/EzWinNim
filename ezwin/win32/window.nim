{.experimental: "overloadableEnums".}

import std/[tables, exitprocs, options, unicode]
import winim/lean
import ../events

export events

proc windowProc(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.}

type
  Window* = ref object
    eventListeners*: seq[proc(e: WindowEvent)]
    mouseEventListeners*: seq[proc(e: MouseEvent)]
    keyboardEventListeners*: seq[proc(e: KeyboardEvent)]
    hWnd: HWND
    title: string
    shouldClose: bool
    x, y: int
    xPrevious, yPrevious: int
    clientX, clientY: int
    width, height: int
    widthPrevious, heightPrevious: int
    clientWidth, clientHeight: int
    mouseButton: MouseButton
    mouseX, mouseY: int
    mouseXPrevious, mouseYPrevious: int
    mouseClientX, mouseClientY: int
    mouseWheel, mouseHWheel: int
    mouseIsDoubleClick: bool
    keyboardKey: KeyboardKey
    character: string

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

func title*(window: Window): string = window.title
func `title=`*(window: Window, value: string) =
  window.title = value
  SetWindowText(window.hwnd, value)

func shouldClose*(window: Window): bool = window.shouldClose

func pollEvents*(window: Window) =
  var msg: MSG
  while PeekMessage(msg, window.hWnd, 0, 0, PM_REMOVE) != 0:
    TranslateMessage(msg)
    DispatchMessage(msg)

func repaint*(window: Window) =
  InvalidateRect(window.hWnd, nil, 1)

func getWindowEvent(window: Window, kind: WindowEventKind): WindowEvent =
  result.kind = kind
  result.x = window.x
  result.y = window.y
  result.clientX = window.clientX
  result.clientY = window.clientY
  result.xChange = window.x - window.xPrevious
  result.yChange = window.y - window.yPrevious
  result.width = window.width
  result.height = window.height
  result.clientWidth = window.clientWidth
  result.clientHeight = window.clientHeight
  result.widthChange = window.width - window.widthPrevious
  result.heightChange = window.height - window.heightPrevious

func getMouseEvent(window: Window, kind: MouseEventKind): MouseEvent =
  result.kind = kind
  result.button = window.mouseButton
  result.x = window.mouseX
  result.y = window.mouseY
  result.clientX = window.mouseClientX
  result.clientY = window.mouseClientY
  result.xChange = window.mouseX - window.mouseXPrevious
  result.yChange = window.mouseY - window.mouseYPrevious
  result.wheel = window.mouseWheel
  result.hWheel = window.mouseHWheel

func getKeyboardEvent(window: Window, kind: KeyboardEventKind): KeyboardEvent =
  result.kind = kind
  result.key = window.keyboardKey
  result.character = window.character

func updateBounds(window: Window) =
  var windowRect: RECT
  GetWindowRect(window.hWnd, windowRect.addr)

  var clientScreenCoords: POINT
  ClientToScreen(window.hWnd, clientScreenCoords.addr)

  let titleBarHeight = clientScreenCoords.y - windowRect.top

  window.xPrevious = window.x
  window.yPrevious = window.y
  window.widthPrevious = window.width
  window.heightPrevious = window.height

  window.x = clientScreenCoords.x
  window.y = clientScreenCoords.y - titleBarHeight
  window.clientX = 0
  window.clientY = titleBarHeight
  window.width = windowRect.right - windowRect.left
  window.height = windowRect.top - windowRect.bottom
  window.clientWidth = window.width
  window.clientHeight = window.height - titleBarHeight

func toMouseButton(msg: UINT, wParam: WPARAM): Option[MouseButton] =
  case msg:
  of WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK: some(Left)
  of WM_MBUTTONDOWN, WM_MBUTTONUP, WM_MBUTTONDBLCLK: some(Middle)
  of WM_RBUTTONDOWN, WM_RBUTTONUP, WM_RBUTTONDBLCLK: some(Right)
  of WM_XBUTTONDOWN, WM_XBUTTONUP, WM_XBUTTONDBLCLK:
    if HIWORD(wParam) == 1: some(Side1)
    else: some(Side2)
  else: none(MouseButton)

func toKeyboardKey*(keyCode: int): Option[KeyboardKey] =
  case keyCode:
  of 3: some(KeyboardKey.ControlBreak)
  of 8: some(KeyboardKey.Backspace)
  of 9: some(KeyboardKey.Tab)
  of 12: some(KeyboardKey.Clear)
  of 13: some(KeyboardKey.Enter)
  of 16: some(KeyboardKey.Shift)
  of 17: some(KeyboardKey.Control)
  of 18: some(KeyboardKey.Alt)
  of 19: some(KeyboardKey.Pause)
  of 20: some(KeyboardKey.CapsLock)
  of 21: some(KeyboardKey.IMEKana)
  of 23: some(KeyboardKey.IMEJunja)
  of 24: some(KeyboardKey.IMEFinal)
  of 25: some(KeyboardKey.IMEHanja)
  of 27: some(KeyboardKey.Escape)
  of 28: some(KeyboardKey.IMEConvert)
  of 29: some(KeyboardKey.IMENonConvert)
  of 30: some(KeyboardKey.IMEAccept)
  of 31: some(KeyboardKey.IMEModeChange)
  of 32: some(KeyboardKey.Space)
  of 33: some(KeyboardKey.PageUp)
  of 34: some(KeyboardKey.PageDown)
  of 35: some(KeyboardKey.End)
  of 36: some(KeyboardKey.Home)
  of 37: some(KeyboardKey.LeftArrow)
  of 38: some(KeyboardKey.UpArrow)
  of 39: some(KeyboardKey.RightArrow)
  of 40: some(KeyboardKey.DownArrow)
  of 41: some(KeyboardKey.Select)
  of 42: some(KeyboardKey.Print)
  of 43: some(KeyboardKey.Execute)
  of 44: some(KeyboardKey.PrintScreen)
  of 45: some(KeyboardKey.Insert)
  of 46: some(KeyboardKey.Delete)
  of 47: some(KeyboardKey.Help)
  of 48: some(KeyboardKey.Key0)
  of 49: some(KeyboardKey.Key1)
  of 50: some(KeyboardKey.Key2)
  of 51: some(KeyboardKey.Key3)
  of 52: some(KeyboardKey.Key4)
  of 53: some(KeyboardKey.Key5)
  of 54: some(KeyboardKey.Key6)
  of 55: some(KeyboardKey.Key7)
  of 56: some(KeyboardKey.Key8)
  of 57: some(KeyboardKey.Key9)
  of 65: some(KeyboardKey.A)
  of 66: some(KeyboardKey.B)
  of 67: some(KeyboardKey.C)
  of 68: some(KeyboardKey.D)
  of 69: some(KeyboardKey.E)
  of 70: some(KeyboardKey.F)
  of 71: some(KeyboardKey.G)
  of 72: some(KeyboardKey.H)
  of 73: some(KeyboardKey.I)
  of 74: some(KeyboardKey.J)
  of 75: some(KeyboardKey.K)
  of 76: some(KeyboardKey.L)
  of 77: some(KeyboardKey.M)
  of 78: some(KeyboardKey.N)
  of 79: some(KeyboardKey.O)
  of 80: some(KeyboardKey.P)
  of 81: some(KeyboardKey.Q)
  of 82: some(KeyboardKey.R)
  of 83: some(KeyboardKey.S)
  of 84: some(KeyboardKey.T)
  of 85: some(KeyboardKey.U)
  of 86: some(KeyboardKey.V)
  of 87: some(KeyboardKey.W)
  of 88: some(KeyboardKey.X)
  of 89: some(KeyboardKey.Y)
  of 90: some(KeyboardKey.Z)
  of 91: some(KeyboardKey.LeftSuper)
  of 92: some(KeyboardKey.RightSuper)
  of 93: some(KeyboardKey.Applications)
  of 95: some(KeyboardKey.Sleep)
  of 96: some(KeyboardKey.NumPad0)
  of 97: some(KeyboardKey.NumPad1)
  of 98: some(KeyboardKey.NumPad2)
  of 99: some(KeyboardKey.NumPad3)
  of 100: some(KeyboardKey.NumPad4)
  of 101: some(KeyboardKey.NumPad5)
  of 102: some(KeyboardKey.NumPad6)
  of 103: some(KeyboardKey.NumPad7)
  of 104: some(KeyboardKey.NumPad8)
  of 105: some(KeyboardKey.NumPad9)
  of 106: some(KeyboardKey.NumPadMultiply)
  of 107: some(KeyboardKey.NumPadAdd)
  of 108: some(KeyboardKey.NumPadSeparator)
  of 109: some(KeyboardKey.NumPadSubtract)
  of 110: some(KeyboardKey.NumPadDecimal)
  of 111: some(KeyboardKey.NumPadDivide)
  of 112: some(KeyboardKey.F1)
  of 113: some(KeyboardKey.F2)
  of 114: some(KeyboardKey.F3)
  of 115: some(KeyboardKey.F4)
  of 116: some(KeyboardKey.F5)
  of 117: some(KeyboardKey.F6)
  of 118: some(KeyboardKey.F7)
  of 119: some(KeyboardKey.F8)
  of 120: some(KeyboardKey.F9)
  of 121: some(KeyboardKey.F10)
  of 122: some(KeyboardKey.F11)
  of 123: some(KeyboardKey.F12)
  of 124: some(KeyboardKey.F13)
  of 125: some(KeyboardKey.F14)
  of 126: some(KeyboardKey.F15)
  of 127: some(KeyboardKey.F16)
  of 128: some(KeyboardKey.F17)
  of 129: some(KeyboardKey.F18)
  of 130: some(KeyboardKey.F20)
  of 131: some(KeyboardKey.F21)
  of 132: some(KeyboardKey.F22)
  of 133: some(KeyboardKey.F23)
  of 134: some(KeyboardKey.F24)
  of 144: some(KeyboardKey.NumLock)
  of 145: some(KeyboardKey.ScrollLock)
  of 160: some(KeyboardKey.LeftShift)
  of 161: some(KeyboardKey.RightShift)
  of 162: some(KeyboardKey.LeftControl)
  of 163: some(KeyboardKey.RightControl)
  of 164: some(KeyboardKey.LeftAlt)
  of 165: some(KeyboardKey.RightAlt)
  of 166: some(KeyboardKey.BrowserBack)
  of 167: some(KeyboardKey.BrowserForward)
  of 168: some(KeyboardKey.BrowserRefresh)
  of 169: some(KeyboardKey.BrowserStop)
  of 170: some(KeyboardKey.BrowserSearch)
  of 171: some(KeyboardKey.BrowserFavorites)
  of 172: some(KeyboardKey.BrowserHome)
  of 173: some(KeyboardKey.BrowserMute)
  of 174: some(KeyboardKey.VolumeDown)
  of 175: some(KeyboardKey.VolumeUp)
  of 176: some(KeyboardKey.MediaNextTrack)
  of 177: some(KeyboardKey.MediaPreviousTrack)
  of 178: some(KeyboardKey.MediaStop)
  of 179: some(KeyboardKey.MediaPlay)
  of 180: some(KeyboardKey.StartMail)
  of 181: some(KeyboardKey.MediaSelect)
  of 182: some(KeyboardKey.LaunchApplication1)
  of 183: some(KeyboardKey.LaunchApplication2)
  of 186: some(KeyboardKey.Semicolon)
  of 187: some(KeyboardKey.Equals)
  of 188: some(KeyboardKey.Comma)
  of 189: some(KeyboardKey.Minus)
  of 190: some(KeyboardKey.Period)
  of 191: some(KeyboardKey.Slash)
  of 192: some(KeyboardKey.Grave)
  of 219: some(KeyboardKey.LeftBracket)
  of 220: some(KeyboardKey.BackSlash)
  of 221: some(KeyboardKey.RightBracket)
  of 222: some(KeyboardKey.Apostrophe)
  of 229: some(KeyboardKey.IMEProcess)
  else: none(KeyboardKey)

proc sendWindowEvent(window: Window, kind: WindowEventKind) =
  for listener in window.eventListeners:
    listener(window.getWindowEvent(kind))

proc sendMouseEvent(window: Window, kind: MouseEventKind) =
  for listener in window.mouseEventListeners:
    listener(window.getMouseEvent(kind))

proc sendKeyboardEvent(window: Window, kind: KeyboardEventKind) =
  for listener in window.keyboardEventListeners:
    listener(window.getKeyboardEvent(kind))

proc windowProc(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  template ifWindow(code: untyped): untyped =
    if hWndToWindowTable.contains(hWnd):
      var window {.inject.} = hWndToWindowTable[hWnd]
      code

  case msg:
  of WM_INITDIALOG:
    SetFocus(hWnd)

  of WM_CLOSE:
    ifWindow:
      window.sendWindowEvent(Close)
    DestroyWindow(hWnd)

  of WM_DESTROY:
    ifWindow:
      window.shouldClose = true
    hWndToWindowTable.del(hWnd)

  of WM_SIZE:
    ifWindow:
      window.updateBounds()
      window.sendWindowEvent(Resize)

  of WM_MOVE:
    ifWindow:
      window.updateBounds()
      window.sendWindowEvent(Move)

  of WM_SYSCOMMAND:
    ifWindow:
      case wParam:
      of SC_MINIMIZE:
        window.updateBounds()
        window.sendWindowEvent(Minimize)
      of SC_MAXIMIZE:
        window.updateBounds()
        window.sendWindowEvent(Maximize)
      else: discard

  of WM_PAINT:
    ifWindow:
      window.sendWindowEvent(Paint)

  of WM_MOUSEMOVE:
    ifWindow:
      window.mouseXPrevious = window.mouseX
      window.mouseYPrevious = window.mouseY
      window.mouseClientX = GET_X_LPARAM(lParam)
      window.mouseX = window.mouseClientX + window.clientX + window.x
      window.mouseClientY = GET_Y_LPARAM(lParam)
      window.mouseY = window.mouseClientY + window.clientY + window.y
      window.sendMouseEvent(Move)

  of WM_MOUSELEAVE:
    ifWindow:
      window.sendMouseEvent(Exit)

  of WM_MOUSEWHEEL:
    ifWindow:
      window.mouseWheel = (GET_WHEEL_DELTA_WPARAM(wParam).float / WHEEL_DELTA.float).int
      window.sendMouseEvent(Wheel)

  of WM_MOUSEHWHEEL:
    ifWindow:
      window.mouseHWheel = (GET_WHEEL_DELTA_WPARAM(wParam).float / WHEEL_DELTA.float).int
      window.sendMouseEvent(HWheel)

  of WM_LBUTTONDOWN, WM_LBUTTONDBLCLK,
     WM_MBUTTONDOWN, WM_MBUTTONDBLCLK,
     WM_RBUTTONDOWN, WM_RBUTTONDBLCLK,
     WM_XBUTTONDOWN, WM_XBUTTONDBLCLK:
    ifWindow:
      let button = toMouseButton(msg, wParam)
      if button.isSome:
        SetCapture(window.hWnd)
        window.mouseButton = button.get
        window.mouseIsDoubleClick = msg in [WM_LBUTTONDBLCLK,
                                            WM_MBUTTONDBLCLK,
                                            WM_RBUTTONDBLCLK,
                                            WM_XBUTTONDBLCLK]
        window.sendMouseEvent(Press)

  of WM_LBUTTONUP, WM_MBUTTONUP, WM_RBUTTONUP, WM_XBUTTONUP:
    ifWindow:
      let button = toMouseButton(msg, wParam)
      if button.isSome:
        ReleaseCapture()
        window.mouseButton = button.get
        window.sendMouseEvent(Release)

  of WM_KEYDOWN, WM_SYSKEYDOWN:
    ifWindow:
      let key = wParam.int.toKeyboardKey
      if key.isSome:
        window.keyboardKey = key.get
        window.sendKeyboardEvent(Press)

  of WM_KEYUP, WM_SYSKEYUP:
    ifWindow:
      let key = wParam.int.toKeyboardKey
      if key.isSome:
        window.keyboardKey = key.get
        window.sendKeyboardEvent(Release)

  of WM_CHAR, WM_SYSCHAR:
    ifWindow:
      if wParam > 0 and wParam < 0x10000:
        window.character = cast[Rune](wParam).toUTF8
        window.sendKeyboardEvent(Character)

  else: discard

  DefWindowProc(hWnd, msg, wParam, lParam)

proc newWindow*(title: string,
                x, y = 0,
                width = 1024, height = 768,
                parent: HWND = 0): Window =
  result = Window()
  result.title = title

  if not windowClassIsRegistered:
    RegisterClassEx(windowClass)
    windowClassIsRegistered = true
    addExitProc(proc =
      UnregisterClass(windowClass.lpszClassName,
                      windowClass.hInstance)
    )

  result.hWnd = CreateWindow(
    lpClassName = windowClass.lpszClassName,
    lpWindowName = title,
    dwStyle = WS_OVERLAPPEDWINDOW,
    x = int32 x,
    y = int32 y,
    nWidth = int32 width,
    nHeight = int32 height,
    hWndParent = parent,
    hMenu = 0,
    hInstance = windowClass.hInstance,
    lpParam = nil,
  )

  hWndToWindowTable[result.hWnd] = result

  ShowWindow(result.hWnd, SW_SHOWDEFAULT)
  UpdateWindow(result.hWnd)
  InvalidateRect(result.hWnd, nil, 1)

  result.updateBounds()