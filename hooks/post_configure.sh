#!/bin/sh
# picolibc defines sigsetjmp/sigsetmask/etc. as MACROS, so vim's generated src/auto/osdef.h
# (prototypes harvested from the system headers) expands them and fails to compile. picolibc
# already declares every function vim needs, so an empty osdef.h is correct here.
set -e
: > "$STAGE/src/auto/osdef.h"
echo "post_configure: emptied src/auto/osdef.h (picolibc declares these; macro prototypes clash)"
