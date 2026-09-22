CC      ?= cc
CFLAGS  := -std=c11 -Wall -Wextra -Werror -O2 $(EXTRA_CFLAGS)
LDFLAGS := $(EXTRA_LDFLAGS)

all: build/test_sum

build/test_sum: src/sum.c tests/test_sum.c
	@mkdir -p build
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

test: build/test_sum
	./build/test_sum

clean:
	rm -rf build

.PHONY: all test clean
