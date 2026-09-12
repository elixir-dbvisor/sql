# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 DBVisor

ERTS_INCLUDE_DIR ?= $(shell erl -noshell -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])]), init:stop().')

CFLAGS ?= -O3 -fPIC
CFLAGS += -I"$(ERTS_INCLUDE_DIR)"

LDFLAGS ?= -shared
ifeq ($(shell uname -s),Darwin)
    LDFLAGS += -undefined dynamic_lookup
endif

MODULES = atomic_term atomic_queue bitset
TARGETS = $(addprefix priv/,$(addsuffix .so,$(MODULES)))

.PHONY: all clean

all: $(TARGETS)

priv:
	@mkdir -p priv

priv/%.so: c_src/%.c | priv
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

clean:
	@rm -rf priv
