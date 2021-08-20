import std/options

type
  MouseButton* = enum
    Left,
    Middle,
    Right,
    Side1,
    Side2,

  KeyboardKey* = enum
    ControlBreak,
    Backspace,
    Tab,
    Clear,
    Enter,
    Shift,
    Control,
    Alt,
    Pause,
    CapsLock,
    IMEKana,
    IMEJunja,
    IMEFinal,
    IMEHanja,
    Escape,
    IMEConvert,
    IMENonConvert,
    IMEAccept,
    IMEModeChange,
    Space,
    PageUp,
    PageDown,
    End,
    Home,
    LeftArrow,
    UpArrow,
    RightArrow,
    DownArrow,
    Select,
    Print,
    Execute,
    PrintScreen,
    Insert,
    Delete,
    Help,
    Key0,
    Key1,
    Key2,
    Key3,
    Key4,
    Key5,
    Key6,
    Key7,
    Key8,
    Key9,
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,
    LeftWindows,
    RightWindows,
    Applications,
    Sleep,
    NumPad0,
    NumPad1,
    NumPad2,
    NumPad3,
    NumPad4,
    NumPad5,
    NumPad6,
    NumPad7,
    NumPad8,
    NumPad9,
    NumPadMultiply,
    NumPadAdd,
    NumPadSeparator,
    NumPadSubtract,
    NumPadDecimal,
    NumPadDivide,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    F13,
    F14,
    F15,
    F16,
    F17,
    F18,
    F20,
    F21,
    F22,
    F23,
    F24,
    NumLock,
    ScrollLock,
    LeftShift,
    RightShift,
    LeftControl,
    RightControl,
    LeftAlt,
    RightAlt,
    BrowserBack,
    BrowserForward,
    BrowserRefresh,
    BrowserStop,
    BrowserSearch,
    BrowserFavorites,
    BrowserHome,
    BrowserMute,
    VolumeDown,
    VolumeUp,
    MediaNextTrack,
    MediaPreviousTrack,
    MediaStop,
    MediaPlay,
    StartMail,
    MediaSelect,
    LaunchApplication1,
    LaunchApplication2,
    Semicolon,
    Equals,
    Comma,
    Minus,
    Period,
    Slash,
    Grave,
    LeftBracket,
    BackSlash,
    RightBracket,
    Apostrophe,
    IMEProcess,

  Input* = ref object
    lastKeyPress*: KeyboardKey
    lastKeyRelease*: KeyboardKey
    lastMousePress*: MouseButton
    lastMouseRelease*: MouseButton
    lastMousePressWasDoubleClick*: bool
    lastChar*: string
    mouseWheel*: float
    mouseHWheel*: float
    mousePosition*: (int, int)
    previousMousePosition*: (int, int)
    keyStates*: array[KeyboardKey, bool]
    mouseButtonStates*: array[MouseButton, bool]

proc newInput*(): Input {.inline.} =
  result = Input()

proc mouseDelta*(input: Input): (int, int) {.inline.} =
  result[0] = input.mousePosition[0] - input.previousMousePosition[0]
  result[1] = input.mousePosition[1] - input.previousMousePosition[1]

proc isPressed*(input: Input, key: KeyboardKey): bool {.inline.} =
  input.keyStates[key]

proc isPressed*(input: Input, button: MouseButton): bool {.inline.} =
  input.mouseButtonStates[button]

proc toKeyboardKey*(keyCode: int): Option[KeyboardKey] =
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
  of 91: some(KeyboardKey.LeftWindows)
  of 92: some(KeyboardKey.RightWindows)
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