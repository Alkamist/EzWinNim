import winim/lean
import ../input

func toMouseButton*(msg: UINT, wParam: WPARAM): MouseButton =
  case msg:
  of WM_LBUTTONDOWN, WM_LBUTTONUP, WM_LBUTTONDBLCLK: MouseButton.Left
  of WM_MBUTTONDOWN, WM_MBUTTONUP, WM_MBUTTONDBLCLK: MouseButton.Middle
  of WM_RBUTTONDOWN, WM_RBUTTONUP, WM_RBUTTONDBLCLK: MouseButton.Right
  of WM_XBUTTONDOWN, WM_XBUTTONUP, WM_XBUTTONDBLCLK:
    if HIWORD(wParam) == 1: MouseButton.Extra1
    else: MouseButton.Extra2
  else: MouseButton.Unknown

func toKeyboardKey*(scanCode: int): KeyboardKey =
  case scanCode:
  of 3: KeyboardKey.ControlBreak
  of 8: KeyboardKey.Backspace
  of 9: KeyboardKey.Tab
  of 12: KeyboardKey.Clear
  of 13: KeyboardKey.Enter
  of 16: KeyboardKey.Shift
  of 17: KeyboardKey.Control
  of 18: KeyboardKey.Alt
  of 19: KeyboardKey.Pause
  of 20: KeyboardKey.CapsLock
  of 21: KeyboardKey.IMEKana
  of 23: KeyboardKey.IMEJunja
  of 24: KeyboardKey.IMEFinal
  of 25: KeyboardKey.IMEHanja
  of 27: KeyboardKey.Escape
  of 28: KeyboardKey.IMEConvert
  of 29: KeyboardKey.IMENonConvert
  of 30: KeyboardKey.IMEAccept
  of 31: KeyboardKey.IMEModeChange
  of 32: KeyboardKey.Space
  of 33: KeyboardKey.PageUp
  of 34: KeyboardKey.PageDown
  of 35: KeyboardKey.End
  of 36: KeyboardKey.Home
  of 37: KeyboardKey.LeftArrow
  of 38: KeyboardKey.UpArrow
  of 39: KeyboardKey.RightArrow
  of 40: KeyboardKey.DownArrow
  of 41: KeyboardKey.Select
  of 42: KeyboardKey.Print
  of 43: KeyboardKey.Execute
  of 44: KeyboardKey.PrintScreen
  of 45: KeyboardKey.Insert
  of 46: KeyboardKey.Delete
  of 47: KeyboardKey.Help
  of 48: KeyboardKey.Key0
  of 49: KeyboardKey.Key1
  of 50: KeyboardKey.Key2
  of 51: KeyboardKey.Key3
  of 52: KeyboardKey.Key4
  of 53: KeyboardKey.Key5
  of 54: KeyboardKey.Key6
  of 55: KeyboardKey.Key7
  of 56: KeyboardKey.Key8
  of 57: KeyboardKey.Key9
  of 65: KeyboardKey.A
  of 66: KeyboardKey.B
  of 67: KeyboardKey.C
  of 68: KeyboardKey.D
  of 69: KeyboardKey.E
  of 70: KeyboardKey.F
  of 71: KeyboardKey.G
  of 72: KeyboardKey.H
  of 73: KeyboardKey.I
  of 74: KeyboardKey.J
  of 75: KeyboardKey.K
  of 76: KeyboardKey.L
  of 77: KeyboardKey.M
  of 78: KeyboardKey.N
  of 79: KeyboardKey.O
  of 80: KeyboardKey.P
  of 81: KeyboardKey.Q
  of 82: KeyboardKey.R
  of 83: KeyboardKey.S
  of 84: KeyboardKey.T
  of 85: KeyboardKey.U
  of 86: KeyboardKey.V
  of 87: KeyboardKey.W
  of 88: KeyboardKey.X
  of 89: KeyboardKey.Y
  of 90: KeyboardKey.Z
  of 91: KeyboardKey.LeftSuper
  of 92: KeyboardKey.RightSuper
  of 93: KeyboardKey.Applications
  of 95: KeyboardKey.Sleep
  of 96: KeyboardKey.NumPad0
  of 97: KeyboardKey.NumPad1
  of 98: KeyboardKey.NumPad2
  of 99: KeyboardKey.NumPad3
  of 100: KeyboardKey.NumPad4
  of 101: KeyboardKey.NumPad5
  of 102: KeyboardKey.NumPad6
  of 103: KeyboardKey.NumPad7
  of 104: KeyboardKey.NumPad8
  of 105: KeyboardKey.NumPad9
  of 106: KeyboardKey.NumPadMultiply
  of 107: KeyboardKey.NumPadAdd
  of 108: KeyboardKey.NumPadSeparator
  of 109: KeyboardKey.NumPadSubtract
  of 110: KeyboardKey.NumPadDecimal
  of 111: KeyboardKey.NumPadDivide
  of 112: KeyboardKey.F1
  of 113: KeyboardKey.F2
  of 114: KeyboardKey.F3
  of 115: KeyboardKey.F4
  of 116: KeyboardKey.F5
  of 117: KeyboardKey.F6
  of 118: KeyboardKey.F7
  of 119: KeyboardKey.F8
  of 120: KeyboardKey.F9
  of 121: KeyboardKey.F10
  of 122: KeyboardKey.F11
  of 123: KeyboardKey.F12
  of 124: KeyboardKey.F13
  of 125: KeyboardKey.F14
  of 126: KeyboardKey.F15
  of 127: KeyboardKey.F16
  of 128: KeyboardKey.F17
  of 129: KeyboardKey.F18
  of 130: KeyboardKey.F20
  of 131: KeyboardKey.F21
  of 132: KeyboardKey.F22
  of 133: KeyboardKey.F23
  of 134: KeyboardKey.F24
  of 144: KeyboardKey.NumLock
  of 145: KeyboardKey.ScrollLock
  of 160: KeyboardKey.LeftShift
  of 161: KeyboardKey.RightShift
  of 162: KeyboardKey.LeftControl
  of 163: KeyboardKey.RightControl
  of 164: KeyboardKey.LeftAlt
  of 165: KeyboardKey.RightAlt
  of 166: KeyboardKey.BrowserBack
  of 167: KeyboardKey.BrowserForward
  of 168: KeyboardKey.BrowserRefresh
  of 169: KeyboardKey.BrowserStop
  of 170: KeyboardKey.BrowserSearch
  of 171: KeyboardKey.BrowserFavorites
  of 172: KeyboardKey.BrowserHome
  of 173: KeyboardKey.BrowserMute
  of 174: KeyboardKey.VolumeDown
  of 175: KeyboardKey.VolumeUp
  of 176: KeyboardKey.MediaNextTrack
  of 177: KeyboardKey.MediaPreviousTrack
  of 178: KeyboardKey.MediaStop
  of 179: KeyboardKey.MediaPlay
  of 180: KeyboardKey.StartMail
  of 181: KeyboardKey.MediaSelect
  of 182: KeyboardKey.LaunchApplication1
  of 183: KeyboardKey.LaunchApplication2
  of 186: KeyboardKey.Semicolon
  of 187: KeyboardKey.Equals
  of 188: KeyboardKey.Comma
  of 189: KeyboardKey.Minus
  of 190: KeyboardKey.Period
  of 191: KeyboardKey.Slash
  of 192: KeyboardKey.Grave
  of 219: KeyboardKey.LeftBracket
  of 220: KeyboardKey.BackSlash
  of 221: KeyboardKey.RightBracket
  of 222: KeyboardKey.Apostrophe
  of 229: KeyboardKey.IMEProcess
  else: KeyboardKey.Unknown