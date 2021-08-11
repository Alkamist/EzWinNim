import ezwin/[windowwin32, input]

export windowwin32, input

when isMainModule:
  var wnd = newWindow(
    title = "Test Window",
    x = 2.0,
    y = 2.0,
    width = 4.0,
    height = 4.0,
  )

  wnd.onKeyPress = proc =
    echo wnd.input.lastKeyPress

  while not wnd.shouldClose:
    wnd.pollEvents()