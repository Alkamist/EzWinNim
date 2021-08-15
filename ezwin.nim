import
  pixie,
  ezwin/[windowwin32, input]

export windowwin32, input

when isMainModule:
  var wnd = newWindow(
    title = "Test Window",
    x = 2.0,
    y = 2.0,
    width = 4.0,
    height = 4.0,
  )

  wnd.onDraw = proc =
    let ctx = wnd.context
    ctx.fillStyle = rgba(255, 0, 0, 255)
    ctx.fillRect(rect(
      vec2(50, 50),
      vec2(100, 100),
    ))

  while not wnd.shouldClose:
    wnd.pollEvents()