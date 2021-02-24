dev: build open

OPEN_TARGET=upstream
open:
	open book/$(OPEN_TARGET).html
build:
	mdbook build -d docs
