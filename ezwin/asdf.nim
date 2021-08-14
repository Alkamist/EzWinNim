import
  winim/lean,
  types

proc RtlVerifyVersionInfo(VersionInfo: PRTL_OSVERSIONINFOEXW, TypeMask: ULONG, ConditionMask: ULONGLONG): NTSTATUS {.stdcall, importc, dynlib: "ntdll".}
proc AdjustWindowRectExForDpi(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD, dp: UINT): BOOL {.stdcall, importc, dynlib: "user32".}

proc isWindows10BuildOrGreater(build: DWORD): bool =
  var osvi = OSVERSIONINFOEXW(
    dwOSVersionInfoSize: sizeof(OSVERSIONINFOEXW).DWORD,
    dwMajorVersion: 10,
    dwMinorVersion: 0,
    dwBuildNumber: build,
  )
  let mask: DWORD = VER_MAJORVERSION or VER_MINORVERSION or VER_BUILDNUMBER

  var cond: ULONGLONG = VerSetConditionMask(0, VER_MAJORVERSION, VER_GREATER_EQUAL)
  cond = VerSetConditionMask(cond, VER_MINORVERSION, VER_GREATER_EQUAL)
  cond = VerSetConditionMask(cond, VER_BUILDNUMBER, VER_GREATER_EQUAL)

  # HACK: Use RtlVerifyVersionInfo instead of VerifyVersionInfoW as the
  #       latter lies unless the user knew to embed a non-default manifest
  #       announcing support for Windows 10 via supportedOS GUID

  RtlVerifyVersionInfo(osvi.addr, mask, cond) == 0

template isWindows10AnniversaryUpdateOrGreater: untyped =
  isWindows10BuildOrGreater(14393)
template isWindows10CreatorsUpdateOrGreater: untyped =
  isWindows10BuildOrGreater(15063)

proc getWindowStyle(window: Window): DWORD =
  result = WS_CLIPSIBLINGS or WS_CLIPCHILDREN
  if window.monitor != nil:
    result = result or WS_POPUP
  else:
    result = result or (WS_SYSMENU or WS_MINIMIZEBOX)
    if window.isDecorated:
      result = result or WS_CAPTION
      if window.isResizable:
        result = result or (WS_MAXIMIZEBOX or WS_THICKFRAME)
    else:
      result = result or WS_POPUP

proc getWindowExStyle(window: Window): DWORD =
  result = WS_EX_APPWINDOW
  if window.monitor != nil or window.isFloating:
    result = result or WS_EX_TOPMOST

proc chooseImage(images: openArray[Image], width, height: int): Image =
  ## Returns the image whose area most closely matches the desired one.
  var leastDiff = int.high
  for image in images:
    var currDiff = abs(image.width * image.height - width * height)
    if currDiff < leastDiff:
      result = image
      leastDiff = currDiff

# proc createIcon*(image: ptr GLFWimage, xhot: cint, yhot: cint, icon: bool): HICON =
#   ## Creates an RGBA icon or cursor
#   var i: cint
#   var dc: HDC
#   var handle: HICON
#   var
#     color: HBITMAP
#     mask: HBITMAP
#   var bi: BITMAPV5HEADER
#   var ii: ICONINFO
#   var target: ptr cuchar = nil
#   var source: ptr cuchar = image.pixels
#   ZeroMemory(addr(bi), sizeof((bi)))
#   bi.bV5Size = sizeof((bi))
#   bi.bV5Width = image.width
#   bi.bV5Height = -image.height
#   bi.bV5Planes = 1
#   bi.bV5BitCount = 32
#   bi.bV5Compression = BI_BITFIELDS
#   bi.bV5RedMask = 0x00ff0000
#   bi.bV5GreenMask = 0x0000ff00
#   bi.bV5BlueMask = 0x000000ff
#   bi.bV5AlphaMask = 0xff000000
#   dc = GetDC(nil)
#   color = CreateDIBSection(dc, cast[ptr BITMAPINFO](addr(bi)), DIB_RGB_COLORS,
#                          cast[ptr pointer](addr(target)), nil, cast[DWORD](0))
#   ReleaseDC(nil, dc)
#   if not color:
#     _glfwInputErrorWin32(GLFW_PLATFORM_ERROR,
#                          "Win32: Failed to create RGBA bitmap")
#     return nil
#   mask = CreateBitmap(image.width, image.height, 1, 1, nil)
#   if not mask:
#     _glfwInputErrorWin32(GLFW_PLATFORM_ERROR,
#                          "Win32: Failed to create mask bitmap")
#     DeleteObject(color)
#     return nil
#   i = 0
#   while i < image.width * image.height:
#     target[0] = source[2]
#     target[1] = source[1]
#     target[2] = source[0]
#     target[3] = source[3]
#     inc(target, 4)
#     inc(source, 4)
#     inc(i)
#   ZeroMemory(addr(ii), sizeof((ii)))
#   ii.fIcon = icon
#   ii.xHotspot = xhot
#   ii.yHotspot = yhot
#   ii.hbmMask = mask
#   ii.hbmColor = color
#   handle = CreateIconIndirect(addr(ii))
#   DeleteObject(color)
#   DeleteObject(mask)
#   if not handle:
#     if icon:
#       _glfwInputErrorWin32(GLFW_PLATFORM_ERROR, "Win32: Failed to create icon")
#     else:
#       _glfwInputErrorWin32(GLFW_PLATFORM_ERROR, "Win32: Failed to create cursor")
#   return handle

proc getFullWindowSize*(style, exStyle: DWORD,
                        contentWidth, contentHeight: int,
                        dpi: UINT): (int, int) =
  ## Translate content area size to full window size according to styles and DPI
  var rect = RECT(
    left: 0, top: 0,
    right: contentWidth.LONG,
    bottom: contentHeight.LONG,
  )

  if isWindows10AnniversaryUpdateOrGreater():
    AdjustWindowRectExForDpi(rect.addr, style, FALSE, exStyle, dpi)
  else:
    AdjustWindowRectEx(rect.addr, style, FALSE, exStyle)

  ((rect.right - rect.left).int, (rect.bottom - rect.top).int)

proc applyAspectRatio*(window: Window, edge: int, area: ptr RECT) =
  ## Enforce the content area aspect ratio based on which edge is being dragged
  var
    xoff: int
    yoff: int
    dpi: UINT = USER_DEFAULT_SCREEN_DPI
    ratio = window.numer.float / window.denom.float
  if isWindows10AnniversaryUpdateOrGreater():
    dpi = GetDpiForWindow(window.win32.handle)
  getFullWindowSize(getWindowStyle(window), getWindowExStyle(window), 0, 0,
                    addr(xoff), addr(yoff), dpi)
  if edge == WMSZ_LEFT or edge == WMSZ_BOTTOMLEFT or edge == WMSZ_RIGHT or
      edge == WMSZ_BOTTOMRIGHT:
    area.bottom = area.top + yoff + (int)((area.right - area.left - xoff) div ratio)
  elif edge == WMSZ_TOPLEFT or edge == WMSZ_TOPRIGHT:
    area.top = area.bottom - yoff - (int)((area.right - area.left - xoff) div ratio)
  elif edge == WMSZ_TOP or edge == WMSZ_BOTTOM:
    area.right = area.left + xoff + (int)((area.bottom - area.top - yoff) * ratio)






##  Updates the cursor image according to its cursor mode
##

proc updateCursorImage*(window: Window) =
  if window.cursorMode == GLFW_CURSOR_NORMAL:
    if window.cursor:
      SetCursor(window.cursor.win32.handle)
    else:
      SetCursor(LoadCursorW(nil, IDC_ARROW))
  else:
    SetCursor(nil)

##  Updates the cursor clip rect
##

proc updateClipRect*(window: Window) =
  if window:
    var clipRect: RECT
    GetClientRect(window.win32.handle, addr(clipRect))
    ClientToScreen(window.win32.handle, cast[ptr POINT](addr(clipRect.left)))
    ClientToScreen(window.win32.handle, cast[ptr POINT](addr(clipRect.right)))
    ClipCursor(addr(clipRect))
  else:
    ClipCursor(nil)

##  Enables WM_INPUT messages for the mouse for the specified window
##

proc enableRawMouseMotion*(window: Window) =
  var rid: RAWINPUTDEVICE = [0x01, 0x02, 0, window.win32.handle]
  if not RegisterRawInputDevices(addr(rid), 1, sizeof((rid))):
    _glfwInputErrorWin32(GLFW_PLATFORM_ERROR,
                         "Win32: Failed to register raw input device")

##  Disables WM_INPUT messages for the mouse
##

proc disableRawMouseMotion*(window: Window) =
  var rid: RAWINPUTDEVICE = [0x01, 0x02, RIDEV_REMOVE, nil]
  if not RegisterRawInputDevices(addr(rid), 1, sizeof((rid))):
    _glfwInputErrorWin32(GLFW_PLATFORM_ERROR,
                         "Win32: Failed to remove raw input device")

##  Apply disabled cursor mode to a focused window
##

proc disableCursor*(window: Window) =
  _glfw.win32.disabledCursorWindow = window
  _glfwPlatformGetCursorPos(window, addr(_glfw.win32.restoreCursorPosX),
                            addr(_glfw.win32.restoreCursorPosY))
  updateCursorImage(window)
  _glfwCenterCursorInContentArea(window)
  updateClipRect(window)
  if window.rawMouseMotion:
    enableRawMouseMotion(window)

##  Exit disabled cursor mode for the specified window
##

proc enableCursor*(window: Window) =
  if window.rawMouseMotion:
    disableRawMouseMotion(window)
  _glfw.win32.disabledCursorWindow = nil
  updateClipRect(nil)
  _glfwPlatformSetCursorPos(window, _glfw.win32.restoreCursorPosX,
                            _glfw.win32.restoreCursorPosY)
  updateCursorImage(window)

##  Returns whether the cursor is in the content area of the specified window
##

proc cursorInContentArea*(window: Window): bool =
  var area: RECT
  var pos: POINT
  if not GetCursorPos(addr(pos)):
    return GLFW_FALSE
  if WindowFromPoint(pos) != window.win32.handle:
    return GLFW_FALSE
  GetClientRect(window.win32.handle, addr(area))
  ClientToScreen(window.win32.handle, cast[ptr POINT](addr(area.left)))
  ClientToScreen(window.win32.handle, cast[ptr POINT](addr(area.right)))
  return PtInRect(addr(area), pos)

proc updateWindowStyles*(window: Window) =
  ## Update native window styles to match attributes
  var rect: RECT
  var style: DWORD = GetWindowLongW(window.win32.handle, GWL_STYLE)
  style = style and not (WS_OVERLAPPEDWINDOW or WS_POPUP)
  style = style or getWindowStyle(window)
  GetClientRect(window.win32.handle, rect.addr)
  if isWindows10AnniversaryUpdateOrGreater():
    AdjustWindowRectExForDpi(rect.addr, style, FALSE, getWindowExStyle(window),
                             GetDpiForWindow(window.win32.handle))
  else:
    AdjustWindowRectEx(rect.addr, style, FALSE, getWindowExStyle(window))

  ClientToScreen(window.win32.handle, cast[ptr POINT]((rect.left.addr))
  ClientToScreen(window.win32.handle, cast[ptr POINT](rect.right.addr))

  SetWindowLongW(window.win32.handle, GWL_STYLE, style)
  SetWindowPos(window.win32.handle, HWND_TOP, rect.left, rect.top,
               rect.right - rect.left, rect.bottom - rect.top,
               SWP_FRAMECHANGED or SWP_NOACTIVATE or SWP_NOZORDER)

##  Update window framebuffer transparency
##

proc updateFramebufferTransparency*(window: Window) =
  var
    composition: BOOL
    opaque: BOOL
  var color: DWORD
  if not IsWindowsVistaOrGreater():
    return
  if FAILED(DwmIsCompositionEnabled(addr(composition))) or not composition:
    return
  if IsWindows8OrGreater() or
      (SUCCEEDED(DwmGetColorizationColor(addr(color), addr(opaque))) and
      not opaque):
    var region: HRGN = CreateRectRgn(0, 0, -1, -1)
    var bb: DWM_BLURBEHIND = [0]
    bb.dwFlags = DWM_BB_ENABLE or DWM_BB_BLURREGION
    bb.hRgnBlur = region
    bb.fEnable = TRUE
    DwmEnableBlurBehindWindow(window.win32.handle, addr(bb))
    DeleteObject(region)
  else:
    ##  HACK: Disable framebuffer transparency on Windows 7 when the
    ##        colorization color is opaque, because otherwise the window
    ##        contents is blended additively with the previous frame instead
    ##        of replacing it
    var bb: DWM_BLURBEHIND = [0]
    bb.dwFlags = DWM_BB_ENABLE
    DwmEnableBlurBehindWindow(window.win32.handle, addr(bb))

##  Retrieves and translates modifier keys
##

proc getKeyMods*(): cint =
  var mods: cint = 0
  if GetKeyState(VK_SHIFT) and 0x8000:
    mods = mods or GLFW_MOD_SHIFT
  if GetKeyState(VK_CONTROL) and 0x8000:
    mods = mods or GLFW_MOD_CONTROL
  if GetKeyState(VK_MENU) and 0x8000:
    mods = mods or GLFW_MOD_ALT
  if (GetKeyState(VK_LWIN) or GetKeyState(VK_RWIN)) and 0x8000:
    mods = mods or GLFW_MOD_SUPER
  if GetKeyState(VK_CAPITAL) and 1:
    mods = mods or GLFW_MOD_CAPS_LOCK
  if GetKeyState(VK_NUMLOCK) and 1:
    mods = mods or GLFW_MOD_NUM_LOCK
  return mods

proc fitToMonitor*(window: Window) =
  var mi: MONITORINFO = [sizeof((mi))]
  GetMonitorInfo(window.monitor.win32.handle, addr(mi))
  SetWindowPos(window.win32.handle, HWND_TOPMOST, mi.rcMonitor.left,
               mi.rcMonitor.top, mi.rcMonitor.right - mi.rcMonitor.left,
               mi.rcMonitor.bottom - mi.rcMonitor.top,
               SWP_NOZORDER or SWP_NOACTIVATE or SWP_NOCOPYBITS)

##  Make the specified window and its video mode active on its monitor
##

proc acquireMonitor*(window: Window) =
  if not _glfw.win32.acquiredMonitorCount:
    SetThreadExecutionState(ES_CONTINUOUS or ES_DISPLAY_REQUIRED)
    ##  HACK: When mouse trails are enabled the cursor becomes invisible when
    ##        the OpenGL ICD switches to page flipping
    SystemParametersInfo(SPI_GETMOUSETRAILS, 0, addr(_glfw.win32.mouseTrailSize), 0)
    SystemParametersInfo(SPI_SETMOUSETRAILS, 0, 0, 0)
  if not window.monitor.window:
    inc(_glfw.win32.acquiredMonitorCount)
  _glfwSetVideoModeWin32(window.monitor, addr(window.videoMode))
  _glfwInputMonitorWindow(window.monitor, window)

##  Remove the window and restore the original video mode
##

proc releaseMonitor*(window: Window) =
  if window.monitor.window != window:
    return
  dec(_glfw.win32.acquiredMonitorCount)
  if not _glfw.win32.acquiredMonitorCount:
    SetThreadExecutionState(ES_CONTINUOUS)
    ##  HACK: Restore mouse trail length saved in acquireMonitor
    SystemParametersInfo(SPI_SETMOUSETRAILS, _glfw.win32.mouseTrailSize, 0, 0)
  _glfwInputMonitorWindow(window.monitor, nil)
  _glfwRestoreVideoModeWin32(window.monitor)

##  Window callback function (handles window messages)
##

proc windowProc*(hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT =
  var window: Window = GetPropW(hWnd, L, "GLFW")
  if not window:
    ##  This is the message handling for the hidden helper window
    ##  and for a regular window during its initial creation
    case uMsg
    of WM_NCCREATE:
      if isWindows10AnniversaryUpdateOrGreater():
        var cs: ptr CREATESTRUCTW = cast[ptr CREATESTRUCTW](lParam)
        var wndconfig: ptr _GLFWwndconfig = cs.lpCreateParams
        ##  On per-monitor DPI aware V1 systems, only enable
        ##  non-client scaling for windows that scale the client area
        ##  We need WM_GETDPISCALEDSIZE from V2 to keep the client
        ##  area static when the non-client area is scaled
        if wndconfig and wndconfig.scaleToMonitor:
          EnableNonClientDpiScaling(hWnd)
      break
    of WM_DISPLAYCHANGE:
      _glfwPollMonitorsWin32()
    of WM_DEVICECHANGE:
      if not _glfw.joysticksInitialized:
        break
      if wParam == DBT_DEVICEARRIVAL:
        var dbh: ptr DEV_BROADCAST_HDR = cast[ptr DEV_BROADCAST_HDR](lParam)
        if dbh and dbh.dbch_devicetype == DBT_DEVTYP_DEVICEINTERFACE:
          _glfwDetectJoystickConnectionWin32()
      elif wParam == DBT_DEVICEREMOVECOMPLETE:
        var dbh: ptr DEV_BROADCAST_HDR = cast[ptr DEV_BROADCAST_HDR](lParam)
        if dbh and dbh.dbch_devicetype == DBT_DEVTYP_DEVICEINTERFACE:
          _glfwDetectJoystickDisconnectionWin32()
      break
    return DefWindowProcW(hWnd, uMsg, wParam, lParam)
  case uMsg
  of WM_MOUSEACTIVATE:
    ##  HACK: Postpone cursor disabling when the window was activated by
    ##        clicking a caption button
    if HIWORD(lParam) == WM_LBUTTONDOWN:
      if LOWORD(lParam) != HTCLIENT:
        window.win32.frameAction = GLFW_TRUE
    break
  of WM_CAPTURECHANGED:
    ##  HACK: Disable the cursor once the caption button action has been
    ##        completed or cancelled
    if lParam == 0 and window.win32.frameAction:
      if window.cursorMode == GLFW_CURSOR_DISABLED:
        disableCursor(window)
      window.win32.frameAction = GLFW_FALSE
    break
  of WM_SETFOCUS:
    _glfwInputWindowFocus(window, GLFW_TRUE)
    ##  HACK: Do not disable cursor while the user is interacting with
    ##        a caption button
    if window.win32.frameAction:
      break
    if window.cursorMode == GLFW_CURSOR_DISABLED:
      disableCursor(window)
    return 0
  of WM_KILLFOCUS:
    if window.cursorMode == GLFW_CURSOR_DISABLED:
      enableCursor(window)
    if window.monitor and window.autoIconify:
      _glfwPlatformIconifyWindow(window)
    _glfwInputWindowFocus(window, GLFW_FALSE)
    return 0
  of WM_SYSCOMMAND:
    case wParam and 0xfff0
    of SC_SCREENSAVE, SC_MONITORPOWER:
      if window.monitor:
        ##  We are running in full screen mode, so disallow
        ##  screen saver and screen blanking
        return 0
      else:
        break
      ##  User trying to access application menu using ALT?
    of SC_KEYMENU:
      if not window.win32.keymenu:
        return 0
      break
    break
  of WM_CLOSE:
    _glfwInputWindowCloseRequest(window)
    return 0
  of WM_INPUTLANGCHANGE:
    _glfwUpdateKeyNamesWin32()
    break
  of WM_CHAR, WM_SYSCHAR:
    if wParam >= 0xd800 and wParam <= 0xdbff:
      window.win32.highSurrogate = cast[WCHAR](wParam)
    else:
      var codepoint: cuint = 0
      if wParam >= 0xdc00 and wParam <= 0xdfff:
        if window.win32.highSurrogate:
          inc(codepoint, (window.win32.highSurrogate - 0xd800) shl 10)
          inc(codepoint, cast[WCHAR](wParam) - 0xdc00)
          inc(codepoint, 0x10000)
      else:
        codepoint = cast[WCHAR](wParam)
      window.win32.highSurrogate = 0
      _glfwInputChar(window, codepoint, getKeyMods(), uMsg != WM_SYSCHAR)
    if uMsg == WM_SYSCHAR and window.win32.keymenu:
      break
    return 0
  of WM_UNICHAR:
    if wParam == UNICODE_NOCHAR:
      ##  WM_UNICHAR is not sent by Windows, but is sent by some
      ##  third-party input method engine
      ##  Returning TRUE here announces support for this message
      return TRUE
    _glfwInputChar(window, cast[cuint](wParam), getKeyMods(), GLFW_TRUE)
    return 0
  of WM_KEYDOWN, WM_SYSKEYDOWN, WM_KEYUP, WM_SYSKEYUP:
    var
      key: cint
      scancode: cint
    var action: cint = if (HIWORD(lParam) and KF_UP): GLFW_RELEASE else: GLFW_PRESS
    var mods: cint = getKeyMods()
    scancode = (HIWORD(lParam) and (KF_EXTENDED or 0xff))
    if not scancode:
      ##  NOTE: Some synthetic key messages have a scancode of zero
      ##  HACK: Map the virtual key back to a usable scancode
      scancode = MapVirtualKeyW(cast[UINT](wParam), MAPVK_VK_TO_VSC)
    key = _glfw.win32.keycodes[scancode]
    ##  The Ctrl keys require special handling
    if wParam == VK_CONTROL:
      if HIWORD(lParam) and KF_EXTENDED:
        ##  Right side keys have the extended key bit set
        key = GLFW_KEY_RIGHT_CONTROL
      else:
        ##  NOTE: Alt Gr sends Left Ctrl followed by Right Alt
        ##  HACK: We only want one event for Alt Gr, so if we detect
        ##        this sequence we discard this Left Ctrl message now
        ##        and later report Right Alt normally
        var next: MSG
        var time: DWORD = GetMessageTime()
        if PeekMessageW(addr(next), nil, 0, 0, PM_NOREMOVE):
          if next.message == WM_KEYDOWN or next.message == WM_SYSKEYDOWN or
              next.message == WM_KEYUP or next.message == WM_SYSKEYUP:
            if next.wParam == VK_MENU and (HIWORD(next.lParam) and KF_EXTENDED) and
                next.time == time:
              ##  Next message is Right Alt down so discard this
              break
        key = GLFW_KEY_LEFT_CONTROL
    elif wParam == VK_PROCESSKEY:
      ##  IME notifies that keys have been filtered by setting the
      ##  virtual key-code to VK_PROCESSKEY
      break
    if action == GLFW_RELEASE and wParam == VK_SHIFT:
      ##  HACK: Release both Shift keys on Shift up event, as when both
      ##        are pressed the first release does not emit any event
      ##  NOTE: The other half of this is in _glfwPlatformPollEvents
      _glfwInputKey(window, GLFW_KEY_LEFT_SHIFT, scancode, action, mods)
      _glfwInputKey(window, GLFW_KEY_RIGHT_SHIFT, scancode, action, mods)
    elif wParam == VK_SNAPSHOT:
      ##  HACK: Key down is not reported for the Print Screen key
      _glfwInputKey(window, key, scancode, GLFW_PRESS, mods)
      _glfwInputKey(window, key, scancode, GLFW_RELEASE, mods)
    else:
      _glfwInputKey(window, key, scancode, action, mods)
    break
  of WM_LBUTTONDOWN, WM_RBUTTONDOWN, WM_MBUTTONDOWN, WM_XBUTTONDOWN, WM_LBUTTONUP,
    WM_RBUTTONUP, WM_MBUTTONUP, WM_XBUTTONUP:
    var
      i: cint
      button: cint
      action: cint
    if uMsg == WM_LBUTTONDOWN or uMsg == WM_LBUTTONUP:
      button = GLFW_MOUSE_BUTTON_LEFT
    elif uMsg == WM_RBUTTONDOWN or uMsg == WM_RBUTTONUP:
      button = GLFW_MOUSE_BUTTON_RIGHT
    elif uMsg == WM_MBUTTONDOWN or uMsg == WM_MBUTTONUP:
      button = GLFW_MOUSE_BUTTON_MIDDLE
    elif GET_XBUTTON_WPARAM(wParam) == XBUTTON1:
      button = GLFW_MOUSE_BUTTON_4
    else:
      button = GLFW_MOUSE_BUTTON_5
    if uMsg == WM_LBUTTONDOWN or uMsg == WM_RBUTTONDOWN or uMsg == WM_MBUTTONDOWN or
        uMsg == WM_XBUTTONDOWN:
      action = GLFW_PRESS
    else:
      action = GLFW_RELEASE
    i = 0
    while i <= GLFW_MOUSE_BUTTON_LAST:
      if window.mouseButtons[i] == GLFW_PRESS:
        break
      inc(i)
    if i > GLFW_MOUSE_BUTTON_LAST:
      SetCapture(hWnd)
    _glfwInputMouseClick(window, button, action, getKeyMods())
    i = 0
    while i <= GLFW_MOUSE_BUTTON_LAST:
      if window.mouseButtons[i] == GLFW_PRESS:
        break
      inc(i)
    if i > GLFW_MOUSE_BUTTON_LAST:
      ReleaseCapture()
    if uMsg == WM_XBUTTONDOWN or uMsg == WM_XBUTTONUP:
      return TRUE
    return 0
  of WM_MOUSEMOVE:
    var x: cint = GET_X_LPARAM(lParam)
    var y: cint = GET_Y_LPARAM(lParam)
    if not window.win32.cursorTracked:
      var tme: TRACKMOUSEEVENT
      ZeroMemory(addr(tme), sizeof((tme)))
      tme.cbSize = sizeof((tme))
      tme.dwFlags = TME_LEAVE
      tme.hwndTrack = window.win32.handle
      TrackMouseEvent(addr(tme))
      window.win32.cursorTracked = GLFW_TRUE
      _glfwInputCursorEnter(window, GLFW_TRUE)
    if window.cursorMode == GLFW_CURSOR_DISABLED:
      var dx: cint = x - window.win32.lastCursorPosX
      var dy: cint = y - window.win32.lastCursorPosY
      if _glfw.win32.disabledCursorWindow != window:
        break
      if window.rawMouseMotion:
        break
      _glfwInputCursorPos(window, window.virtualCursorPosX + dx,
                          window.virtualCursorPosY + dy)
    else:
      _glfwInputCursorPos(window, x, y)
    window.win32.lastCursorPosX = x
    window.win32.lastCursorPosY = y
    return 0
  of WM_INPUT:
    var size: UINT = 0
    var ri: HRAWINPUT = cast[HRAWINPUT](lParam)
    var data: ptr RAWINPUT = nil
    var
      dx: cint
      dy: cint
    if _glfw.win32.disabledCursorWindow != window:
      break
    if not window.rawMouseMotion:
      break
    GetRawInputData(ri, RID_INPUT, nil, addr(size), sizeof((RAWINPUTHEADER)))
    if size > cast[UINT](_glfw.win32.rawInputSize):
      free(_glfw.win32.rawInput)
      _glfw.win32.rawInput = calloc(size, 1)
      _glfw.win32.rawInputSize = size
    size = _glfw.win32.rawInputSize
    if GetRawInputData(ri, RID_INPUT, _glfw.win32.rawInput, addr(size),
                      sizeof((RAWINPUTHEADER))) == (UINT) - 1:
      _glfwInputError(GLFW_PLATFORM_ERROR,
                      "Win32: Failed to retrieve raw input data")
      break
    data = _glfw.win32.rawInput
    if data.data.mouse.usFlags and MOUSE_MOVE_ABSOLUTE:
      dx = data.data.mouse.lLastX - window.win32.lastCursorPosX
      dy = data.data.mouse.lLastY - window.win32.lastCursorPosY
    else:
      dx = data.data.mouse.lLastX
      dy = data.data.mouse.lLastY
    _glfwInputCursorPos(window, window.virtualCursorPosX + dx,
                        window.virtualCursorPosY + dy)
    inc(window.win32.lastCursorPosX, dx)
    inc(window.win32.lastCursorPosY, dy)
    break
  of WM_MOUSELEAVE:
    window.win32.cursorTracked = GLFW_FALSE
    _glfwInputCursorEnter(window, GLFW_FALSE)
    return 0
  of WM_MOUSEWHEEL:
    _glfwInputScroll(window, 0.0,
                     cast[SHORT](HIWORD(wParam) div cast[cdouble](WHEEL_DELTA)))
    return 0
  of WM_MOUSEHWHEEL:
    ##  This message is only sent on Windows Vista and later
    ##  NOTE: The X-axis is inverted for consistency with macOS and X11
    _glfwInputScroll(window, -(cast[SHORT](HIWORD(wParam) div
        cast[cdouble](WHEEL_DELTA))), 0.0)
    return 0
  of WM_ENTERSIZEMOVE, WM_ENTERMENULOOP:
    if window.win32.frameAction:
      break
    if window.cursorMode == GLFW_CURSOR_DISABLED:
      enableCursor(window)
    break
  of WM_EXITSIZEMOVE, WM_EXITMENULOOP:
    if window.win32.frameAction:
      break
    if window.cursorMode == GLFW_CURSOR_DISABLED:
      disableCursor(window)
    break
  of WM_SIZE:
    var width: cint = LOWORD(lParam)
    var height: cint = HIWORD(lParam)
    var iconified: bool = wParam == SIZE_MINIMIZED
    var maximized: bool = wParam == SIZE_MAXIMIZED or
        (window.win32.maximized and wParam != SIZE_RESTORED)
    if _glfw.win32.disabledCursorWindow == window:
      updateClipRect(window)
    if window.win32.iconified != iconified:
      _glfwInputWindowIconify(window, iconified)
    if window.win32.maximized != maximized:
      _glfwInputWindowMaximize(window, maximized)
    if width != window.win32.width or height != window.win32.height:
      window.win32.width = width
      window.win32.height = height
      _glfwInputFramebufferSize(window, width, height)
      _glfwInputWindowSize(window, width, height)
    if window.monitor and window.win32.iconified != iconified:
      if iconified:
        releaseMonitor(window)
      else:
        acquireMonitor(window)
        fitToMonitor(window)
    window.win32.iconified = iconified
    window.win32.maximized = maximized
    return 0
  of WM_MOVE:
    if _glfw.win32.disabledCursorWindow == window:
      updateClipRect(window)
    _glfwInputWindowPos(window, GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam))
    return 0
  of WM_SIZING:
    if window.numer == GLFW_DONT_CARE or window.denom == GLFW_DONT_CARE:
      break
    applyAspectRatio(window, cast[cint](wParam), cast[ptr RECT](lParam))
    return TRUE
  of WM_GETMINMAXINFO:
    var
      xoff: cint
      yoff: cint
    var dpi: UINT = USER_DEFAULT_SCREEN_DPI
    var mmi: ptr MINMAXINFO = cast[ptr MINMAXINFO](lParam)
    if window.monitor:
      break
    if isWindows10AnniversaryUpdateOrGreater():
      dpi = GetDpiForWindow(window.win32.handle)
    getFullWindowSize(getWindowStyle(window), getWindowExStyle(window), 0, 0,
                      addr(xoff), addr(yoff), dpi)
    if window.minwidth != GLFW_DONT_CARE and window.minheight != GLFW_DONT_CARE:
      mmi.ptMinTrackSize.x = window.minwidth + xoff
      mmi.ptMinTrackSize.y = window.minheight + yoff
    if window.maxwidth != GLFW_DONT_CARE and window.maxheight != GLFW_DONT_CARE:
      mmi.ptMaxTrackSize.x = window.maxwidth + xoff
      mmi.ptMaxTrackSize.y = window.maxheight + yoff
    if not window.isDecorated:
      var mi: MONITORINFO
      var mh: HMONITOR = MonitorFromWindow(window.win32.handle,
                                       MONITOR_DEFAULTTONEAREST)
      ZeroMemory(addr(mi), sizeof((mi)))
      mi.cbSize = sizeof((mi))
      GetMonitorInfo(mh, addr(mi))
      mmi.ptMaxPosition.x = mi.rcWork.left - mi.rcMonitor.left
      mmi.ptMaxPosition.y = mi.rcWork.top - mi.rcMonitor.top
      mmi.ptMaxSize.x = mi.rcWork.right - mi.rcWork.left
      mmi.ptMaxSize.y = mi.rcWork.bottom - mi.rcWork.top
    return 0
  of WM_PAINT:
    _glfwInputWindowDamage(window)
    break
  of WM_ERASEBKGND:
    return TRUE
  of WM_NCACTIVATE, WM_NCPAINT:
    ##  Prevent title bar from being drawn after restoring a minimized
    ##  undecorated window
    if not window.isDecorated:
      return TRUE
    break
  of WM_DWMCOMPOSITIONCHANGED, WM_DWMCOLORIZATIONCOLORCHANGED:
    if window.win32.transparent:
      updateFramebufferTransparency(window)
    return 0
  of WM_GETDPISCALEDSIZE:
    if window.win32.scaleToMonitor:
      break
    if _glfwIsWindows10CreatorsUpdateOrGreaterWin32():
      var
        source: RECT = [0]
        target: RECT = [0]
      var size: ptr SIZE = cast[ptr SIZE](lParam)
      AdjustWindowRectExForDpi(addr(source), getWindowStyle(window), FALSE,
                               getWindowExStyle(window),
                               GetDpiForWindow(window.win32.handle))
      AdjustWindowRectExForDpi(addr(target), getWindowStyle(window), FALSE,
                               getWindowExStyle(window), LOWORD(wParam))
      inc(size.cx, (target.right - target.left) - (source.right - source.left))
      inc(size.cy, (target.bottom - target.top) - (source.bottom - source.top))
      return TRUE
    break
  of WM_DPICHANGED:
    var xscale: cfloat = HIWORD(wParam) div cast[cfloat](USER_DEFAULT_SCREEN_DPI)
    var yscale: cfloat = LOWORD(wParam) div cast[cfloat](USER_DEFAULT_SCREEN_DPI)
    ##  Resize windowed mode windows that either permit rescaling or that
    ##  need it to compensate for non-client area scaling
    if not window.monitor and
        (window.win32.scaleToMonitor or
        _glfwIsWindows10CreatorsUpdateOrGreaterWin32()):
      var suggested: ptr RECT = cast[ptr RECT](lParam)
      SetWindowPos(window.win32.handle, HWND_TOP, suggested.left, suggested.top,
                   suggested.right - suggested.left,
                   suggested.bottom - suggested.top, SWP_NOACTIVATE or
          SWP_NOZORDER)
    _glfwInputWindowContentScale(window, xscale, yscale)
    break
  of WM_SETCURSOR:
    if LOWORD(lParam) == HTCLIENT:
      updateCursorImage(window)
      return TRUE
    break
  of WM_DROPFILES:
    var drop: HDROP = cast[HDROP](wParam)
    var pt: POINT
    var i: cint
    var count: cint = DragQueryFileW(drop, 0xffffffff, nil, 0)
    var paths: cstringArray = calloc(count, sizeof(cstring))
    ##  Move the mouse to the position of the drop
    DragQueryPoint(drop, addr(pt))
    _glfwInputCursorPos(window, pt.x, pt.y)
    i = 0
    while i < count:
      var length: UINT = DragQueryFileW(drop, i, nil, 0)
      var buffer: ptr WCHAR = calloc(cast[csize_t](length) + 1, sizeof((WCHAR)))
      DragQueryFileW(drop, i, buffer, length + 1)
      paths[i] = _glfwCreateUTF8FromWideStringWin32(buffer)
      free(buffer)
      inc(i)
    _glfwInputDrop(window, count, cast[cstringArray](paths))
    i = 0
    while i < count:
      free(paths[i])
      inc(i)
    free(paths)
    DragFinish(drop)
    return 0
  return DefWindowProcW(hWnd, uMsg, wParam, lParam)

##  Creates the GLFW window
##

proc createNativeWindow*(window: Window, wndconfig: ptr _GLFWwndconfig,
                        fbconfig: ptr _GLFWfbconfig): cint =
  var
    xpos: cint
    ypos: cint
    fullWidth: cint
    fullHeight: cint
  var wideTitle: ptr WCHAR
  var style: DWORD = getWindowStyle(window)
  var exStyle: DWORD = getWindowExStyle(window)
  if window.monitor:
    var mode: GLFWvidmode
    ##  NOTE: This window placement is temporary and approximate, as the
    ##        correct position and size cannot be known until the monitor
    ##        video mode has been picked in _glfwSetVideoModeWin32
    _glfwPlatformGetMonitorPos(window.monitor, addr(xpos), addr(ypos))
    _glfwPlatformGetVideoMode(window.monitor, addr(mode))
    fullWidth = mode.width
    fullHeight = mode.height
  else:
    xpos = CW_USEDEFAULT
    ypos = CW_USEDEFAULT
    window.win32.maximized = wndconfig.maximized
    if wndconfig.maximized:
      style = style or WS_MAXIMIZE
    getFullWindowSize(style, exStyle, wndconfig.width, wndconfig.height,
                      addr(fullWidth), addr(fullHeight), USER_DEFAULT_SCREEN_DPI)
  wideTitle = _glfwCreateWideStringFromUTF8Win32(wndconfig.title)
  if not wideTitle:
    return GLFW_FALSE
  window.win32.handle = CreateWindowExW(exStyle, _GLFW_WNDCLASSNAME, wideTitle,
                                      style, xpos, ypos, fullWidth, fullHeight, nil, ##  No parent window
                                      nil, ##  No window menu
                                      GetModuleHandleW(nil),
                                      cast[LPVOID](wndconfig))
  free(wideTitle)
  if not window.win32.handle:
    _glfwInputErrorWin32(GLFW_PLATFORM_ERROR, "Win32: Failed to create window")
    return GLFW_FALSE
  SetPropW(window.win32.handle, L, "GLFW", window)
  if IsWindows7OrGreater():
    ChangeWindowMessageFilterEx(window.win32.handle, WM_DROPFILES, MSGFLT_ALLOW,
                                nil)
    ChangeWindowMessageFilterEx(window.win32.handle, WM_COPYDATA, MSGFLT_ALLOW, nil)
    ChangeWindowMessageFilterEx(window.win32.handle, WM_COPYGLOBALDATA,
                                MSGFLT_ALLOW, nil)
  window.win32.scaleToMonitor = wndconfig.scaleToMonitor
  window.win32.keymenu = wndconfig.win32.keymenu
  ##  Adjust window rect to account for DPI scaling of the window frame and
  ##  (if enabled) DPI scaling of the content area
  ##  This cannot be done until we know what monitor the window was placed on
  if not window.monitor:
    var rect: RECT = [0, 0, wndconfig.width, wndconfig.height]
    var wp: WINDOWPLACEMENT = [sizeof((wp))]
    if wndconfig.scaleToMonitor:
      var
        xscale: cfloat
        yscale: cfloat
      _glfwPlatformGetWindowContentScale(window, addr(xscale), addr(yscale))
      rect.right = (int)(rect.right * xscale)
      rect.bottom = (int)(rect.bottom * yscale)
    ClientToScreen(window.win32.handle, cast[ptr POINT](addr(rect.left)))
    ClientToScreen(window.win32.handle, cast[ptr POINT](addr(rect.right)))
    if isWindows10AnniversaryUpdateOrGreater():
      AdjustWindowRectExForDpi(rect.addr, style, FALSE, exStyle,
                               GetDpiForWindow(window.win32.handle))
    else:
      AdjustWindowRectEx(rect.addr, style, FALSE, exStyle)
    ##  Only update the restored window rect as the window may be maximized
    GetWindowPlacement(window.win32.handle, addr(wp))
    wp.rcNormalPosition = rect
    wp.showCmd = SW_HIDE
    SetWindowPlacement(window.win32.handle, addr(wp))
  DragAcceptFiles(window.win32.handle, TRUE)
  if fbconfig.transparent:
    updateFramebufferTransparency(window)
    window.win32.transparent = GLFW_TRUE
  _glfwPlatformGetWindowSize(window, addr(window.win32.width),
                             addr(window.win32.height))
  return GLFW_TRUE

## ////////////////////////////////////////////////////////////////////////
## ////                       GLFW internal API                      //////
## ////////////////////////////////////////////////////////////////////////
##  Registers the GLFW window class
##

proc _glfwRegisterWindowClassWin32*(): bool =
  var wc: WNDCLASSEXW
  ZeroMemory(addr(wc), sizeof((wc)))
  wc.cbSize = sizeof((wc))
  wc.style = CS_HREDRAW or CS_VREDRAW or CS_OWNDC
  wc.lpfnWndProc = cast[WNDPROC](windowProc)
  wc.hInstance = GetModuleHandleW(nil)
  wc.hCursor = LoadCursorW(nil, IDC_ARROW)
  wc.lpszClassName = _GLFW_WNDCLASSNAME
  ##  Load user-provided icon if available
  wc.hIcon = LoadImageW(GetModuleHandleW(nil), L, "GLFW_ICON", IMAGE_ICON, 0, 0,
                      LR_DEFAULTSIZE or LR_SHARED)
  if not wc.hIcon:
    ##  No user-provided icon found, load default icon
    wc.hIcon = LoadImageW(nil, IDI_APPLICATION, IMAGE_ICON, 0, 0,
                        LR_DEFAULTSIZE or LR_SHARED)
  if not RegisterClassExW(addr(wc)):
    _glfwInputErrorWin32(GLFW_PLATFORM_ERROR,
                         "Win32: Failed to register window class")
    return GLFW_FALSE
  return GLFW_TRUE

##  Unregisters the GLFW window class
##

proc _glfwUnregisterWindowClassWin32*() =
  UnregisterClassW(_GLFW_WNDCLASSNAME, GetModuleHandleW(nil))

## ////////////////////////////////////////////////////////////////////////
## ////                       GLFW platform API                      //////
## ////////////////////////////////////////////////////////////////////////

proc _glfwPlatformCreateWindow*(window: Window,
                               wndconfig: ptr _GLFWwndconfig,
                               ctxconfig: ptr _GLFWctxconfig,
                               fbconfig: ptr _GLFWfbconfig): cint =
  if not createNativeWindow(window, wndconfig, fbconfig):
    return GLFW_FALSE
  if ctxconfig.client != GLFW_NO_API:
    if ctxconfig.source == GLFW_NATIVE_CONTEXT_API:
      if not _glfwInitWGL():
        return GLFW_FALSE
      if not _glfwCreateContextWGL(window, ctxconfig, fbconfig):
        return GLFW_FALSE
    elif ctxconfig.source == GLFW_EGL_CONTEXT_API:
      if not _glfwInitEGL():
        return GLFW_FALSE
      if not _glfwCreateContextEGL(window, ctxconfig, fbconfig):
        return GLFW_FALSE
    elif ctxconfig.source == GLFW_OSMESA_CONTEXT_API:
      if not _glfwInitOSMesa():
        return GLFW_FALSE
      if not _glfwCreateContextOSMesa(window, ctxconfig, fbconfig):
        return GLFW_FALSE
  if window.monitor:
    _glfwPlatformShowWindow(window)
    _glfwPlatformFocusWindow(window)
    acquireMonitor(window)
    fitToMonitor(window)
  return GLFW_TRUE

proc _glfwPlatformDestroyWindow*(window: Window) =
  if window.monitor:
    releaseMonitor(window)
  if window.context.destroy:
    window.context.destroy(window)
  if _glfw.win32.disabledCursorWindow == window:
    _glfw.win32.disabledCursorWindow = nil
  if window.win32.handle:
    RemovePropW(window.win32.handle, L, "GLFW")
    DestroyWindow(window.win32.handle)
    window.win32.handle = nil
  if window.win32.bigIcon:
    DestroyIcon(window.win32.bigIcon)
  if window.win32.smallIcon:
    DestroyIcon(window.win32.smallIcon)

proc _glfwPlatformSetWindowTitle*(window: Window, title: cstring) =
  var wideTitle: ptr WCHAR = _glfwCreateWideStringFromUTF8Win32(title)
  if not wideTitle:
    return
  SetWindowTextW(window.win32.handle, wideTitle)
  free(wideTitle)

proc _glfwPlatformSetWindowIcon*(window: Window, count: cint,
                                images: ptr GLFWimage) =
  var
    bigIcon: HICON = nil
    smallIcon: HICON = nil
  if count:
    var bigImage: ptr GLFWimage = chooseImage(count, images,
        GetSystemMetrics(SM_CXICON), GetSystemMetrics(SM_CYICON))
    var smallImage: ptr GLFWimage = chooseImage(count, images,
        GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON))
    bigIcon = createIcon(bigImage, 0, 0, GLFW_TRUE)
    smallIcon = createIcon(smallImage, 0, 0, GLFW_TRUE)
  else:
    bigIcon = cast[HICON](GetClassLongPtrW(window.win32.handle, GCLP_HICON))
    smallIcon = cast[HICON](GetClassLongPtrW(window.win32.handle, GCLP_HICONSM))
  SendMessage(window.win32.handle, WM_SETICON, ICON_BIG, cast[LPARAM](bigIcon))
  SendMessage(window.win32.handle, WM_SETICON, ICON_SMALL, cast[LPARAM](smallIcon))
  if window.win32.bigIcon:
    DestroyIcon(window.win32.bigIcon)
  if window.win32.smallIcon:
    DestroyIcon(window.win32.smallIcon)
  if count:
    window.win32.bigIcon = bigIcon
    window.win32.smallIcon = smallIcon

proc _glfwPlatformGetWindowPos*(window: Window, xpos: ptr cint, ypos: ptr cint) =
  var pos: POINT = [0, 0]
  ClientToScreen(window.win32.handle, addr(pos))
  if xpos:
    xpos[] = pos.x
  if ypos:
    ypos[] = pos.y

proc _glfwPlatformSetWindowPos*(window: Window, xpos: cint, ypos: cint) =
  var rect: RECT = [xpos, ypos, xpos, ypos]
  if isWindows10AnniversaryUpdateOrGreater():
    AdjustWindowRectExForDpi(rect.addr, getWindowStyle(window), FALSE,
                             getWindowExStyle(window),
                             GetDpiForWindow(window.win32.handle))
  else:
    AdjustWindowRectEx(rect.addr, getWindowStyle(window), FALSE,
                       getWindowExStyle(window))
  SetWindowPos(window.win32.handle, nil, rect.left, rect.top, 0, 0,
               SWP_NOACTIVATE or SWP_NOZORDER or SWP_NOSIZE)

proc _glfwPlatformGetWindowSize*(window: Window, width: ptr cint,
                                height: ptr cint) =
  var area: RECT
  GetClientRect(window.win32.handle, addr(area))
  if width:
    width[] = area.right
  if height:
    height[] = area.bottom

proc _glfwPlatformSetWindowSize*(window: Window, width: cint, height: cint) =
  if window.monitor:
    if window.monitor.window == window:
      acquireMonitor(window)
      fitToMonitor(window)
  else:
    var rect: RECT = [0, 0, width, height]
    if isWindows10AnniversaryUpdateOrGreater():
      AdjustWindowRectExForDpi(rect.addr, getWindowStyle(window), FALSE,
                               getWindowExStyle(window),
                               GetDpiForWindow(window.win32.handle))
    else:
      AdjustWindowRectEx(rect.addr, getWindowStyle(window), FALSE,
                         getWindowExStyle(window))
    SetWindowPos(window.win32.handle, HWND_TOP, 0, 0, rect.right - rect.left,
                 rect.bottom - rect.top, SWP_NOACTIVATE or SWP_NOOWNERZORDER or
        SWP_NOMOVE or SWP_NOZORDER)

proc _glfwPlatformSetWindowSizeLimits*(window: Window, minwidth: cint,
                                      minheight: cint, maxwidth: cint,
                                      maxheight: cint) =
  var area: RECT
  if (minwidth == GLFW_DONT_CARE or minheight == GLFW_DONT_CARE) and
      (maxwidth == GLFW_DONT_CARE or maxheight == GLFW_DONT_CARE):
    return
  GetWindowRect(window.win32.handle, addr(area))
  MoveWindow(window.win32.handle, area.left, area.top, area.right - area.left,
             area.bottom - area.top, TRUE)

proc _glfwPlatformSetWindowAspectRatio*(window: Window, numer: cint,
                                       denom: cint) =
  var area: RECT
  if numer == GLFW_DONT_CARE or denom == GLFW_DONT_CARE:
    return
  GetWindowRect(window.win32.handle, addr(area))
  applyAspectRatio(window, WMSZ_BOTTOMRIGHT, addr(area))
  MoveWindow(window.win32.handle, area.left, area.top, area.right - area.left,
             area.bottom - area.top, TRUE)

proc _glfwPlatformGetFramebufferSize*(window: Window, width: ptr cint,
                                     height: ptr cint) =
  _glfwPlatformGetWindowSize(window, width, height)

proc _glfwPlatformGetWindowFrameSize*(window: Window, left: ptr cint,
                                     top: ptr cint, right: ptr cint, bottom: ptr cint) =
  var rect: RECT
  var
    width: cint
    height: cint
  _glfwPlatformGetWindowSize(window, addr(width), addr(height))
  SetRect(rect.addr, 0, 0, width, height)
  if isWindows10AnniversaryUpdateOrGreater():
    AdjustWindowRectExForDpi(rect.addr, getWindowStyle(window), FALSE,
                             getWindowExStyle(window),
                             GetDpiForWindow(window.win32.handle))
  else:
    AdjustWindowRectEx(rect.addr, getWindowStyle(window), FALSE,
                       getWindowExStyle(window))
  if left:
    left[] = -rect.left
  if top:
    top[] = -rect.top
  if right:
    right[] = rect.right - width
  if bottom:
    bottom[] = rect.bottom - height

proc _glfwPlatformGetWindowContentScale*(window: Window,
                                        xscale: ptr cfloat, yscale: ptr cfloat) =
  var handle: HANDLE = MonitorFromWindow(window.win32.handle,
                                     MONITOR_DEFAULTTONEAREST)
  _glfwGetMonitorContentScaleWin32(handle, xscale, yscale)

proc _glfwPlatformIconifyWindow*(window: Window) =
  ShowWindow(window.win32.handle, SW_MINIMIZE)

proc _glfwPlatformRestoreWindow*(window: Window) =
  ShowWindow(window.win32.handle, SW_RESTORE)

proc _glfwPlatformMaximizeWindow*(window: Window) =
  ShowWindow(window.win32.handle, SW_MAXIMIZE)

proc _glfwPlatformShowWindow*(window: Window) =
  ShowWindow(window.win32.handle, SW_SHOWNA)

proc _glfwPlatformHideWindow*(window: Window) =
  ShowWindow(window.win32.handle, SW_HIDE)

proc _glfwPlatformRequestWindowAttention*(window: Window) =
  FlashWindow(window.win32.handle, TRUE)

proc _glfwPlatformFocusWindow*(window: Window) =
  BringWindowToTop(window.win32.handle)
  SetForegroundWindow(window.win32.handle)
  SetFocus(window.win32.handle)

proc _glfwPlatformSetWindowMonitor*(window: Window,
                                   monitor: ptr _GLFWmonitor, xpos: cint, ypos: cint,
                                   width: cint, height: cint, refreshRate: cint) =
  if window.monitor == monitor:
    if monitor:
      if monitor.window == window:
        acquireMonitor(window)
        fitToMonitor(window)
    else:
      var rect: RECT = [xpos, ypos, xpos + width, ypos + height]
      if isWindows10AnniversaryUpdateOrGreater():
        AdjustWindowRectExForDpi(rect.addr, getWindowStyle(window), FALSE,
                                 getWindowExStyle(window),
                                 GetDpiForWindow(window.win32.handle))
      else:
        AdjustWindowRectEx(rect.addr, getWindowStyle(window), FALSE,
                           getWindowExStyle(window))
      SetWindowPos(window.win32.handle, HWND_TOP, rect.left, rect.top,
                   rect.right - rect.left, rect.bottom - rect.top,
                   SWP_NOCOPYBITS or SWP_NOACTIVATE or SWP_NOZORDER)
    return
  if window.monitor:
    releaseMonitor(window)
  _glfwInputWindowMonitor(window, monitor)
  if window.monitor:
    var mi: MONITORINFO = [sizeof((mi))]
    var flags: UINT = SWP_SHOWWINDOW or SWP_NOACTIVATE or SWP_NOCOPYBITS
    if window.isDecorated:
      var style: DWORD = GetWindowLongW(window.win32.handle, GWL_STYLE)
      style = style and not WS_OVERLAPPEDWINDOW
      style = style or getWindowStyle(window)
      SetWindowLongW(window.win32.handle, GWL_STYLE, style)
      flags = flags or SWP_FRAMECHANGED
    acquireMonitor(window)
    GetMonitorInfo(window.monitor.win32.handle, addr(mi))
    SetWindowPos(window.win32.handle, HWND_TOPMOST, mi.rcMonitor.left,
                 mi.rcMonitor.top, mi.rcMonitor.right - mi.rcMonitor.left,
                 mi.rcMonitor.bottom - mi.rcMonitor.top, flags)
  else:
    var after: HWND
    var rect: RECT = [xpos, ypos, xpos + width, ypos + height]
    var style: DWORD = GetWindowLongW(window.win32.handle, GWL_STYLE)
    var flags: UINT = SWP_NOACTIVATE or SWP_NOCOPYBITS
    if window.isDecorated:
      style = style and not WS_POPUP
      style = style or getWindowStyle(window)
      SetWindowLongW(window.win32.handle, GWL_STYLE, style)
      flags = flags or SWP_FRAMECHANGED
    if window.isFloating:
      after = HWND_TOPMOST
    else:
      after = HWND_NOTOPMOST
    if isWindows10AnniversaryUpdateOrGreater():
      AdjustWindowRectExForDpi(rect.addr, getWindowStyle(window), FALSE,
                               getWindowExStyle(window),
                               GetDpiForWindow(window.win32.handle))
    else:
      AdjustWindowRectEx(rect.addr, getWindowStyle(window), FALSE,
                         getWindowExStyle(window))
    SetWindowPos(window.win32.handle, after, rect.left, rect.top,
                 rect.right - rect.left, rect.bottom - rect.top, flags)

proc _glfwPlatformWindowFocused*(window: Window): cint =
  return window.win32.handle == GetActiveWindow()

proc _glfwPlatformWindowIconified*(window: Window): cint =
  return IsIconic(window.win32.handle)

proc _glfwPlatformWindowVisible*(window: Window): cint =
  return IsWindowVisible(window.win32.handle)

proc _glfwPlatformWindowMaximized*(window: Window): cint =
  return IsZoomed(window.win32.handle)

proc _glfwPlatformWindowHovered*(window: Window): cint =
  return cursorInContentArea(window)

proc _glfwPlatformFramebufferTransparent*(window: Window): cint =
  var
    composition: BOOL
    opaque: BOOL
  var color: DWORD
  if not window.win32.transparent:
    return GLFW_FALSE
  if not IsWindowsVistaOrGreater():
    return GLFW_FALSE
  if FAILED(DwmIsCompositionEnabled(addr(composition))) or not composition:
    return GLFW_FALSE
  if not IsWindows8OrGreater():
    ##  HACK: Disable framebuffer transparency on Windows 7 when the
    ##        colorization color is opaque, because otherwise the window
    ##        contents is blended additively with the previous frame instead
    ##        of replacing it
    if FAILED(DwmGetColorizationColor(addr(color), addr(opaque))) or opaque:
      return GLFW_FALSE
  return GLFW_TRUE

proc _glfwPlatformSetWindowResizable*(window: Window, enabled: bool) =
  updateWindowStyles(window)

proc _glfwPlatformSetWindowDecorated*(window: Window, enabled: bool) =
  updateWindowStyles(window)

proc _glfwPlatformSetWindowFloating*(window: Window, enabled: bool) =
  var after: HWND = if enabled: HWND_TOPMOST else: HWND_NOTOPMOST
  SetWindowPos(window.win32.handle, after, 0, 0, 0, 0,
               SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE)

proc _glfwPlatformSetWindowMousePassthrough*(window: Window,
    enabled: bool) =
  var key: COLORREF = 0
  var alpha: BYTE = 0
  var flags: DWORD = 0
  var exStyle: DWORD = GetWindowLongW(window.win32.handle, GWL_EXSTYLE)
  if exStyle and WS_EX_LAYERED:
    GetLayeredWindowAttributes(window.win32.handle, addr(key), addr(alpha),
                               addr(flags))
  if enabled:
    exStyle = exStyle or (WS_EX_TRANSPARENT or WS_EX_LAYERED)
  else:
    exStyle = exStyle and not WS_EX_TRANSPARENT
    ##  NOTE: Window opacity also needs the layered window style so do not
    ##        remove it if the window is alpha blended
    if exStyle and WS_EX_LAYERED:
      if not (flags and LWA_ALPHA):
        exStyle = exStyle and not WS_EX_LAYERED
  SetWindowLongW(window.win32.handle, GWL_EXSTYLE, exStyle)
  if enabled:
    SetLayeredWindowAttributes(window.win32.handle, key, alpha, flags)

proc _glfwPlatformGetWindowOpacity*(window: Window): cfloat =
  var alpha: BYTE
  var flags: DWORD
  if (GetWindowLongW(window.win32.handle, GWL_EXSTYLE) and WS_EX_LAYERED) and
      GetLayeredWindowAttributes(window.win32.handle, nil, addr(alpha), addr(flags)):
    if flags and LWA_ALPHA:
      return alpha div 255.f
  return 1.f

proc _glfwPlatformSetWindowOpacity*(window: Window, opacity: cfloat) =
  var exStyle: LONG = GetWindowLongW(window.win32.handle, GWL_EXSTYLE)
  if opacity < 1.f or (exStyle and WS_EX_TRANSPARENT):
    var alpha: BYTE = (BYTE)(255 * opacity)
    exStyle = exStyle or WS_EX_LAYERED
    SetWindowLongW(window.win32.handle, GWL_EXSTYLE, exStyle)
    SetLayeredWindowAttributes(window.win32.handle, 0, alpha, LWA_ALPHA)
  elif exStyle and WS_EX_TRANSPARENT:
    SetLayeredWindowAttributes(window.win32.handle, 0, 0, 0)
  else:
    exStyle = exStyle and not WS_EX_LAYERED
    SetWindowLongW(window.win32.handle, GWL_EXSTYLE, exStyle)

proc _glfwPlatformSetRawMouseMotion*(window: Window, enabled: bool) =
  if _glfw.win32.disabledCursorWindow != window:
    return
  if enabled:
    enableRawMouseMotion(window)
  else:
    disableRawMouseMotion(window)

proc _glfwPlatformRawMouseMotionSupported*(): bool =
  return GLFW_TRUE

proc _glfwPlatformPollEvents*() =
  var msg: MSG
  var handle: HWND
  var window: Window
  while PeekMessageW(addr(msg), nil, 0, 0, PM_REMOVE):
    if msg.message == WM_QUIT:
      ##  NOTE: While GLFW does not itself post WM_QUIT, other processes
      ##        may post it to this one, for example Task Manager
      ##  HACK: Treat WM_QUIT as a close on all windows
      window = _glfw.windowListHead
      while window:
        _glfwInputWindowCloseRequest(window)
        window = window.next
    else:
      TranslateMessage(addr(msg))
      DispatchMessageW(addr(msg))
  ##  HACK: Release modifier keys that the system did not emit KEYUP for
  ##  NOTE: Shift keys on Windows tend to "stick" when both are pressed as
  ##        no key up message is generated by the first key release
  ##  NOTE: Windows key is not reported as released by the Win+V hotkey
  ##        Other Win hotkeys are handled implicitly by _glfwInputWindowFocus
  ##        because they change the input focus
  ##  NOTE: The other half of this is in the WM_*KEY* handler in windowProc
  handle = GetActiveWindow()
  if handle:
    window = GetPropW(handle, L, "GLFW")
    if window:
      var i: cint
      var keys: array[4, array[2, cint]] = [[VK_LSHIFT, GLFW_KEY_LEFT_SHIFT],
                                      [VK_RSHIFT, GLFW_KEY_RIGHT_SHIFT],
                                      [VK_LWIN, GLFW_KEY_LEFT_SUPER],
                                      [VK_RWIN, GLFW_KEY_RIGHT_SUPER]]
      i = 0
      while i < 4:
        var vk: cint = keys[i][0]
        var key: cint = keys[i][1]
        var scancode: cint = _glfw.win32.scancodes[key]
        if (GetKeyState(vk) and 0x8000):
          inc(i)
          continue
        if window.keys[key] != GLFW_PRESS:
          inc(i)
          continue
        _glfwInputKey(window, key, scancode, GLFW_RELEASE, getKeyMods())
        inc(i)
  window = _glfw.win32.disabledCursorWindow
  if window:
    var
      width: cint
      height: cint
    _glfwPlatformGetWindowSize(window, addr(width), addr(height))
    ##  NOTE: Re-center the cursor only if it has moved since the last call,
    ##        to avoid breaking glfwWaitEvents with WM_MOUSEMOVE
    if window.win32.lastCursorPosX != width div 2 or
        window.win32.lastCursorPosY != height div 2:
      _glfwPlatformSetCursorPos(window, width div 2, height div 2)

proc _glfwPlatformWaitEvents*() =
  WaitMessage()
  _glfwPlatformPollEvents()

proc _glfwPlatformWaitEventsTimeout*(timeout: cdouble) =
  MsgWaitForMultipleObjects(0, nil, FALSE, (DWORD)(timeout * 1e3), QS_ALLEVENTS)
  _glfwPlatformPollEvents()

proc _glfwPlatformPostEmptyEvent*() =
  PostMessage(_glfw.win32.helperWindowHandle, WM_NULL, 0, 0)

proc _glfwPlatformGetCursorPos*(window: Window, xpos: ptr cdouble,
                               ypos: ptr cdouble) =
  var pos: POINT
  if GetCursorPos(addr(pos)):
    ScreenToClient(window.win32.handle, addr(pos))
    if xpos:
      xpos[] = pos.x
    if ypos:
      ypos[] = pos.y

proc _glfwPlatformSetCursorPos*(window: Window, xpos: cdouble, ypos: cdouble) =
  var pos: POINT = [cast[cint](xpos), cast[cint](ypos)]
  ##  Store the new position so it can be recognized later
  window.win32.lastCursorPosX = pos.x
  window.win32.lastCursorPosY = pos.y
  ClientToScreen(window.win32.handle, addr(pos))
  SetCursorPos(pos.x, pos.y)

proc _glfwPlatformSetCursorMode*(window: Window, mode: cint) =
  if mode == GLFW_CURSOR_DISABLED:
    if _glfwPlatformWindowFocused(window):
      disableCursor(window)
  elif _glfw.win32.disabledCursorWindow == window:
    enableCursor(window)
  elif cursorInContentArea(window):
    updateCursorImage(window)

proc _glfwPlatformGetScancodeName*(scancode: cint): cstring =
  if scancode < 0 or scancode > (KF_EXTENDED or 0xff) or
      _glfw.win32.keycodes[scancode] == GLFW_KEY_UNKNOWN:
    _glfwInputError(GLFW_INVALID_VALUE, "Invalid scancode %i", scancode)
    return nil
  return _glfw.win32.keynames[_glfw.win32.keycodes[scancode]]

proc _glfwPlatformGetKeyScancode*(key: cint): cint =
  return _glfw.win32.scancodes[key]

proc _glfwPlatformCreateCursor*(cursor: ptr _GLFWcursor, image: ptr GLFWimage,
                               xhot: cint, yhot: cint): cint =
  cursor.win32.handle = cast[HCURSOR](createIcon(image, xhot, yhot, GLFW_FALSE))
  if not cursor.win32.handle:
    return GLFW_FALSE
  return GLFW_TRUE

proc _glfwPlatformCreateStandardCursor*(cursor: ptr _GLFWcursor, shape: cint): cint =
  var id: cint = 0
  case shape
  of GLFW_ARROW_CURSOR:
    id = OCR_NORMAL
  of GLFW_IBEAM_CURSOR:
    id = OCR_IBEAM
  of GLFW_CROSSHAIR_CURSOR:
    id = OCR_CROSS
  of GLFW_POINTING_HAND_CURSOR:
    id = OCR_HAND
  of GLFW_RESIZE_EW_CURSOR:
    id = OCR_SIZEWE
  of GLFW_RESIZE_NS_CURSOR:
    id = OCR_SIZENS
  of GLFW_RESIZE_NWSE_CURSOR:
    id = OCR_SIZENWSE
  of GLFW_RESIZE_NESW_CURSOR:
    id = OCR_SIZENESW
  of GLFW_RESIZE_ALL_CURSOR:
    id = OCR_SIZEALL
  of GLFW_NOT_ALLOWED_CURSOR:
    id = OCR_NO
  else:
    _glfwInputError(GLFW_PLATFORM_ERROR, "Win32: Unknown standard cursor")
    return GLFW_FALSE
  cursor.win32.handle = LoadImageW(nil, MAKEINTRESOURCEW(id), IMAGE_CURSOR, 0, 0,
                                 LR_DEFAULTSIZE or LR_SHARED)
  if not cursor.win32.handle:
    _glfwInputErrorWin32(GLFW_PLATFORM_ERROR,
                         "Win32: Failed to create standard cursor")
    return GLFW_FALSE
  return GLFW_TRUE

proc _glfwPlatformDestroyCursor*(cursor: ptr _GLFWcursor) =
  if cursor.win32.handle:
    DestroyIcon(cast[HICON](cursor.win32.handle))

proc _glfwPlatformSetCursor*(window: Window, cursor: ptr _GLFWcursor) =
  if cursorInContentArea(window):
    updateCursorImage(window)

proc _glfwPlatformSetClipboardString*(string: cstring) =
  var characterCount: cint
  var `object`: HANDLE
  var buffer: ptr WCHAR
  characterCount = MultiByteToWideChar(CP_UTF8, 0, string, -1, nil, 0)
  if not characterCount:
    return
  `object` = GlobalAlloc(GMEM_MOVEABLE, characterCount * sizeof((WCHAR)))
  if not `object`:
    _glfwInputErrorWin32(GLFW_PLATFORM_ERROR, "Win32: Failed to allocate global handle for clipboard")
    return
  buffer = GlobalLock(`object`)
  if not buffer:
    _glfwInputErrorWin32(GLFW_PLATFORM_ERROR,
                         "Win32: Failed to lock global handle")
    GlobalFree(`object`)
    return
  MultiByteToWideChar(CP_UTF8, 0, string, -1, buffer, characterCount)
  GlobalUnlock(`object`)
  if not OpenClipboard(_glfw.win32.helperWindowHandle):
    _glfwInputErrorWin32(GLFW_PLATFORM_ERROR, "Win32: Failed to open clipboard")
    GlobalFree(`object`)
    return
  EmptyClipboard()
  SetClipboardData(CF_UNICODETEXT, `object`)
  CloseClipboard()

proc _glfwPlatformGetClipboardString*(): cstring =
  var `object`: HANDLE
  var buffer: ptr WCHAR
  if not OpenClipboard(_glfw.win32.helperWindowHandle):
    _glfwInputErrorWin32(GLFW_PLATFORM_ERROR, "Win32: Failed to open clipboard")
    return nil
  `object` = GetClipboardData(CF_UNICODETEXT)
  if not `object`:
    _glfwInputErrorWin32(GLFW_FORMAT_UNAVAILABLE,
                         "Win32: Failed to convert clipboard to string")
    CloseClipboard()
    return nil
  buffer = GlobalLock(`object`)
  if not buffer:
    _glfwInputErrorWin32(GLFW_PLATFORM_ERROR,
                         "Win32: Failed to lock global handle")
    CloseClipboard()
    return nil
  free(_glfw.win32.clipboardString)
  _glfw.win32.clipboardString = _glfwCreateUTF8FromWideStringWin32(buffer)
  GlobalUnlock(`object`)
  CloseClipboard()
  return _glfw.win32.clipboardString

proc _glfwPlatformGetEGLPlatform*(attribs: ptr ptr EGLint): EGLenum =
  if _glfw.egl.ANGLE_platform_angle:
    var `type`: cint = 0
    if _glfw.egl.ANGLE_platform_angle_opengl:
      if _glfw.hints.init.angleType == GLFW_ANGLE_PLATFORM_TYPE_OPENGL:
        `type` = EGL_PLATFORM_ANGLE_TYPE_OPENGL_ANGLE
      elif _glfw.hints.init.angleType == GLFW_ANGLE_PLATFORM_TYPE_OPENGLES:
        `type` = EGL_PLATFORM_ANGLE_TYPE_OPENGLES_ANGLE
    if _glfw.egl.ANGLE_platform_angle_d3d:
      if _glfw.hints.init.angleType == GLFW_ANGLE_PLATFORM_TYPE_D3D9:
        `type` = EGL_PLATFORM_ANGLE_TYPE_D3D9_ANGLE
      elif _glfw.hints.init.angleType == GLFW_ANGLE_PLATFORM_TYPE_D3D11:
        `type` = EGL_PLATFORM_ANGLE_TYPE_D3D11_ANGLE
    if _glfw.egl.ANGLE_platform_angle_vulkan:
      if _glfw.hints.init.angleType == GLFW_ANGLE_PLATFORM_TYPE_VULKAN:
        `type` = EGL_PLATFORM_ANGLE_TYPE_VULKAN_ANGLE
    if `type`:
      attribs[] = calloc(3, sizeof((EGLint)))
      (attribs[])[0] = EGL_PLATFORM_ANGLE_TYPE_ANGLE
      (attribs[])[1] = `type`
      (attribs[])[2] = EGL_NONE
      return EGL_PLATFORM_ANGLE_ANGLE
  return 0

proc _glfwPlatformGetEGLNativeDisplay*(): EGLNativeDisplayType =
  return GetDC(_glfw.win32.helperWindowHandle)

proc _glfwPlatformGetEGLNativeWindow*(window: Window): EGLNativeWindowType =
  return window.win32.handle

proc _glfwPlatformGetRequiredInstanceExtensions*(extensions: cstringArray) =
  if not _glfw.vk.KHR_surface or not _glfw.vk.KHR_win32_surface:
    return
  extensions[0] = "VK_KHR_surface"
  extensions[1] = "VK_KHR_win32_surface"

proc _glfwPlatformGetPhysicalDevicePresentationSupport*(instance: VkInstance,
    device: VkPhysicalDevice, queuefamily: uint32_t): cint =
  var vkGetPhysicalDeviceWin32PresentationSupportKHR: PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR = cast[PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR](vkGetInstanceProcAddr(
      instance, "vkGetPhysicalDeviceWin32PresentationSupportKHR"))
  if not vkGetPhysicalDeviceWin32PresentationSupportKHR:
    _glfwInputError(GLFW_API_UNAVAILABLE, "Win32: Vulkan instance missing VK_KHR_win32_surface extension")
    return GLFW_FALSE
  return vkGetPhysicalDeviceWin32PresentationSupportKHR(device, queuefamily)

proc _glfwPlatformCreateWindowSurface*(instance: VkInstance,
                                      window: Window,
                                      allocator: ptr VkAllocationCallbacks,
                                      surface: ptr VkSurfaceKHR): VkResult =
  var err: VkResult
  var sci: VkWin32SurfaceCreateInfoKHR
  var vkCreateWin32SurfaceKHR: PFN_vkCreateWin32SurfaceKHR
  vkCreateWin32SurfaceKHR = cast[PFN_vkCreateWin32SurfaceKHR](vkGetInstanceProcAddr(
      instance, "vkCreateWin32SurfaceKHR"))
  if not vkCreateWin32SurfaceKHR:
    _glfwInputError(GLFW_API_UNAVAILABLE, "Win32: Vulkan instance missing VK_KHR_win32_surface extension")
    return VK_ERROR_EXTENSION_NOT_PRESENT
  memset(addr(sci), 0, sizeof((sci)))
  sci.sType = VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR
  sci.hinstance = GetModuleHandle(nil)
  sci.hwnd = window.win32.handle
  err = vkCreateWin32SurfaceKHR(instance, addr(sci), allocator, surface)
  if err:
    _glfwInputError(GLFW_PLATFORM_ERROR,
                    "Win32: Failed to create Vulkan surface: %s",
                    _glfwGetVulkanResultString(err))
  return err

## ////////////////////////////////////////////////////////////////////////
## ////                        GLFW native API                       //////
## ////////////////////////////////////////////////////////////////////////

proc glfwGetWin32Window*(handle: ptr GLFWwindow): HWND =
  var window: Window = cast[Window](handle)
  _GLFW_REQUIRE_INIT_OR_RETURN(nil)
  return window.win32.handle
