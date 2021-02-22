.POSIX:

CONFIGFILE = config.mk
include $(CONFIGFILE)

all: krandom

krandom: krandom.o
	$(CC) -o $@ krandom.o $(LDFLAGS)

krandom.o: krandom.c arg.h
	$(CC) -c -o $@ krandom.c $(CFLAGS) $(CPPFLAGS)

install: krandom
	mkdir -p -- "$(DESTDIR)$(PREFIX)/bin"
	mkdir -p -- "$(DESTDIR)$(MANPREFIX)/man1"
	cp -- krandom "$(DESTDIR)$(PREFIX)/bin/"
	cp -- krandom.1 "$(DESTDIR)$(MANPREFIX)/man1/"

uninstall:
	-rm -f -- "$(DESTDIR)$(PREFIX)/bin/krandom"
	-rm -f -- "$(DESTDIR)$(MANPREFIX)/man1/krandom.1"

clean:
	-rm -r -- krandom *.o

.PHONY: all install uninstall clean
