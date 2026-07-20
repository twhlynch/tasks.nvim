all: build test

build:
	echo "building"

test:
	echo "testing"

clean:
	echo "cleaning"

files := $(wildcard *)

$(files):
	cat $@ | wc -l

.PHONY: $(files) build test clean all
