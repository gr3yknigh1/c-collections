.PHONY: default all main clean veryclean format format-source format-tests

MKDIR  = mkdir -p
REMOVE = rm -rf

CC     = clang
CFLAGS = -std=c2x
CFLAGS += -Werror
CFLAGS += -Wall
CFLAGS += -Wextra
CFLAGS += -Wpedantic
CFLAGS += -Wuninitialized
CFLAGS += -Wmissing-include-dirs
CFLAGS += -Wshadow
CFLAGS += -Wundef
CFLAGS += -Warc-repeated-use-of-weak
CFLAGS += -Wbitfield-enum-conversion
CFLAGS += -Wconditional-uninitialized
CFLAGS += -Wthread-safety
CFLAGS += -Wconversion
CFLAGS += -Wswitch -Wswitch-enum
CFLAGS += -Wformat-security
CFLAGS += -Wdouble-promotion
CFLAGS += -Wfloat-equal
CFLAGS += -Wfloat-overflow-conversion
CFLAGS += -Wfloat-zero-conversion
CFLAGS += -Wsign-compare
CFLAGS += -Wsign-conversion

AR      = ar
ARFLAGS = -cvrs

PROJECT_NAME = cboxes

PROJECT_DIR = $(CURDIR)

INCLUDE_DIR = $(PROJECT_DIR)/include
SOURCES_DIR = $(PROJECT_DIR)/src
BUILD_DIR   = $(PROJECT_DIR)/build
TESTS_DIR   = $(PROJECT_DIR)/tests

LIBRARY     = $(BUILD_DIR)/lib$(PROJECT_NAME).a

OBJ_DIR       = $(BUILD_DIR)/objs
TESTS_BIN_DIR = $(BUILD_DIR)/tests

TESTS_SOURCES = $(wildcard $(TESTS_DIR)/*.c)
TESTS_BINS    = $(patsubst $(TESTS_DIR)/%.c, $(TESTS_BIN_DIR)/%, $(TESTS_SOURCES))

SOURCES = $(wildcard $(SOURCES_DIR)/*.c)
HEADERS = $(wildcard $(INCLUDE_DIR)/**/*.h)
OBJS    = $(patsubst $(SOURCES_DIR)/%.c, $(OBJ_DIR)/%.o, $(SOURCES))

INCLUDE_FLAGS = -I$(INCLUDE_DIR)

FORMATTER = clang-format
FORMATTER_FLAGS = -i

CLANG_TIDY = clang-tidy
CLANG_TIDY_FLAGS = -header-filter=.*

TARGETS = $(LIBRARY)

all: debug

debug: CFLAGS += -g -O0 -D__DEBUG_MODE__
debug: $(TARGETS)

release: CFLAGS += -O3 -D__RELEASE__MODE__
release: clean
release: $(TARGETS)

asan: CFLAGS += -fsanitize=address -fno-optimize-sibling-calls -fno-omit-frame-pointer

lsan: CFLAGS += -fsanitize=leak

msan: CFLAGS += -fsanitize=memory -fno-optimize-sibling-calls -fno-omit-frame-pointer

ubsan: CFLAGS += -fsanitize=undefined

clean:
	$(REMOVE) $(BUILD_DIR)

$(LIBRARY): $(BUILD_DIR) $(OBJ_DIR) $(OBJS)
	$(RM) $(LIBRARY)
	$(AR) $(ARFLAGS) $(LIBRARY) $(OBJS)

$(BUILD_DIR):
	$(MKDIR) $@

$(OBJ_DIR):
	$(MKDIR) $@

$(OBJ_DIR)/%.o: $(SOURCES_DIR)/%.c $(INCLUDE_DIR)/$(PROJECT_NAME)/%.h
	$(CLANG_TIDY) $(CLANG_TIDY_FLAGS) $<
	$(CC) $(CFLAGS) -c $< -o $@ $(INCLUDE_FLAGS)

$(OBJ_DIR)/%.o: $(SOURCES_DIR)/%.c
	$(CLANG_TIDY) $(CLANG_TIDY_FLAGS) $<
	$(CC) $(CFLAGS) -c $< -o $@ $(INCLUDE_FLAGS)


tests: $(LIBRARY) $(TESTS_BIN_DIR) $(TESTS_BINS)
	@for test in $(TESTS_BINS); do $$test ; done

$(TESTS_BIN_DIR)/%: $(TESTS_DIR)/%.c
	$(CLANG_TIDY) $(CLANG_TIDY_FLAGS) $<
	$(CC) $(CFLAGS) $< $(OBJS) -o $@ -lcriterion $(INCLUDE_FLAGS)

$(TESTS_BIN_DIR):
	$(MKDIR) $@

checks:
	sh ./scripts/run_sanitazers.sh

install:
	@echo todo

# Formatting
format-source:
	$(FORMATTER) $(FORMATTER_FLAGS) $(SOURCES)
	$(FORMATTER) $(FORMATTER_FLAGS) $(HEADERS)

format-tests:
	$(FORMATTER) $(FORMATTER_FLAGS) $(TESTS_SOURCES)

format: format-source format-tests

# Testing executable
TESTING_DIR = $(PROJECT_DIR)/testing
TESTING_SRC = $(TESTING_DIR)/testing.c
TESTING_OUT = $(BUILD_DIR)/testing

$(TESTING_OUT): $(LIBRARY)
	$(RM) $(TESTING_OUT)
	$(CC) $(CFLAGS) $(TESTING_SRC) $< -o $@ -I$(INCLUDE_DIR)

testing: $(TESTING_OUT)

run: testing
	$(TESTING_OUT)

