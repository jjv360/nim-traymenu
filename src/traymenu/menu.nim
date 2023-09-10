import classes

## Defines a menu component
class TrayMenuItem:

    ## System-defined menu ID
    var id = 0

    ## Item title
    var title = ""

    ## Is separator
    var isSeparator = false

    ## Is disabled
    var isDisabled = false

    ## Is checked
    var isChecked = false

    ## Submenu items. This is considered a submenu if it is not empty.
    var submenuItems : seq[TrayMenuItem]

    ## Callback function when the menu item is clicked
    var onClick : proc() = nil