PREFIX ?= /usr/local

.PHONY: build install uninstall clean

build:
	swift build -c release

install: build
	install -d $(PREFIX)/bin
	install .build/release/nosleepclub $(PREFIX)/bin/nosleepclub

uninstall:
	rm -f $(PREFIX)/bin/nosleepclub

clean:
	swift package clean
