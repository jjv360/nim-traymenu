
# Independent stuff
import ./traymenu/menu
import ./traymenu/traymenu_base
export menu, traymenu_base

# Platform dependent stuff
when defined(windows):

    # Windows specific stuff
    import ./traymenu/windows
    export windows

# elif defined(linux):

#     # Linux specific stuff
#     import ./traymenu/linux
#     export linux
    
else:

    # Unsupported stub class
    import ./traymenu/unsupported
    export unsupported