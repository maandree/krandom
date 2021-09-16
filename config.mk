PREFIX    = /usr
MANPREFIX = $(PREFIX)/share/man

CC = cc

CPPFLAGS  = -D_DEFAULT_SOURCE -D_BSD_SOURCE -D_XOPEN_SOURCE=700
CFLAGS    = -std=c99 -Wall -O3
LDFLAGS   = -s -lkeccak

# krandom is seeded by /dev/urandom (Linux's non-blocking random number generator),
# this can be changed by adding -DURANDOM=??? to CPPFLAGS, where ??? is the file
# to use instead of /dev/urandom.
