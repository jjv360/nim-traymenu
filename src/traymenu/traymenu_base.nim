import std/asyncdispatch
import classes
import ./menu

## Base class for tray menus
class TrayMenuBase:

    ## Tooltip
    var tooltip = ""

    ## Menu items
    var contextMenu : seq[TrayMenuItem]

    ## Callback when the tray icon is clicked
    var onClick : proc() = nil

    ## Callback when a menu item is clicked
    var onMenuItemClick : proc(item : TrayMenuItem) = nil

    ## Set menu icon from a file path
    method loadIcon(path : string) =
        
        # Load file data
        var data = readFile(path)

        # Load image
        this.loadIconFromData(data)

    
    ## Set menu icon from PNG data (abstract)
    method loadIconFromData(data : string)

    ## Show the tray icon
    method show()

    ## Update the tray icon
    method update()

    ## Remove the tray icon
    method remove()

    ## Called to display the tray's menu
    method openContextMenu() : Future[TrayMenuItem] {.async.}

    ## Check if supported on this playform
    method supported() : bool = false