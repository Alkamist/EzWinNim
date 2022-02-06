import windowlogic, mouselogic, keyboardlogic
export windowlogic, mouselogic, keyboardlogic

when defined(windows):
  import win32/window
  export window
elif defined(emscripten):
  import emscripten/window
  export window