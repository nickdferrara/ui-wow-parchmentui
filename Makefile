LUA ?= lua5.1
SOURCES := ParchmentUI tests
PACKAGER_URL := https://raw.githubusercontent.com/BigWigsMods/packager/v2/release.sh

.PHONY: check lint format format-check test toc-check package

check: lint format-check test toc-check

lint:
	luacheck $(SOURCES)

format:
	stylua $(SOURCES)

format-check:
	stylua --check $(SOURCES)

test:
	busted

toc-check:
	$(LUA) tests/TocCheck.lua

# -d skips uploads, so this only builds the zip into .release/.
package:
	curl -fsSL $(PACKAGER_URL) | bash -s -- -d
