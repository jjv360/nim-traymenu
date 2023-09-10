# Nim TrayMenu

![](https://img.shields.io/badge/status-beta-orange)
![](https://img.shields.io/badge/platforms-windows-darkgreen)

Create system tray icons and menus in Nim.

```nim
import traymenu
import std/asyncdispatch

# Create a tray icon
let tray = TrayMenu.init()
tray.tooltip = "My App"
tray.loadIcon("file.png")
tray.show()

# Add a menu item
tray.contextMenu.add(TrayMenuItem(title: "Hello World", onClick: proc() = echo "Hello World!"))

# Ensure asyncdispatch is running
drain(int.high)
```

> **Note:** The `show()` function may fail if dependent libraries are not available on the system, or if the current desktop environment doesn't support system tray icons. You can wrap it with a try/catch to handle this. It uses the WinAPI on Windows, and 

> **Note:** On linux you'll need the DBus dev package, which you can get with `sudo apt install libdbus-1-dev`

See the [example](./tests/test_tray.nim) for more information.