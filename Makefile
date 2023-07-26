#!/usr/bin/make -f
draft = sexp
OUTPUT = $(draft).txt $(draft).html $(draft).xml

all: $(OUTPUT)

%.xml: %.md
	kramdown-rfc2629 --v3 $< > $@.tmp
	mv $@.tmp $@

%.html: %.xml
	xml2rfc --v3 $< --html

%.txt: %.xml
	xml2rfc --v3 $< --text

%.pdf: %.xml
	xml2rfc --v3 $< --pdf

clean:
	-rm -rf $(OUTPUT) *.tmp

check: codespell trailing-whitespace

codespell:
	codespell $(draft).md

trailing-whitespace:
	! grep -n '[[:space:]]$$' $(draft).md

.PHONY: clean all check codespell
