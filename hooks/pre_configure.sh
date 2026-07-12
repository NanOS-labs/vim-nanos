#!/bin/sh
# pre_configure.sh — prepare the vim source tree (copied verbatim by nanos-port's `dir:` source)
# for an x86_64-nanos cross build.
#
# (1) REUSE the i686 cross-cache. vim's src/configure hardcodes `--cache-file=auto/config.cache`
#     (appended AFTER nanos-port's own --cache-file, and the last one wins), so the driver's
#     nxport.cache is ignored — vim only ever reads src/auto/config.cache. That file in the source
#     tree IS the committed i686 vim cross-cache (all the vim_cv_*/vi_cv_*/cf_cv_* AC_RUN answers +
#     the header/func probes). We reuse it verbatim, only: drop the i686-nanos CC/CPP/AWK + env/alias
#     pins so x86_64-nanos-gcc is auto-detected from --host, and override the 4 arch-dependent values
#     (long/pointer/size_t = 8 for LP64, uname_m = x86_64). Everything else is arch-independent
#     (both arches link the same NanOS libc), so it carries over unchanged.
#
# (2) SCRUB the stale i686 build state (generated auto/* + 32-bit objects) so configure regenerates
#     for x86_64 and `make` never links a leftover i686 object. vim's top Makefile and src/Makefile
#     are STATIC (checked-in) — configure only generates src/auto/config.{mk,h}+osdef.h+pathdef.c —
#     so we keep the Makefiles and delete only the generated/compiled artifacts.
set -e

CACHE=src/auto/config.cache
if [ -f "$CACHE" ]; then
	grep -vE 'ac_cv_env_|_alias|ac_cv_prog_CC=|ac_cv_prog_CPP|ac_cv_prog_AWK|ac_cv_sizeof_long=|ac_cv_sizeof_void_p=|ac_cv_sizeof_size_t=|vim_cv_uname_m_output=|ac_cv_func_setitimer=|ac_cv_func_getitimer=|ac_cv_func_sigpending=' "$CACHE" > "$CACHE.nx"
	cat >> "$CACHE.nx" <<-'EOF'
	ac_cv_sizeof_long=8
	ac_cv_sizeof_void_p=8
	ac_cv_sizeof_size_t=8
	vim_cv_uname_m_output=x86_64
	EOF
	# setitimer/getitimer/sigpending are GENUINELY ABSENT from the NanOS libc (not in libc.ndl,
	# not in picolibc/libc-glue — unlike sigaction/alarm/sigsuspend, which are present). On i686
	# autoconf's link probe (real libc.a, absolute relocs) correctly returns "no", so the i686
	# config.h leaves HAVE_SETITIMER/HAVE_SIGPENDING undefined and vim never calls them. On x86_64
	# the toolchain links with --unresolved-symbols=ignore-all, so every AC_CHECK_FUNC link probe
	# "succeeds" — autoconf would FALSELY conclude these exist, vim would compile in calls that
	# resolve to address 0, and it page-faults (vec=0e, rip=0) during the first screen redraw.
	# Record the truth so x86_64's config.h matches i686's: vim uses its alarm()/poll-based paths.
	cat >> "$CACHE.nx" <<-'EOF'
	ac_cv_func_setitimer=no
	ac_cv_func_getitimer=no
	ac_cv_func_sigpending=no
	EOF
	mv "$CACHE.nx" "$CACHE"
	echo "  [pre_configure] reused i686 vim cross-cache (LP64-adjusted) -> $CACHE"
else
	echo "  [pre_configure] WARNING: $CACHE not found — configure will fail cross AC_RUN checks" >&2
fi

# Scrub generated/compiled state (keep the static Makefiles + the adjusted config.cache).
rm -f src/auto/config.status src/auto/config.h src/auto/config.mk \
      src/auto/config.log src/auto/pathdef.c src/auto/osdef.h
find . \( -name '*.o' -o -name '*.a' \) -delete 2>/dev/null || true
rm -f src/vim src/vim.nxe vim.nxe 2>/dev/null || true
[ -d src/objects ] && find src/objects -type f -delete 2>/dev/null || true
echo "  [pre_configure] scrubbed stale i686 build artifacts (kept the static Makefiles)"
