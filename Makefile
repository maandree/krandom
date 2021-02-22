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
	cp -- krandom "$(DESTDIR)$(PREFIX)/bin/"

uninstall:
	-rm -f -- "$(DESTDIR)$(PREFIX)/bin/krandom"

clean:
	-rm -r -- krandom *.o

.PHONY: all install uninstall clean
