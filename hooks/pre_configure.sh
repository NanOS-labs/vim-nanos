#!/bin/sh
# vim forces its cache to src/auto/config.cache and ignores --cache-file, so seed THAT file with
# the cross-compile answers vim's configure cannot determine without running target programs.
set -e
cd "$STAGE/src"
mkdir -p auto
cp "$SDK/port/config.cache" auto/config.cache
cat >> auto/config.cache <<CACHE
vim_cv_toupper_broken=no
vim_cv_terminfo=yes
vim_cv_tgetent=zero
vim_cv_getcwd_broken=no
vim_cv_stat_ignores_slash=no
vim_cv_memmove_handles_overlap=yes
vim_cv_bcopy_handles_overlap=yes
vim_cv_memcpy_handles_overlap=no
vim_cv_timer_create=no
vim_cv_uname_output=NanOS
vim_cv_uname_r_output=1.0
vim_cv_uname_m_output=i686
ac_cv_sizeof_time_t=8
CACHE
