##
## Imports for using libgtk3
import stdx/dynlib


## Types
type gint* = int
type gboolean* = distinct gint
type gssize* = int
type guint32* = uint32
type GQuark* = guint32
type GObject* = pointer
type GInputStream* = GObject
type GDestroyNotify* = proc(data : pointer) {.cdecl.}
type GtkStatusIcon* = GObject
type GdkPixbuf* = GObject

## Error
type GErrorStruct* {.pure.} = object

    ## Error domain, e.g. G_FILE_ERROR.
    domain* : GQuark

    ## Error code, e.g. G_FILE_ERROR_NOENT.
    code* : gint

    ## Human-readable informative error message.
    message : cstring

## Pointer to an error
type GError* = ptr GErrorStruct


## Import functions from libgtk ang libgdk
## From: https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-TrialUse/LSB-TrialUse/gtk3libraries.html
dynamicImport("libgtk-3.so.0"):

    ## This function does the same work as gtk_init() with only a single change: It does not terminate the program if the commandline arguments couldn’t be parsed or the windowing system can’t be initialized. Instead it returns FALSE on failure.
    proc gtk_init_check*(argc : ptr int, argv : pointer) : gboolean {.cdecl.}

    ## Decreases the reference count of object. When its reference count drops to 0, the object is finalized (i.e. its memory is freed).
    proc unref*(this : GObject) {.cdecl, importc:"g_object_unref".}

    ## Creates a new GMemoryInputStream with data in memory of a given size.
    proc g_memory_input_stream_new_from_data*(data : pointer, len : gssize, destroy : GDestroyNotify = nil) : GInputStream {.cdecl.}

    ## Closes the stream, releasing resources related to it.
    proc close*(this : GInputStream, cancellable : pointer = nil, error : pointer = nil) : gboolean {.cdecl, importc:"g_input_stream_close".}

    ## Creates an empty status icon object.
    proc gtk_status_icon_new*() : GtkStatusIcon {.cdecl.}

    ## Makes status_icon display the file filename. See gtk_status_icon_new_from_file() for details.
    proc set_from_file*(this : GtkStatusIcon, filename : cstring) {.cdecl, importc:"gtk_status_icon_set_from_file".}

    ## Makes status_icon display pixbuf. See gtk_status_icon_new_from_pixbuf() for details.
    proc set_from_pixbuf*(this : GtkStatusIcon, pixbuf : GdkPixbuf) {.cdecl, importc:"gtk_status_icon_set_from_pixbuf".}

    ## Shows or hides a status icon.
    proc set_visible*(this : GtkStatusIcon, visible : gboolean) {.cdecl, importc:"gtk_status_icon_set_visible".}


## Import from libgdk as well (the graphics library)
dynamicImport("libgdk-3.so.0"):

    ## Creates a new pixbuf by loading an image from an input stream.
    proc gdk_pixbuf_new_from_stream*(stream : GInputStream, cancellable : pointer = nil, error : ptr GError = nil) : GdkPixbuf {.cdecl.}




## Allow gboolean to be converted to Nim's bool
converter gbooleanToBool*(input : gboolean) : bool = cast[gint](input) != 0
converter boolToGboolean*(input : bool) : gboolean = 
    if input: return cast[gboolean](1)
    else: return cast[gboolean](0)