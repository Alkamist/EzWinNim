import ../mouselogic

func toMouseButton*(scanCode: cushort): MouseButton =
  case scanCode:
  of 0: MouseButton.Left
  of 1: MouseButton.Middle
  of 2: MouseButton.Right
  of 3: MouseButton.Extra1
  of 4: MouseButton.Extra2
  else: MouseButton.Unknown