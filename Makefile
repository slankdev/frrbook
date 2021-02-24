dev: build open

OPEN_TARGET=upstream
open:
	open docs/$(OPEN_TARGET).html
build:
	mdbook build -d docs
