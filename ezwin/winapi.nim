when defined vcc:
  {.passL: "user32.lib".}
else:
  {.passL: "-luser32".}

{.pragma: windowsType, importc, header: "<windows.h>".}

const
  useUnicode = not defined(winansi)
  HWND_TOP* = nil
  HWND_BOTTOM* = nil
  HWND_TOPMOST* = nil
  HWND_NOTOPMOST* = nil
  CS_CLASSDC* = 0x0040
  WM_KEYDOWN* = 0x0100
  WM_KEYUP* = 0x0101
  WM_SYSKEYDOWN* = 0x0104
  WM_SYSKEYUP* = 0x0105
  WM_MOUSEMOVE* = 0x0200
  WM_LBUTTONDOWN* = 0x0201
  WM_LBUTTONUP* = 0x0202
  WM_LBUTTONDBLCLK* = 0x0203
  WM_MBUTTONDOWN* = 0x0207
  WM_MBUTTONUP* = 0x0208
  WM_MBUTTONDBLCLK* = 0x0209
  WM_RBUTTONDOWN* = 0x0204
  WM_RBUTTONUP* = 0x0205
  WM_RBUTTONDBLCLK* = 0x0206
  WM_XBUTTONDOWN* = 0x020b
  WM_XBUTTONUP* = 0x020c
  WM_XBUTTONDBLCLK* = 0x020d
  WM_CREATE* = 0x0001
  WM_DESTROY* = 0x0002
  WM_INITDIALOG* = 0x0110
  WM_SHOWWINDOW* = 0x0018
  WM_PAINT* = 0x000f
  WM_ERASEBKGND* = 0x0014
  WM_CLOSE* = 0x0010
  WM_SIZE* = 0x0005
  WM_MOVE* = 0x0003
  WM_COMMAND* = 0x0111
  WM_TIMER* =  0x0113
  WM_DPICHANGED* = 0x02E0
  MK_CONTROL* = 0x0008
  MK_LBUTTON* = 0x0001
  MK_MBUTTON* = 0x0010
  MK_RBUTTON* = 0x0002
  MK_SHIFT* = 0x0004
  MK_XBUTTON1* = 0x0020
  MK_XBUTTON2* = 0x0040
  SW_HIDE* = 0
  SW_SHOWNORMAL* = 1
  SW_NORMAL* = 1
  SW_SHOWMINIMIZED* = 2
  SW_SHOWMAXIMIZED* = 3
  SW_MAXIMIZE* = 3
  SW_SHOWNOACTIVATE* = 4
  SW_SHOW* = 5
  SW_MINIMIZE* = 6
  SW_SHOWMINNOACTIVE* = 7
  SW_SHOWNA* = 8
  SW_RESTORE* = 9
  SW_SHOWDEFAULT* = 10
  SW_FORCEMINIMIZE* = 11
  PS_COSMETIC* = 0x00000000
  PS_ENDCAP_ROUND* = 0x00000000
  PS_JOIN_ROUND* = 0x00000000
  PS_SOLID* = 0x00000000
  PS_DASH* = 0x00000001
  PS_DOT* = 0x00000002
  PS_DASHDOT* = 0x00000003
  PS_DASHDOTDOT* = 0x00000004
  PS_NULL* = 0x00000005
  PS_INSIDEFRAME* = 0x00000006
  PS_USERSTYLE* = 0x00000007
  PS_ALTERNATE* = 0x00000008
  PS_ENDCAP_SQUARE* = 0x00000100
  PS_ENDCAP_FLAT* = 0x00000200
  PS_JOIN_BEVEL* = 0x00001000
  PS_JOIN_MITER* = 0x00002000
  PS_GEOMETRIC* = 0x00010000
  SWP_ASYNCWINDOWPOS* = 0x4000
  SWP_DEFERERASE* = 0x2000
  SWP_DRAWFRAME* = 0x0020
  SWP_FRAMECHANGED* = 0x0020
  SWP_HIDEWINDOW* = 0x0080
  SWP_NOACTIVATE* = 0x0010
  SWP_NOCOPYBITS* = 0x0100
  SWP_NOMOVE* = 0x0002
  SWP_NOOWNERZORDER* = 0x0200
  SWP_NOREDRAW* = 0x0008
  SWP_NOREPOSITION* = 0x0200
  SWP_NOSENDCHANGING* = 0x0400
  SWP_NOSIZE* = 0x0001
  SWP_NOZORDER* = 0x0004
  SWP_SHOWWINDOW* = 0x0040
  SRCCOPY* = 0x00CC0020
  WS_OVERLAPPED* = 0x00000000
  WS_POPUP* = 0x80000000
  WS_CHILD* = 0x40000000
  WS_MINIMIZE* = 0x20000000
  WS_VISIBLE* = 0x10000000
  WS_DISABLED* = 0x08000000
  WS_CLIPSIBLINGS* = 0x04000000
  WS_CLIPCHILDREN* = 0x02000000
  WS_MAXIMIZE* = 0x01000000
  WS_CAPTION* = 0x00C00000
  WS_BORDER* = 0x00800000
  WS_DLGFRAME* = 0x00400000
  WS_VSCROLL* = 0x00200000
  WS_HSCROLL* = 0x00100000
  WS_SYSMENU* = 0x00080000
  WS_THICKFRAME* = 0x00040000
  WS_GROUP* = 0x00020000
  WS_TABSTOP* = 0x00010000
  WS_MINIMIZEBOX* = 0x00020000
  WS_MAXIMIZEBOX* = 0x00010000
  WS_TILED* = WS_OVERLAPPED
  WS_ICONIC* = WS_MINIMIZE
  WS_SIZEBOX* = WS_THICKFRAME
  WS_OVERLAPPEDWINDOW* = WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_THICKFRAME or WS_MINIMIZEBOX or WS_MAXIMIZEBOX
  WS_TILEDWINDOW* = WS_OVERLAPPEDWINDOW
  WS_POPUPWINDOW* = WS_POPUP or WS_BORDER or WS_SYSMENU
  WS_CHILDWINDOW* = WS_CHILD
  WS_EX_DLGMODALFRAME* = 0x00000001
  WS_EX_NOPARENTNOTIFY* = 0x00000004
  WS_EX_TOPMOST* = 0x00000008
  WS_EX_ACCEPTFILES* = 0x00000010
  WS_EX_TRANSPARENT* = 0x00000020
  WS_EX_MDICHILD* = 0x00000040
  WS_EX_TOOLWINDOW* = 0x00000080
  WS_EX_WINDOWEDGE* = 0x00000100
  WS_EX_CLIENTEDGE* = 0x00000200
  WS_EX_CONTEXTHELP* = 0x00000400
  WS_EX_RIGHT* = 0x00001000
  WS_EX_LEFT* = 0x00000000
  WS_EX_RTLREADING* = 0x00002000
  WS_EX_LTRREADING* = 0x00000000
  WS_EX_LEFTSCROLLBAR* = 0x00004000
  WS_EX_RIGHTSCROLLBAR* = 0x00000000
  WS_EX_CONTROLPARENT* = 0x00010000
  WS_EX_STATICEDGE* = 0x00020000
  WS_EX_APPWINDOW* = 0x00040000
  WS_EX_OVERLAPPEDWINDOW* = WS_EX_WINDOWEDGE or WS_EX_CLIENTEDGE
  WS_EX_PALETTEWINDOW* = WS_EX_WINDOWEDGE or WS_EX_TOOLWINDOW or WS_EX_TOPMOST
  WS_EX_LAYERED* = 0x00080000
  WS_EX_NOINHERITLAYOUT* = 0x00100000
  WS_EX_NOREDIRECTIONBITMAP* = 0x00200000
  WS_EX_LAYOUTRTL* = 0x00400000
  WS_EX_COMPOSITED* = 0x02000000
  WS_EX_NOACTIVATE* = 0x08000000
  PM_NOREMOVE* = 0x0000
  PM_REMOVE* = 0x0001
  PM_NOYIELD* = 0x0002

when defined(cpu64):
  type
    INT_PTR* {.windowsType.} = int64
    UINT_PTR* {.windowsType.} = int64
    LONG_PTR* {.windowsType.} = int64
    ULONG_PTR* {.windowsType.} = int64
else:
  type
    INT_PTR* {.windowsType.} = cint
    UINT_PTR* {.windowsType.} = cint
    LONG_PTR* {.windowsType.} = cint
    ULONG_PTR* {.windowsType.} = cint

type
  VOID* {.windowsType.} = void
  PVOID* {.windowsType.} = pointer
  LPVOID* {.windowsType.} = pointer
  BOOL* {.windowsType.} = cint
  WINBOOL* {.windowsType.} = cint
  CHAR* {.windowsType.} = cchar
  WORD* {.windowsType.} = cushort
  ATOM* {.windowsType.} = WORD
  INT* {.windowsType.} = cint
  LONG* {.windowsType.} = clong
  BYTE* {.windowsType.} = cuchar
  UCHAR* {.windowsType.} = cuchar
  USHORT* {.windowsType.} = cushort
  WCHAR* {.windowsType.} = Utf16Char
  UINT* {.windowsType.} = cuint
  ULONG* {.windowsType.} = culong
  DWORD* {.windowsType.} = culong
  FLOAT* {.windowsType.} = cfloat
  WPARAM* {.windowsType.} = UINT_PTR
  LPARAM* {.windowsType.} = LONG_PTR
  LRESULT* {.windowsType.} = LONG_PTR
  LPCSTR* {.windowsType.} = cstring
  LPCWSTR* {.windowsType.} = WideCString
  HANDLE* {.windowsType.} = PVOID
  HINSTANCE* {.windowsType.} = HANDLE
  HMODULE* {.windowsType.} = HINSTANCE
  HWND* {.windowsType.} = HANDLE
  HMENU* {.windowsType.} = HANDLE
  HDC* {.windowsType.} = HANDLE
  HPEN* {.windowsType.} = HANDLE
  HBRUSH* {.windowsType.} = HANDLE
  HFONT* {.windowsType.} = HANDLE
  HGDIOBJ* {.windowsType.} = HANDLE
  HICON* {.windowsType.}  = HANDLE
  HCURSOR* {.windowsType.}  = HANDLE

  POINT* {.windowsType.} = object
    x*: LONG
    y*: LONG

  RECT* {.windowsType.} = object
    left*: LONG
    top*: LONG
    right*: LONG
    bottom*: LONG
  LPRECT* {.windowsType.} = ptr RECT

  MSG* {.windowsType.} = object
    hwnd*: HWND
    message*: UINT
    wParam*: WPARAM
    lParam*: LPARAM
    time*: DWORD
    pt*: POINT
  PMSG* {.windowsType.} = ptr MSG
  LPMSG* {.windowsType.} = ptr MSG

  GUID* {.windowsType.} = object
    Data1*: culong
    Data2*: cushort
    Data3*: cushort
    Data4*: array[8, cchar]

  ACCEL* {.windowsType.} = object
    fVirt*: BYTE
    key*: WORD
    cmd*: WORD

  PAINTSTRUCT* {.windowsType.} = object
    hdc*: HDC
    fErase*: BOOL
    rcPaint*: RECT
    fRestore*: BOOL
    fIncUpdate*: BOOL
    rgbReserved*: array[32, BYTE]
  LPPAINTSTRUCT* {.windowsType.} = ptr PAINTSTRUCT

  WNDPROC* {.windowsType.} = proc(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.}
  DLGPROC* {.windowsType.} = proc(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): INT_PTR {.stdcall.}
  TIMERPROC* {.windowsType.} = proc(P1: HWND, P2: UINT, P3: UINT_PTR, P4: DWORD): VOID {.stdcall.}

  WNDCLASSEXA* {.windowsType.} = object
    cbSize*: UINT
    style*: UINT
    lpfnWndProc*: WNDPROC
    cbClsExtra*: cint
    cbWndExtra*: cint
    hInstance*: HINSTANCE
    hIcon*: HICON
    hCursor*: HCURSOR
    hbrBackground*: HBRUSH
    lpszMenuName*: LPCSTR
    lpszClassName*: LPCSTR
    hIconSm*: HICON

  WNDCLASSEXW* {.windowsType.} = object
    cbSize*: UINT
    style*: UINT
    lpfnWndProc*: WNDPROC
    cbClsExtra*: cint
    cbWndExtra*: cint
    hInstance*: HINSTANCE
    hIcon*: HICON
    hCursor*: HCURSOR
    hbrBackground*: HBRUSH
    lpszMenuName*: LPCWSTR
    lpszClassName*: LPCWSTR
    hIconSm*: HICON

converter toLPCSTR*(str: string): LPCSTR = str
converter toLPCWSTR*(str: string): LPCWSTR = newWideCString(str)

{.push discardable, stdcall, importc, header: "<windowsx.h>".}

proc GET_X_LPARAM*(lParam: LPARAM): int
proc GET_Y_LPARAM*(lParam: LPARAM): int

{.pop.}

{.push discardable, stdcall, importc, header: "<windows.h>".}

proc LOWORD*(value: WPARAM): int
proc HIWORD*(value: WPARAM): int

proc GetClientRect*(hWnd: HWND, lpRect: LPRECT): BOOL
proc GetWindowRect*(hWnd: HWND, lpRect: LPRECT): BOOL
proc ShowWindow*(hWnd: HWND, nCmdShow: cint): BOOL
proc UpdateWindow*(hWnd: HWND): BOOL
proc DestroyWindow*(hWnd: HWND): BOOL
proc SetFocus*(hWnd: HWND): HWND
proc SetCapture*(hWnd: HWND): HWND
proc ReleaseCapture*(): BOOL
proc GetParent*(hWnd: HWND): HWND
proc SetWindowPos*(hWnd: HWND, hWndInsertAfter: HWND, X, Y, cx, cy: int, uFlag: UINT): BOOL
proc TranslateMessage*(lpMsg: ptr MSG): LRESULT
proc DispatchMessage*(lpMsg: ptr MSG): LRESULT
proc SetTimer*(hWnd: HWND, nIDEvent: UINT_PTR, uElapse: UINT, lpTimerFunc: TIMERPROC): UINT_PTR
proc KillTimer*(hWnd: HWND, uIDEvent: UINT_PTR): BOOL

proc GetModuleHandleA*(lpModuleName: LPCSTR): HMODULE
proc GetModuleHandleW*(lpModuleName: LPCWSTR): HMODULE
proc RegisterClassExA*(P1: ptr WNDCLASSEXA): ATOM
proc RegisterClassExW*(P1: ptr WNDCLASSEXW): ATOM
proc UnregisterClassA*(lpClassName: LPCSTR, hInstance: HINSTANCE): BOOL
proc UnregisterClassW*(lpClassName: LPCWSTR, hInstance: HINSTANCE): BOOL
proc CreateWindowA*(lpClassName, lpWindowName: LPCSTR, dwStyle: DWORD, x, y, nWidth, nHeight: cint, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPVOID): HWND
proc CreateWindowW*(lpClassName, lpWindowName: LPCWSTR, dwStyle: DWORD, x, y, nWidth, nHeight: cint, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPVOID): HWND
proc DefWindowProcA*(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT
proc DefWindowProcW*(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT
proc SetWindowTextA*(hWnd: HWND, lpString: LPCSTR): BOOL
proc SetWindowTextW*(hWnd: HWND, lpString: LPCWSTR): BOOL
proc PeekMessageA*(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin, wMsgFilterMax, wRemoveMsg: UINT): BOOL
proc PeekMessageW*(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin, wMsgFilterMax, wRemoveMsg: UINT): BOOL

{.pop.}

when useUnicode:
  type
    WNDCLASSEX* = WNDCLASSEXW

  {.push discardable.}

  proc GetModuleHandle*(lpModuleName: LPCWSTR): HMODULE {.stdcall, importc: "GetModuleHandleW", header: "<windows.h>".}
  proc RegisterClassEx*(P1: ptr WNDCLASSEXW): ATOM {.stdcall, importc: "RegisterClassExW", header: "<windows.h>".}
  proc UnregisterClass*(lpClassName: LPCWSTR, hInstance: HINSTANCE): BOOL {.stdcall, importc: "UnregisterClassW", header: "<windows.h>".}
  proc CreateWindow*(lpClassName, lpWindowName: LPCWSTR, dwStyle: DWORD, x, y, nWidth, nHeight: cint, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPVOID): HWND {.stdcall, importc: "CreateWindowW", header: "<windows.h>".}
  proc DefWindowProc*(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall, importc: "DefWindowProcW", header: "<windows.h>".}
  proc SetWindowText*(hWnd: HWND, lpString: LPCWSTR): BOOL {.stdcall, importc: "SetWindowTextW", header: "<windows.h>".}
  proc PeekMessage*(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin, wMsgFilterMax, wRemoveMsg: UINT): BOOL {.stdcall, importc: "PeekMessageW", header: "<windows.h>".}

  {.pop.}

else:
  type
    WNDCLASSEX* = WNDCLASSEXA

  {.push discardable.}

  proc GetModuleHandle*(lpModuleName: LPCSTR): HMODULE {.stdcall, importc: "GetModuleHandleA", header: "<windows.h>".}
  proc RegisterClassEx*(P1: ptr WNDCLASSEXA): ATOM {.stdcall, importc: "RegisterClassExA", header: "<windows.h>".}
  proc UnregisterClass*(lpClassName: LPCSTR, hInstance: HINSTANCE): BOOL {.stdcall, importc: "UnregisterClassA", header: "<windows.h>".}
  proc CreateWindow*(lpClassName, lpWindowName: LPCSTR, dwStyle: DWORD, x, y, nWidth, nHeight: cint, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPVOID): HWND {.stdcall, importc: "CreateWindowA", header: "<windows.h>".}
  proc DefWindowProc*(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall, importc: "DefWindowProcA", header: "<windows.h>".}
  proc SetWindowText*(hWnd: HWND, lpString: LPCSTR): BOOL {.stdcall, importc: "SetWindowTextA", header: "<windows.h>".}
  proc PeekMessage*(lpMsg: LPMSG, hWnd: HWND, wMsgFilterMin, wMsgFilterMax, wRemoveMsg: UINT): BOOL {.stdcall, importc: "PeekMessageA", header: "<windows.h>".}

  {.pop.}