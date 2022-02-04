{.experimental: "overloadableEnums".}

import std/options

export options

type
  MouseButton* = enum
    Left,
    Middle,
    Right,
    Extra1,
    Extra2,
    Extra3,
    Extra4,
    Extra5,

  KeyboardKey* = enum
    Unknown
    Space
    Apostrophe
    Comma
    Minus
    Period
    Slash
    Key0
    Key1
    Key2
    Key3
    Key4
    Key5
    Key6
    Key7
    Key8
    Key9
    Semicolon
    Equal
    A
    B
    C
    D
    E
    F
    G
    H
    I
    J
    K
    L
    M
    N
    O
    P
    Q
    R
    S
    T
    U
    V
    W
    X
    Y
    Z
    LeftBracket
    Backslash
    RightBracket
    Grave
    World1
    World2
    Escape
    Enter
    Tab
    Backspace
    Insert
    Delete
    Right
    Left
    Down
    Up
    PageUp
    PageDown
    Home
    End
    CapsLock
    ScrollLock
    NumLock
    PrintScreen
    Pause
    F1
    F2
    F3
    F4
    F5
    F6
    F7
    F8
    F9
    F10
    F11
    F12
    F13
    F14
    F15
    F16
    F17
    F18
    F19
    F20
    F21
    F22
    F23
    F24
    F25
    NumPad0
    NumPad1
    NumPad2
    NumPad3
    NumPad4
    NumPad5
    NumPad6
    NumPad7
    NumPad8
    NumPad9
    NumPadDecimal
    NumPadDivide
    NumPadMultiply
    NumPadSubtract
    NumPadAdd
    NumPadEnter
    NumPadEqual
    LeftShift
    LeftControl
    LeftAlt
    LeftSuper
    RightShift
    RightControl
    RightAlt
    RightSuper
    Menu

  InputState* = ref object
    mousePress*: MouseButton
    mouseRelease*: MouseButton
    mouseX*, mouseY*: float
    mouseXPrevious*, mouseYPrevious*: float
    mouseXChange*, mouseYChange*: float
    mouseWheelX*, mouseWheelY*: float
    keyPress*: KeyboardKey
    keyRelease*: KeyboardKey
    character*: string

func newInputState*(): InputState =
  result = InputState()

func toMouseButton*(buttonCode: int): Option[MouseButton] =
  case buttonCode:
  of 0: some(MouseButton.Left)
  of 1: some(MouseButton.Middle)
  of 2: some(MouseButton.Right)
  of 3: some(MouseButton.Extra1)
  of 4: some(MouseButton.Extra2)
  of 5: some(MouseButton.Extra3)
  of 6: some(MouseButton.Extra4)
  of 7: some(MouseButton.Extra5)
  else: none(MouseButton)

func toKeyboardKey*(keyCode: int): Option[KeyboardKey] =
  case keyCode:
  of -1: some(KeyboardKey.Unknown)
  of 32: some(KeyboardKey.Space)
  of 39: some(KeyboardKey.Apostrophe)
  of 44: some(KeyboardKey.Comma)
  of 45: some(KeyboardKey.Minus)
  of 46: some(KeyboardKey.Period)
  of 47: some(KeyboardKey.Slash)
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
  of 59: some(KeyboardKey.Semicolon)
  of 61: some(KeyboardKey.Equal)
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
  of 91: some(KeyboardKey.LeftBracket)
  of 92: some(KeyboardKey.Backslash)
  of 93: some(KeyboardKey.RightBracket)
  of 96: some(KeyboardKey.Grave)
  of 161: some(KeyboardKey.World1)
  of 162: some(KeyboardKey.World2)
  of 256: some(KeyboardKey.Escape)
  of 257: some(KeyboardKey.Enter)
  of 258: some(KeyboardKey.Tab)
  of 259: some(KeyboardKey.Backspace)
  of 260: some(KeyboardKey.Insert)
  of 261: some(KeyboardKey.Delete)
  of 262: some(KeyboardKey.Right)
  of 263: some(KeyboardKey.Left)
  of 264: some(KeyboardKey.Down)
  of 265: some(KeyboardKey.Up)
  of 266: some(KeyboardKey.PageUp)
  of 267: some(KeyboardKey.PageDown)
  of 268: some(KeyboardKey.Home)
  of 269: some(KeyboardKey.End)
  of 280: some(KeyboardKey.CapsLock)
  of 281: some(KeyboardKey.ScrollLock)
  of 282: some(KeyboardKey.NumLock)
  of 283: some(KeyboardKey.PrintScreen)
  of 284: some(KeyboardKey.Pause)
  of 290: some(KeyboardKey.F1)
  of 291: some(KeyboardKey.F2)
  of 292: some(KeyboardKey.F3)
  of 293: some(KeyboardKey.F4)
  of 294: some(KeyboardKey.F5)
  of 295: some(KeyboardKey.F6)
  of 296: some(KeyboardKey.F7)
  of 297: some(KeyboardKey.F8)
  of 298: some(KeyboardKey.F9)
  of 299: some(KeyboardKey.F10)
  of 300: some(KeyboardKey.F11)
  of 301: some(KeyboardKey.F12)
  of 302: some(KeyboardKey.F13)
  of 303: some(KeyboardKey.F14)
  of 304: some(KeyboardKey.F15)
  of 305: some(KeyboardKey.F16)
  of 306: some(KeyboardKey.F17)
  of 307: some(KeyboardKey.F18)
  of 308: some(KeyboardKey.F19)
  of 309: some(KeyboardKey.F20)
  of 310: some(KeyboardKey.F21)
  of 311: some(KeyboardKey.F22)
  of 312: some(KeyboardKey.F23)
  of 313: some(KeyboardKey.F24)
  of 314: some(KeyboardKey.F25)
  of 320: some(KeyboardKey.NumPad0)
  of 321: some(KeyboardKey.NumPad1)
  of 322: some(KeyboardKey.NumPad2)
  of 323: some(KeyboardKey.NumPad3)
  of 324: some(KeyboardKey.NumPad4)
  of 325: some(KeyboardKey.NumPad5)
  of 326: some(KeyboardKey.NumPad6)
  of 327: some(KeyboardKey.NumPad7)
  of 328: some(KeyboardKey.NumPad8)
  of 329: some(KeyboardKey.NumPad9)
  of 330: some(KeyboardKey.NumPadDecimal)
  of 331: some(KeyboardKey.NumPadDivide)
  of 332: some(KeyboardKey.NumPadMultiply)
  of 333: some(KeyboardKey.NumPadSubtract)
  of 334: some(KeyboardKey.NumPadAdd)
  of 335: some(KeyboardKey.NumPadEnter)
  of 336: some(KeyboardKey.NumPadEqual)
  of 340: some(KeyboardKey.LeftShift)
  of 341: some(KeyboardKey.LeftControl)
  of 342: some(KeyboardKey.LeftAlt)
  of 343: some(KeyboardKey.LeftSuper)
  of 344: some(KeyboardKey.RightShift)
  of 345: some(KeyboardKey.RightControl)
  of 346: some(KeyboardKey.RightAlt)
  of 347: some(KeyboardKey.RightSuper)
  of 348: some(KeyboardKey.Menu)
  else: none(KeyboardKey)