import std/asyncdispatch
import classes
import ./menu
import ./traymenu_base
import ./gtk3

##
## The state of tray icons in Linux is UNBELIEVABLE. There are multiple methods of doing this and they all have issues.
## Here's a nice article about it: https://blog.tingping.se/2019/09/07/how-to-design-a-modern-status-icon.html
## 
## So... I'll only support GtkStatusIcon for now. Kill me.
## 


## Create a system tray icon
class TrayMenu of TrayMenuBase:

    ## Tray icon
    var statusIcon : GtkStatusIcon

    ## Check if supported on this playform
    method supported() : bool = true

    ## Constructor
    method init() =
        
        # Initialize Gtk
        let success = gtk_init_check(nil, nil)
        if not success:
            raise newException(OSError, "Failed to initialize GTK.")

        # Create menu
        this.statusIcon = gtk_status_icon_new()
        if this.statusIcon == nil:
            raise newException(OSError, "Failed to create tray icon.")

    
    ## Set menu icon from PNG data
    method loadIconFromData(data : string) =
    
        # Create memory input stream
        let inputStream = g_memory_input_stream_new_from_data(data[0].addr, data.len)
        if inputStream == nil:
            raise newException(OSError, "Failed to create memory input stream.")

        # Create pixbuf
        let icon = gdk_pixbuf_new_from_stream(inputStream)
        if icon == nil:
            raise newException(OSError, "Failed to process the icon image.")

        # Set icon from pixbuf
        echo "Icon: ", this.statusIcon.repr, " Pixbuf: ", icon.repr
        this.statusIcon.set_from_pixbuf(icon)

        # Unref resources we aren't using any more
        inputStream.unref()
        icon.unref()


    ## Show the tray icon
    method show() =

        # Update icon
        this.update()

        # Set visible
        this.statusIcon.set_visible(true)


    ## Update the tray icon
    method update() = 
        discard

    ## Remove the tray icon
    method remove() = 

        # Hide icon
        this.statusIcon.set_visible(false)


    ## Called to display the tray's menu
    method openContextMenu() : Future[TrayMenuItem] {.async.} = 
        return nil