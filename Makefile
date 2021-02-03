dev: build open

OPEN_TARGET=bgp_struct_index
open:
	open book/$(OPEN_TARGET).html
build:
	mdbook build --open
