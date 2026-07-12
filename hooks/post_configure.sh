#!/bin/sh
# post_configure.sh — force an EMPTY src/auto/osdef.h, matching the i686 vim port.
#
# vim's osdef.sh auto-generates auto/osdef.h with prototypes for functions it believes are missing
# from the system headers. On NanOS x86_64 it wrongly emits
#     extern int  sigsetjmp(sigjmp_buf, int);
#     extern void siglongjmp(sigjmp_buf, int);
# because <machine/setjmp.h> exposes sigsetjmp only as a GNU-C statement-expression MACRO (no plain
# prototype for osdef.sh's preprocess-and-grep to detect). osdef.h is #included from vim.h BEFORE
# <setjmp.h>, so `sigjmp_buf` is an unknown type at that point -> "expected ')' before 'int'" and
# the whole build fails. The i686 port's osdef.h is EMPTY (every prototype vim needs comes from the
# real picolibc/libc-glue headers), which is the correct arch-independent answer — sigsetjmp itself
# still works via the <setjmp.h> macro wherever vim's .c files include it (HAVE_SIGSETJMP stays on).
#
# We (re)create osdef.h empty and stamp it newer than auto/config.h so make's
#   `auto/osdef.h: auto/config.h osdef.sh osdef1.h.in osdef2.h.in`
# rule sees it up-to-date and never re-runs osdef.sh.
set -e
: > src/auto/osdef.h
touch src/auto/osdef.h
echo "  [post_configure] forced empty src/auto/osdef.h (matches i686; avoids the sigsetjmp prototype bug)"
