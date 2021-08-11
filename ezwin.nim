import ezwin/[windowwin32, input]

export windowwin32, input

when isMainModule:
  var wnd = newWindow(
    title = "Test Window",
    bounds = ((1.0, 1.0), (4.0, 3.0)),
  )

  wnd.onKeyPress = proc =
    echo wnd.input.lastKeyPress

  while not wnd.shouldClose:
    wnd.pollEvents()