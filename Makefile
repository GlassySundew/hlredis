# name of produced module
TARGET = redis.hdll

# source files
SRC = redis.c

# compiler
CC = gcc

# IMPORTANT: change this to your hashlink root
HL_PATH ?= ../../src

# hiredis flags via pkg-config (best practice)
HIREDIS_CFLAGS := $(shell pkg-config --cflags hiredis)
HIREDIS_LIBS   := $(shell pkg-config --libs hiredis)

CFLAGS = -O2 -fPIC -shared \
	-I$(HL_PATH) \
	$(HIREDIS_CFLAGS)

LDFLAGS = $(HIREDIS_LIBS)

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f $(TARGET)

.PHONY: all clean