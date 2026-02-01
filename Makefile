SHELL := /bin/sh

BAISH_SRC_DIR ?= src
BAISH_BIN := $(BAISH_SRC_DIR)/baish

JOBS ?= $(shell sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)

PREFIX ?= $(HOME)/.local
DESTDIR ?=

CONFIGURE_ARGS ?=

.PHONY: all configure build run test install uninstall clean distclean help depends release release-minor release-major

all: build

$(BAISH_SRC_DIR)/Makefile: $(BAISH_SRC_DIR)/configure
	cd "$(BAISH_SRC_DIR)" && ./configure $(CONFIGURE_ARGS)

configure: $(BAISH_SRC_DIR)/Makefile

build: configure
	$(MAKE) -C "$(BAISH_SRC_DIR)" -j$(JOBS)

run: build
	"$(BAISH_BIN)" $(RUN_ARGS)

test: build
	$(MAKE) -C "$(BAISH_SRC_DIR)" tests

install: build
	install -d "$(DESTDIR)$(PREFIX)/bin"
	install -m 0755 "$(BAISH_BIN)" "$(DESTDIR)$(PREFIX)/bin/baish"

uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/bin/baish"

clean:
	-$(MAKE) -C "$(BAISH_SRC_DIR)" clean
	-rm -rf .tmp-*

distclean:
	-$(MAKE) -C "$(BAISH_SRC_DIR)" distclean
	-rm -rf .tmp-*

depends:
	@echo "Installing build dependencies..."
	@if command -v apt-get >/dev/null 2>&1; then \
		echo "Detected apt-get (Debian/Ubuntu/WSL)"; \
		sudo apt-get update && sudo apt-get install -y libcurl4-openssl-dev; \
	elif command -v apt >/dev/null 2>&1; then \
		echo "Detected apt (Debian/Ubuntu/WSL)"; \
		sudo apt update && sudo apt install -y libcurl4-openssl-dev; \
	elif command -v brew >/dev/null 2>&1; then \
		echo "Detected brew (macOS)"; \
		brew install curl; \
	elif command -v pkg >/dev/null 2>&1; then \
		echo "Detected pkg (FreeBSD)"; \
		sudo pkg install -y curl; \
	else \
		echo "Error: Could not detect package manager"; \
		echo "Please install libcurl development headers manually:"; \
		echo "  - Debian/Ubuntu/WSL: sudo apt-get install libcurl4-openssl-dev"; \
		echo "  - macOS: brew install curl"; \
		echo "  - FreeBSD: sudo pkg install curl"; \
		exit 1; \
	fi
	@echo "Dependencies installed successfully!"

help:
	@printf "%s\n" \
		"Targets:" \
		"  depends       Install build dependencies (requires sudo)" \
		"  build         Configure (if needed) and build baish" \
		"  run           Run baish (pass args via RUN_ARGS=...)" \
		"  test          Run baish tests (bash test suite)" \
		"  install       Install baish to $(DESTDIR)$(PREFIX)/bin" \
		"  clean         Clean build outputs" \
		"  distclean     Remove configure outputs (requires reconfigure)" \
		"  release       Create a patch release (X.Y.Z-baish.B+1)" \
		"  release-minor Create a minor release (X.Y+1.0-baish.1)" \
		"  release-major Create a major release (X+1.0.0-baish.1)"

release:
	@echo "Creating patch release..."
	@./scripts/release.sh patch

release-minor:
	@echo "Creating minor release..."
	@./scripts/release.sh minor

release-major:
	@echo "Creating major release..."
	@./scripts/release.sh major
