type
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

  KeyboardLogic* = ref object
    onPress*: proc()
    onRelease*: proc()
    onCharacter*: proc()
    press*: KeyboardKey
    release*: KeyboardKey
    character*: string

proc processPress*(keyboard: KeyboardLogic, key: KeyboardKey) =
  keyboard.press = key
  if keyboard.onPress != nil: keyboard.onPress()

proc processRelease*(keyboard: KeyboardLogic, key: KeyboardKey) =
  keyboard.release = key
  if keyboard.onRelease != nil: keyboard.onRelease()

proc processCharacter*(keyboard: KeyboardLogic, character: string) =
  keyboard.character = character
  if keyboard.onCharacter != nil: keyboard.onCharacter()