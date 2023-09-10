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

See the [example](./tests/test_tray.nim) for more information.