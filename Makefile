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



.PHONY: clean
clean:
	-rm -r bin obj

