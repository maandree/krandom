# Copyright © 2014  Mattias Andrée (maandree@member.fsf.org)
# 
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
# 
# [GNU All Permissive License]


# The package path prefix, if you want to install to another root, set DESTDIR to that root
PREFIX = /usr
# The command path excluding prefix
BIN = /bin
# The resource path excluding prefix
DATA = /share
# The command path including prefix
BINDIR = $(PREFIX)$(BIN)
# The resource path including prefix
DATADIR = $(PREFIX)$(DATA)
# The generic documentation path including prefix
DOCDIR = $(DATADIR)/doc
# The man page documentation path including prefix
MANDIR = $(DATADIR)/man
# The info manual documentation path including prefix
INFODIR = $(DATADIR)/info
# The license base path including prefix
LICENSEDIR = $(DATADIR)/licenses

# The name of the package as it should be installed
PKGNAME = krandom
# The name of the command as it should be installed
COMMAND = krandom


WARN = -Wall -Wextra -pedantic -Wdouble-promotion -Wformat=2 -Winit-self -Wmissing-include-dirs  \
       -Wtrampolines -Wfloat-equal -Wshadow -Wmissing-prototypes -Wmissing-declarations          \
       -Wredundant-decls -Wnested-externs -Winline -Wno-variadic-macros -Wswitch-default         \
       -Wpadded -Wsync-nand -Wunsafe-loop-optimizations -Wcast-align -Wstrict-overflow           \
       -Wdeclaration-after-statement -Wundef -Wbad-function-cast -Wcast-qual -Wlogical-op        \
       -Wstrict-prototypes -Wold-style-definition -Wpacked -Wvector-operation-performance        \
       -Wunsuffixed-float-constants -Wsuggest-attribute=const -Wsuggest-attribute=noreturn       \
       -Wsuggest-attribute=pure -Wsuggest-attribute=format -Wnormalized=nfkc

LDOPTIMISE =
COPTIMISE = -O3

FLAGS = $(WARN) -std=gnu99



.PHONY: default
default: command shell doc

.PHONY: all
all: command shell info


.PHONY: command
command: bin/krandom

bin/%: obj/%.o
	@mkdir -p bin
	$(CC) $(FLAGS) $(LDOPTIMISE) -lkeccak -largparser -o $@ $^ $(LDFLAGS)

obj/%.o: src/%.c
	@mkdir -p obj
	$(CC) $(FLAGS) $(COPTIMISE) -c -o $@ $< $(CFLAGS) $(CPPFLAGS)


.PHONY: shell
shell: bash zsh fish

.PHONY: bash
bash: bin/$(COMMAND).bash

.PHONY: zsh
zsh: bin/$(COMMAND).zsh

.PHONY: fish
fish: bin/$(COMMAND).fish

bin/%.bash: src/completion
	@mkdir -p bin
	auto-auto-complete bash --output $@ --source $< command="$*"

bin/%.zsh: src/completion
	@mkdir -p bin
	auto-auto-complete zsh --output $@ --source $< command="$*"

bin/%.fish: src/completion
	@mkdir -p bin
	auto-auto-complete fish --output $@ --source $< command="$*"


.PHONY: doc
doc: info pdf dvi ps

.PHONY: info
info: bin/krandom.info
bin/%.info: info/%.texinfo info/fdl.texinfo
	@mkdir -p obj bin
	cd obj ; makeinfo ../$<
	mv obj/$*.info bin/$*.info

.PHONY: pdf
pdf: bin/krandom.pdf
bin/%.pdf: info/%.texinfo info/fdl.texinfo
	@mkdir -p obj bin
	cd obj ; yes X | texi2pdf ../$<
	mv obj/$*.pdf bin/$*.pdf

.PHONY: dvi
dvi: bin/krandom.dvi
bin/%.dvi: info/%.texinfo info/fdl.texinfo
	@mkdir -p obj bin
	cd obj ; yes X | $(TEXI2DVI) ../$<
	mv obj/$*.dvi bin/$*.dvi

.PHONY: ps
ps: bin/krandom.ps
bin/%.ps: info/%.texinfo info/fdl.texinfo
	@mkdir -p obj bin
	cd obj ; yes X | texi2pdf --ps ../$<
	mv obj/$*.ps bin/$*.ps



.PHONY: install
install: install-base install-shell install-info

.PHONY: install-all
install-all: install-base install-shell install-doc

.PHONY: install-base
install-base: install-command install-copyright


.PHONY: install-command
install-command: bin/krandom
	install -dm755 -- "$(DESTDIR)$(BINDIR)"
	install -m755 -- $< "$(DESTDIR)$(BINDIR)/$(COMMAND)"


.PHONY: install-copyright
install-copyright: install-copying install-license

.PHONY: install-copying
install-copying:
	install -dm755 -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	install -m644 -- COPYING "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/COPYING"

.PHONY: install-license
install-license:
	install -dm755 -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	install -m644 -- LICENSE "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/LICENSE"


.PHONY: install-shell
install-shell: install-bash install-fish install-zsh

.PHONY: install-bash
install-bash: bin/$(COMMAND).bash
	install -dm755 -- "$(DESTDIR)$(DATADIR)/bash-completion/completions"
	install -m644 -- $< "$(DESTDIR)$(DATADIR)/bash-completion/completions/$(COMMAND)"

.PHONY: install-fish
install-fish: bin/$(COMMAND).fish
	install -dm755 -- "$(DESTDIR)$(DATADIR)/fish/completions"
	install -m644 -- $< "$(DESTDIR)$(DATADIR)/fish/completions/$(COMMAND).fish"

.PHONY: install-zsh
install-zsh: bin/$(COMMAND).zsh
	install -dm755 -- "$(DESTDIR)$(DATADIR)/zsh/site-functions"
	install -m644 -- $< "$(DESTDIR)$(DATADIR)/zsh/site-functions/_$(COMMAND)"


.PHONY: install-doc
install-doc: install-info install-pdf install-dvi install-ps

.PHONY: install-info
install-info: bin/krandom.info
	install -dm755 -- "$(DESTDIR)$(INFODIR)"
	install -m644 -- $< "$(DESTDIR)$(INFODIR)/$(PKGNAME).info"

.PHONY: install-pdf
install-pdf: bin/krandom.pdf
	install -dm755 -- "$(DESTDIR)$(DOCDIR)"
	install -m644 -- $< "$(DESTDIR)$(DOCDIR)/$(PKGNAME).pdf"

.PHONY: install-dvi
install-dvi: bin/krandom.dvi
	install -dm755 -- "$(DESTDIR)$(DOCDIR)"
	install -m644 -- $< "$(DESTDIR)$(DOCDIR)/$(PKGNAME).dvi"

.PHONY: install-ps
install-ps: bin/krandom.ps
	install -dm755 -- "$(DESTDIR)$(DOCDIR)"
	install -m644 -- $< "$(DESTDIR)$(DOCDIR)/$(PKGNAME).ps"



.PHONY: uninstall
uninstall:
	-rm -- "$(DESTDIR)$(BINDIR)/$(COMMAND)"
	-rm -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/COPYING"
	-rm -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/LICENSE"
	-rmdir -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	-rm -- "$(DESTDIR)$(DATADIR)/bash-completion/completions/$(COMMAND)"
	-rm -- "$(DESTDIR)$(DATADIR)/fish/completions/$(COMMAND).fish"
	-rm -- "$(DESTDIR)$(DATADIR)/zsh/site-functions/_$(COMMAND)"
	-rm -- "$(DESTDIR)$(MANDIR)/man1/$(COMMAND).1"
	-rm -- "$(DESTDIR)$(INFODIR)/$(PKGNAME).info"
	-rm -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).pdf"
	-rm -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).dvi"
	-rm -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).ps"



.PHONY: clean
clean:
	-rm -r bin obj

