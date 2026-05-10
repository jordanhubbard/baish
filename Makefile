SHELL := /bin/sh

BAISH_SRC_DIR ?= src
BAISH_BIN := $(BAISH_SRC_DIR)/baish

CC ?= $(shell command -v cc 2>/dev/null || command -v gcc 2>/dev/null || echo cc)
JOBS ?= $(shell sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)

PREFIX ?= $(HOME)/.local
DESTDIR ?=

CONFIGURE_ARGS ?=
CURL_CONFIG ?= curl-config
CURL_CFLAGS ?= $(shell $(CURL_CONFIG) --cflags 2>/dev/null)
CURL_LIBS ?= $(shell $(CURL_CONFIG) --libs 2>/dev/null || printf "%s" "-lcurl")

CONFIGURE_DEPS := \
	$(BAISH_SRC_DIR)/configure \
	$(BAISH_SRC_DIR)/Makefile.in \
	$(BAISH_SRC_DIR)/builtins/Makefile.in \
	$(BAISH_SRC_DIR)/doc/Makefile.in \
	$(BAISH_SRC_DIR)/examples/loadables/Makefile.in \
	$(BAISH_SRC_DIR)/examples/loadables/Makefile.inc.in \
	$(BAISH_SRC_DIR)/examples/loadables/Makefile.sample.in \
	$(BAISH_SRC_DIR)/examples/loadables/perl/Makefile.in \
	$(BAISH_SRC_DIR)/lib/glob/Makefile.in \
	$(BAISH_SRC_DIR)/lib/intl/Makefile.in \
	$(BAISH_SRC_DIR)/lib/malloc/Makefile.in \
	$(BAISH_SRC_DIR)/lib/readline/Makefile.in \
	$(BAISH_SRC_DIR)/lib/sh/Makefile.in \
	$(BAISH_SRC_DIR)/lib/termcap/Makefile.in \
	$(BAISH_SRC_DIR)/lib/tilde/Makefile.in \
	$(BAISH_SRC_DIR)/po/Makefile.in.in \
	$(BAISH_SRC_DIR)/support/Makefile.in

.PHONY: all check-deps configure build run test install uninstall clean distclean help depends release release-minor release-major

all: build

$(BAISH_SRC_DIR)/Makefile: $(CONFIGURE_DEPS)
	cd "$(BAISH_SRC_DIR)" && ./configure $(CONFIGURE_ARGS)

check-deps:
	@tmp_c=$$(mktemp "$${TMPDIR:-/tmp}/baish-curl-check.XXXXXX.c") || exit 1; \
	tmp_bin=$$(mktemp "$${TMPDIR:-/tmp}/baish-curl-check.XXXXXX") || { rm -f "$$tmp_c"; exit 1; }; \
	trap 'rm -f "$$tmp_c" "$$tmp_bin"' EXIT HUP INT TERM; \
	printf "%s\n" "#include <curl/curl.h>" \
		"int main(void) { curl_global_init(CURL_GLOBAL_DEFAULT); curl_global_cleanup(); return 0; }" > "$$tmp_c"; \
	if ! $(CC) $(CURL_CFLAGS) -o "$$tmp_bin" "$$tmp_c" $(CURL_LIBS) >/dev/null 2>&1; then \
		echo "Error: libcurl development headers/libraries are required to build baish."; \
		echo "Run 'make depends' or install libcurl development files manually."; \
		echo "For non-standard locations, pass CURL_CFLAGS=... and CURL_LIBS=..."; \
		exit 1; \
	fi

configure: $(BAISH_SRC_DIR)/Makefile

build: check-deps configure
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
		echo "Installing build dependencies..."; \
		sudo apt-get update && sudo apt-get install -y libcurl4-openssl-dev locales; \
		echo "Generating locales for test suite..."; \
		sudo locale-gen en_US.UTF-8 || true; \
		sudo locale-gen zh_TW.BIG5 || true; \
		sudo locale-gen de_DE.UTF-8 || true; \
		sudo locale-gen fr_FR.ISO-8859-1 || true; \
		sudo locale-gen ja_JP.SJIS || true; \
		sudo update-locale LANG=en_US.UTF-8 || true; \
	elif command -v apt >/dev/null 2>&1; then \
		echo "Detected apt (Debian/Ubuntu/WSL)"; \
		echo "Installing build dependencies..."; \
		sudo apt update && sudo apt install -y libcurl4-openssl-dev locales; \
		echo "Generating locales for test suite..."; \
		sudo locale-gen en_US.UTF-8 || true; \
		sudo locale-gen zh_TW.BIG5 || true; \
		sudo locale-gen de_DE.UTF-8 || true; \
		sudo locale-gen fr_FR.ISO-8859-1 || true; \
		sudo locale-gen ja_JP.SJIS || true; \
		sudo update-locale LANG=en_US.UTF-8 || true; \
	elif command -v brew >/dev/null 2>&1; then \
		echo "Detected brew (macOS)"; \
		brew install curl; \
	elif command -v pkg >/dev/null 2>&1; then \
		echo "Detected pkg (FreeBSD)"; \
		sudo pkg install -y curl; \
	else \
		echo "Error: Could not detect package manager"; \
		echo "Please install libcurl development headers manually:"; \
		echo "  - Debian/Ubuntu/WSL: sudo apt-get install libcurl4-openssl-dev locales"; \
		echo "  - macOS: brew install curl"; \
		echo "  - FreeBSD: sudo pkg install curl"; \
		exit 1; \
	fi
	@echo "Dependencies installed successfully!"

help:
	@printf "%s\n" \
		"Targets:" \
		"  check-deps    Verify build dependencies are available" \
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
