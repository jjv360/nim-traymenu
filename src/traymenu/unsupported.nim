import std/asyncdispatch
import classes
import ./menu
import ./traymenu_base

## Create a system tray icon
class TrayMenu of TrayMenuBase:
    
    ## Set menu icon from PNG data
    method loadIconFromData(data : string) =
        discard


    ## Show the tray icon
    method show() = raiseAssert("TrayMenu is not supported on this platform.")

    ## Update the tray icon
    method update() = discard

    ## Remove the tray icon
    method remove() = discard

    ## Called to display the tray's menu
    method openContextMenu() : Future[TrayMenuItem] {.async.} = 
        return nil