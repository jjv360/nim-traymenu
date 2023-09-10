import stdx/winlean
import std/tables
import stdx/asyncdispatch
import classes
import winim/mean
import pixie
import ./menu
import ./traymenu_base

## List of all active windows
var activeHWNDs: Table[HWND, RootRef]

## Tray message ID
const WM_MyTrayMessage = WM_USER + 1

## Proxy function for stdcall to class function
proc wndProcProxy(hwnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.}

## Register the Win32 "class"
proc registerWindowClass(): string =

    # If done already, stop
    const WindowClassName = "NimTrayMenuWindow"
    var hasDone {.global.} = false
    if hasDone:
        return WindowClassName

    # Do it
    var wc: WNDCLASSEX
    wc.cbSize = sizeof(WNDCLASSEX).UINT
    wc.lpfnWndProc = wndProcProxy
    wc.hInstance = GetModuleHandle(nil)
    wc.lpszClassName = WindowClassName
    wc.style = CS_HREDRAW or CS_VREDRAW
    wc.hIcon = LoadIcon(0, IDI_APPLICATION)
    wc.hCursor = LoadCursor(0, IDC_ARROW)
    wc.hbrBackground = (HBRUSH) (COLOR_WINDOW + 1)
    RegisterClassEx(wc)

    # Done
    hasDone = true
    return WindowClassName


## Create a system tray icon
class TrayMenu of TrayMenuBase:

    ## Tray icon
    var hIcon : HICON

    ## Tray window
    var hwnd : HWND
    
    ## Set menu icon from PNG data
    method loadIconFromData(data : string) =

        # Load image
        var image = decodeImage(data)

        # Resize to the system's desired icon size
        let width = GetSystemMetrics(SM_CXSMICON)
        let height = GetSystemMetrics(SM_CYSMICON)
        if width == 0 or height == 0: raiseLastError("Unable to get system tray icon size.")
        if width != image.width or height != image.height:
            image = image.resize(width, height)

        # Create icon information
        var iconInfo : ICONINFO
        iconInfo.fIcon = true           # <-- This is an icon, not a cursor
        
        # Convert pixels to Win32's weird format
        var imgDataARGB = newSeq[uint8](image.width * image.height * 4)
        for i in 0 ..< image.width * image.height:
            let pixel = image.data[i]
            imgDataARGB[i * 4 + 0] = pixel.b
            imgDataARGB[i * 4 + 1] = pixel.g
            imgDataARGB[i * 4 + 2] = pixel.r
            imgDataARGB[i * 4 + 3] = pixel.a

        # Create color bitmap
        iconInfo.hbmColor = CreateBitmap(image.width.int32, image.height.int32, 1, 32, imgDataARGB[0].addr)
        if iconInfo.hbmColor == 0:
            raiseLastError("Unable to create bitmap for tray icon.")

        # Create blank bitmask bitmap
        iconInfo.hbmMask = CreateCompatibleBitmap(GetDC(0), image.width.int32, image.height.int32)
        if iconInfo.hbmMask == 0:
            raiseLastError("Unable to create mask bitmap for tray icon.")

        # Create the icon
        let hIcon = CreateIconIndirect(iconInfo)
        if hIcon == 0:
            raiseLastError("Unable to create icon for system tray icon.")

        # Clean up
        DeleteObject(iconInfo.hbmColor)
        DeleteObject(iconInfo.hbmMask)

        # Save icon
        this.hIcon = hIcon


    ## Update the tray icon
    method updateNativeTray() =

        # Check if it already exists
        var isCreating = this.hwnd == 0
        if isCreating:

            # Create window
            this.hwnd = CreateWindowExW(
                0,                                  # Extra window styles
                registerWindowClass(),              # Class name
                "NimTrayMenuWindow",                # Window title
                0,                                  # Window style

                # Size and position, x, y, width, height
                0, 0, 0, 0,

                HWND_MESSAGE,                       # Parent window    
                0,                                  # Menu
                GetModuleHandle(nil),               # Instance handle
                nil                                 # Extra data
            )

            # Store it
            activeHWNDs[this.hwnd] = this

            # Start the windows event loop
            asyncCheck startWindowsEventLoop()

        # Setup notification data
        var data : NOTIFYICONDATAW
        data.cbSize = windef.DWORD(sizeof(data))
        data.uVersion = NOTIFYICON_VERSION_4
        data.hWnd = this.hwnd
        data.uID = 1                                    # <-- No unique ID needed since we make a new window for each tray icon
        data.uFlags = NIF_STATE or NIF_TIP or NIF_SHOWTIP or NIF_MESSAGE
        data.dwState = 0
        data.uCallbackMessage = WM_MyTrayMessage

        # Add icon if we have one
        if this.hIcon != 0:
            data.uFlags = data.uFlags or NIF_ICON
            data.hIcon = this.hIcon

        # Convert tooltip to TCHAR with a 64-byte limit, and copy it into the struct
        var tooltip = this.tooltip
        if tooltip.len > 63: tooltip = tooltip[0 ..< 63]
        let wTooltip = +$tooltip
        for i in 0 ..< wTooltip.len: 
            data.szTip[i] = wTooltip[i]

        # Check operation
        if isCreating:

            # Add it
            let success = Shell_NotifyIconW(NIM_ADD, data)
            if success == 0:
                raiseLastError("Unable to create system tray icon.")

            # Update version
            Shell_NotifyIconW(NIM_SETVERSION, data)

        else:

            # Just update it
            let success = Shell_NotifyIconW(NIM_MODIFY, data)
            if success == 0:
                raiseLastError("Unable to update system tray icon.")


    ## Check if supported on this playform
    method supported() : bool = true


    ## Show the tray icon
    method show() =

        # Update it
        this.updateNativeTray()


    ## Update the tray icon
    method update() = 
    
        # Stop if not visible
        if this.hwnd == 0: 
            return

        # Update native tray again
        this.updateNativeTray()


    ## Remove the tray icon
    method remove() =

        # Stop if already removed
        if this.hwnd == 0: 
            return

        # Setup notification data
        var data : NOTIFYICONDATAW
        data.cbSize = windef.DWORD(sizeof(data))
        data.uVersion = NOTIFYICON_VERSION_4
        data.hWnd = this.hwnd
        data.uID = 1                                    # <-- No unique ID needed since we make a new window for each tray icon
        data.uFlags = 0

        # Remove it
        let success = Shell_NotifyIconW(NIM_DELETE, data)
        if success == 0:
            raiseLastError("Unable to remove system tray icon.")

        # Delete window
        DestroyWindow(this.hwnd)
        activeHWNDs.del(this.hwnd)
        this.hwnd = 0


    ## Called when a WinAPI event is received
    method wndProc(hwnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT =

        # Check if message is for another component
        if uMsg != WM_MyTrayMessage:
            return DefWindowProc(hwnd, uMsg, wParam, lParam)

        # Check message
        let uMsg2 = LOWORD(lParam)
        if uMsg2 == WM_LBUTTONUP or uMsg2 == WM_CONTEXTMENU:

            # Notify clicked
            if this.onClick != nil:
                this.onClick()

            # User activated the tray icon, show menu
            asyncCheck this.openContextMenu()
            return 0

        else:

            # Pass on to base
            return DefWindowProc(hwnd, uMsg, wParam, lParam)


    ## Build the HMENU resource
    method buildHMENU(parent : HMENU, index : int, menu : TrayMenuItem) =

        # Unique menu IDs
        var LastMenuID {.global.} = 1

        # Create unique menu item ID if necessary
        if menu.id == 0:
            menu.id = LastMenuID
            LastMenuID += 1

        # Create menu item info
        var menuItemInfo : MENUITEMINFOW
        menuItemInfo.cbSize = sizeof(menuItemInfo).UINT
        menuItemInfo.fMask = MIIM_ID or MIIM_FTYPE or MIIM_STATE or MIIM_STRING
        menuItemInfo.fType = MFT_STRING
        menuItemInfo.wID = menu.id.UINT
        menuItemInfo.dwTypeData = menu.title
        menuItemInfo.cch = menu.title.len.UINT

        # If it's a separator, set the flag
        if menu.isSeparator:
            menuItemInfo.fType = menuItemInfo.fType or MFT_SEPARATOR

        # If it's disabled, set the flag
        if menu.isDisabled:
            menuItemInfo.fState = menuItemInfo.fState or MFS_DISABLED

        # If it's checked, show checkmark
        if menu.isChecked:
            menuItemInfo.fState = menuItemInfo.fState or MFS_CHECKED

        # Check if there's a submenu
        for index, submenuItem in menu.submenuItems:

            # If this is the first one, create the menu
            if menuItemInfo.hSubMenu == 0:
                menuItemInfo.hSubMenu = CreatePopupMenu()
                menuItemInfo.fMask = menuItemInfo.fMask or MIIM_SUBMENU

            # Add it to the submenu
            this.buildHMENU(menuItemInfo.hSubMenu, index, submenuItem)

        # Create menu item
        let success = InsertMenuItemW(parent, index.UINT, TRUE, menuItemInfo)
        if success == FALSE:
            raiseLastError("Unable to create menu item.")


    ## Called to display the tray's menu and returns the clicked item
    method openContextMenu() : Future[TrayMenuItem] {.async.} =

        # If no items, stop
        if this.contextMenu.len == 0:
            return nil

        # Create menu
        let hMenu = CreatePopupMenu()
        if hMenu == FALSE:
            raiseLastError("Unable to create popup menu.")

        # Get menu items
        for idx, menuItem in this.contextMenu:
            this.buildHMENU(hMenu, idx, menuItem)

        # Get cursor position
        var cursorPos : POINT
        let winResult1 = GetCursorPos(cursorPos)
        if winResult1 == FALSE:
            raiseLastError("Unable to get cursor position.")

        # Show menu in new thread
        var winResult2 : windef.WINBOOL = 0
        awaitThread(winResult2, hMenu, cursorPos):

            # Create temporary window
            let hwnd = CreateWindowExW(
                0,                                  # Extra window styles
                registerWindowClass(),              # Class name
                "HiddenWindow",                     # Window title
                0,                                  # Window style

                # Size and position, x, y, width, height
                0, 0, 0, 0,

                HWND_MESSAGE,                       # Parent window    
                0,                                  # Menu
                GetModuleHandle(nil),               # Instance handle
                nil                                 # Extra data
            )

            # Workaround: The menu doesn't close unless the user clicks a menu item. This issue is addressed in the elusive MSDN article Q135788.
            # Basically, the HWND needs to be made foreground before calling TrackPopupMenu(). Very weird, considering the window isn't even a
            # real window...
            SetForegroundWindow(hwnd)

            # Run the menu
            SetLastError(0)
            winResult2 = TrackPopupMenuEx(hMenu, TPM_NONOTIFY or TPM_RETURNCMD or TPM_RIGHTBUTTON, cursorPos.x, cursorPos.y, hwnd, nil)

            # Check for error
            if GetLastError() != 0:
                raiseLastError()

            # Destroy the temporary window
            DestroyWindow(hwnd)

        # Check if cancelled
        if winResult2 == FALSE:
            return

        # Recursively find the item that was selected
        proc findChild(items : seq[TrayMenuItem]) : TrayMenuItem =
            for item in items:
                if item.id == winResult2: return item
                if item.submenuItems.len > 0:
                    let found = findChild(item.submenuItems)
                    if found != nil: return found
            return nil
        let clickedItem = findChild(this.contextMenu)

        # Stop if not found
        if clickedItem == nil:
            echo "Unable to find selected menu item."
            return nil

        # Call our onClick handler
        if this.onMenuItemClick != nil:
            this.onMenuItemClick(clickedItem)

        # Call it's onClick handler
        if clickedItem.onClick != nil:
            clickedItem.onClick()

        # Return the clicked item
        return clickedItem

        






## Proxy function for stdcall to class function
proc wndProcProxy(hwnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =

    # Find class instance
    let component = activeHWNDs.getOrDefault(hwnd, nil).TrayMenu()
    if component == nil:

        # No component associated with this HWND, we don't know where to route this message... Maybe it's a thread message or something? 
        # Let's just perform the default action.
        return DefWindowProc(hwnd, uMsg, wParam, lParam)

    # Pass on
    return component.wndProc(hwnd, uMsg, wParam, lParam)