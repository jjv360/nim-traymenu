
# Independent stuff
import ./traymenu/menu
export menu

# Platform dependent stuff
when defined(windows):

    # Windows specific stuff
    import ./traymenu/windows
    export windows
    