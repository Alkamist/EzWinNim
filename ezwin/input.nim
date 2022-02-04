{.experimental: "overloadableEnums".}

type
  MouseButton* = enum
    Unknown
    Left
    Middle
    Right
    Extra1
    Extra2
    Extra3
    Extra4
    Extra5

  KeyboardKey* = enum
    Unknown
    ControlBreak
    Backspace
    Tab
    Clear
    Enter
    Shift
    Control
    Alt
    Pause
    CapsLock
    IMEKana
    IMEJunja
    IMEFinal
    IMEHanja
    Escape
    IMEConvert
    IMENonConvert
    IMEAccept
    IMEModeChange
    Space
    PageUp
    PageDown
    End
    Home
    LeftArrow
    UpArrow
    RightArrow
    DownArrow
    Select
    Print
    Execute
    PrintScreen
    Insert
    Delete
    Help
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
    LeftSuper
    RightSuper
    Applications
    Sleep
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
    NumPadMultiply
    NumPadAdd
    NumPadSeparator
    NumPadSubtract
    NumPadDecimal
    NumPadDivide
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
    F20
    F21
    F22
    F23
    F24
    NumLock
    ScrollLock
    LeftShift
    RightShift
    LeftControl
    RightControl
    LeftAlt
    RightAlt
    BrowserBack
    BrowserForward
    BrowserRefresh
    BrowserStop
    BrowserSearch
    BrowserFavorites
    BrowserHome
    BrowserMute
    VolumeDown
    VolumeUp
    MediaNextTrack
    MediaPreviousTrack
    MediaStop
    MediaPlay
    StartMail
    MediaSelect
    LaunchApplication1
    LaunchApplication2
    Semicolon
    Equals
    Comma
    Minus
    Period
    Slash
    Grave
    LeftBracket
    BackSlash
    RightBracket
    Apostrophe
    IMEProcess

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