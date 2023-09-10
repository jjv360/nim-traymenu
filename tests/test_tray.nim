import std/os
import std/asyncdispatch
import ../src/traymenu


## Enhancements on Windows
when defined(windows):

    import winim/lean
    import stdx/dynlib

    # Useful imports from uxtheme.dll
    dynamicImport("uxtheme.dll"):

        ## Preferred app modes
        type PreferredAppMode = enum 
            APPMODE_DEFAULT = 0
            APPMODE_ALLOWDARK = 1
            APPMODE_FORCEDARK = 2
            APPMODE_FORCELIGHT = 3
            APPMODE_MAX = 4

        ## Set the preferred app mode, mainly changes context menus
        proc SetPreferredAppMode(mode : PreferredAppMode) {.stdcall, winapiOrdinal:135, winapiVersion: "10.0.17763".}

    # Enable High DPI mode to prevent blurry UI
    SetProcessDPIAware()

    # Enable dark mode if the system is set to dark mode
    SetPreferredAppMode(APPMODE_ALLOWDARK)




# Tray icon data
const trayIcon = staticRead(currentSourcePath.parentDir() / "trayicon.png")

# Create tray menu
let tray = TrayMenu.init()
tray.tooltip = "Nim - TrayMenu Test"
tray.loadIconFromData(trayIcon)
tray.onClick = proc() = echo "Tray clicked!"
tray.onMenuItemClick = proc(item : TrayMenuItem) = echo "Menu item clicked: ", item.title

# Show if supported
if tray.supported:
    tray.show()
else:
    echo "TrayMenu not supported on this platform!"
    quit(1)

# Create tray menu items
tray.contextMenu.add(TrayMenuItem(title: "Nim - TrayMenu Test", isDisabled: true))
tray.contextMenu.add(TrayMenuItem(isSeparator: true))
tray.contextMenu.add(TrayMenuItem(title: "Item 1"))

# Submenu
var submenu = TrayMenuitem(title: "Item 2")
submenu.submenuItems.add(TrayMenuItem(title: "Subitem 1"))
submenu.submenuItems.add(TrayMenuItem(title: "Subitem 2", isChecked: true))
submenu.submenuItems.add(TrayMenuItem(title: "Subitem 3"))
tray.contextMenu.add(submenu)

# Hide the tray and then show it again after a few seconds
proc hideAndShow() {.async.} =
    tray.remove()
    await sleepAsync(1000)
    tray.show()

# More menu items
tray.contextMenu.add(TrayMenuItem(title: "Item 3"))
tray.contextMenu.add(TrayMenuItem(isSeparator: true))
tray.contextMenu.add(TrayMenuItem(title: "Hide", onClick: proc() = asyncCheck hideAndShow()))
tray.contextMenu.add(TrayMenuItem(title: "Quit", onClick: proc() = quit()))


# Continually update the tooltip and menu
proc updateTooltip() {.async.} =
    for i in 0 ..< int.high:
        await sleepAsync(250)
        tray.tooltip = "Nim - TrayMenu Test - " & $i
        tray.contextMenu[0].title = "Nim - TrayMenu Test - " & $i
        tray.update()
asyncCheck updateTooltip()



# Run asyncdispatch
echo "App starting..."
drain(int.high)
echo "App ending..."