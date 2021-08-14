import
  pixie, winim/lean,
  ezwin/[windowwin32, input]

export windowwin32, input

let
  w: int32 = 256
  h: int32 = 256

var
  image = newImage(w, h)
  ctx = newContext(image)
  frameCount = 0

proc draw(hWnd: HWND) =
  ctx.fillStyle = rgba(255, 0, 0, 255)

  let
    pos = vec2(50, 50)
    wh = vec2(100, 100)

  ctx.fillRect(rect(pos, wh))

  inc frameCount

  let
    w = image.width.int32
    h = image.height.int32
    dc = GetDC(hWnd)

  var info = BITMAPINFO()
  info.bmiHeader.biBitCount = 32
  info.bmiHeader.biWidth = w
  info.bmiHeader.biHeight = h
  info.bmiHeader.biPlanes = 1
  info.bmiHeader.biSize = DWORD sizeof(BITMAPINFOHEADER)
  info.bmiHeader.biSizeImage = w * h * 4
  info.bmiHeader.biCompression = BI_RGB

  var bgrBuffer = newSeq[uint8](image.data.len * 4)

  # Convert to BGRA.
  for i, c in image.data:
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
  ReleaseDC(hWnd, dc)

when isMainModule:
  var wnd = newWindow(
    title = "Test Window",
    x = 2.0,
    y = 2.0,
    width = 4.0,
    height = 4.0,
  )

  wnd.onDraw = proc =
    draw(wnd.hWnd)

  wnd.onChar = proc =
    echo wnd.input.lastChar

  while not wnd.shouldClose:
    wnd.pollEvents()