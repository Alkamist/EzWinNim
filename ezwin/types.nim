type
  Image* = ref object
    width*, height*: int
    pixels*: seq[char]

  GammaRamp* = ref object
    red*, green*, blue*: seq[int]

  VideoMode* = ref object
    width*, height*: int
    redBits*, greenBits*, blueBits*: int
    refreshRate*: int

  Monitor* = ref object
    name*: string
    userPointer*: pointer
    widthmillimeters*, heightmillimeters*: int
    window*: Window
    modes*: seq[VideoMode]
    currentMode*: VideoMode
    originalRamp*: GammaRamp
    currentRamp*: GammaRamp
    # platformState: MonitorState

  Cursor* = ref object
    next*: Cursor
    # platformState: CursorState

  Context* = ref object
    client*: int
    source*: int
    major*, minor*, revision*: int
    forward*, debug*, noError*: bool
    profile*: int
    robustness*: int
    release*: int
    # makeCurrent: proc()
    # swapBuffers: proc()
    # swapInterval: proc()
    # extensionSupported: proc()
    # getProcAddress: proc()
    # destroy: proc()
    # platformState*: ContextState

  Window* = ref object
    next*: Window
    isResizable*: bool
    isDecorated*: bool
    autoIconify*: bool
    isFloating*: bool
    focusOnShow*: bool
    mousePassthrough*: bool
    shouldClose*: bool
    userPointer*: pointer
    doublebuffer*: bool
    videoMode*: VideoMode
    monitor*: Monitor
    cursor*: Cursor
    minWidth*, minHeight*: int
    maxWidth*, maxHeight*: int
    numer*, denom*: int
    stickyKeys*: bool
    stickyMouseButtons*: bool
    lockKeyMods*: bool
    cursorMode*: int
    # mouseButtons: array[GLFW_MOUSE_BUTTON_LAST + 1, char]
    # keys: array[GLFW_KEY_LAST + 1, char]
    virtualCursorPosX*, virtualCursorPosY*: float64
    rawMouseMotion*: bool
    context*: Context
    # pos: proc()
    # size: proc()
    # close: proc()
    # refresh: proc()
    # focus: proc()
    # iconify: proc()
    # maximize: proc()
    # fbsize: proc()
    # scale: proc()
    # mouseButton: proc()
    # cursorPos: proc()
    # cursorEnter: proc()
    # scroll: proc()
    # key: proc()
    # character: proc()
    # charmods: proc()
    # drop: proc()