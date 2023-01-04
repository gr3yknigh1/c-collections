MKDIR  = mkdir -p
REMOVE = rm -rf

CC     = clang
CFLAGS = -g -Wall -std=c17

MKFILE_PATH = $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  = $(dir $(MKFILE_PATH))

PROJECT_NAME      = c-collections

PROJECT_DIRECTORY = $(MKFILE_DIR:-=)

INCLUDE_DIRECTORY = $(PROJECT_DIRECTORY)include
BUILD_FOLDER      = $(PROJECT_DIRECTORY)build
SOURCE_DIRECTORY  = $(PROJECT_DIRECTORY)src
TESTS_FOLDER      = $(PROJECT_DIRECTORY)tests

LIBRARY           = $(BUILD_FOLDER)/libccollections.a

OBJ_FOLDER        = $(BUILD_FOLDER)/objs
TESTS_BIN_FOLDER  = $(BUILD_FOLDER)/tests

TESTS_SOURCES     = $(wildcard $(TESTS_FOLDER)/*.c)
TESTS_BINS        = $(patsubst $(TESTS_FOLDER)/%.c, $(TESTS_BIN_FOLDER)/%, $(TESTS_SOURCES))

SOURCES           = $(wildcard $(SOURCE_DIRECTORY)/*.c)
HEADERS           = $(wildcard $(SOURCE_DIRECTORY)/*.h)
OBJS              = $(patsubst $(SOURCE_DIRECTORY)/%.c, $(OBJ_FOLDER)/%.o, $(SOURCES))


FORMATTER = clang-format
FORMATTER_FLAGS = -i


default: all
all: $(LIBRARY)

release: CFLAGS=-Wall -O3 -DNDEBUG
release: clean
release: $(LIBRARY)


$(LIBRARY): $(BUILD_FOLDER) $(OBJ_FOLDER) $(OBJS)
	$(RM) $(LIBRARY)
	ar -cvrs $(LIBRARY) $(OBJS)

$(BUILD_FOLDER):
	$(MKDIR) $@

$(OBJ_FOLDER):
	$(MKDIR) $@

$(OBJ_FOLDER)/%.o: $(SOURCE_DIRECTORY)/%.c $(INCLUDE_DIRECTORY)/$(PROJECT_NAME)/%.h
	$(CC) $(CFLAGS) -c $< -o $@ -I$(INCLUDE_DIRECTORY)

$(OBJ_FOLDER)/%.o: $(SOURCE_DIRECTORY)/%.c
	$(CC) $(CFLAGS) -c $< -o $@ -I$(INCLUDE_DIRECTORY)


$(TESTS_BIN_FOLDER)/%: $(TESTS_FOLDER)/%.c
	$(CC) $(CFLAGS) $< $(OBJS) -o $@ -lcriterion -I$(INCLUDE_DIRECTORY)

tests: $(LIBRARY) $(TESTS_BIN_FOLDER) $(TESTS_BINS)
	for test in $(TESTS_BINS); do $$test ; done

$(TESTS_BIN_FOLDER):
	$(MKDIR) $@


clean veryclean:
	$(REMOVE) $(BUILD_FOLDER)

format-source:
	$(FORMATTER) $(FORMATTER_FLAGS) $(SOURCES)
	$(FORMATTER) $(FORMATTER_FLAGS) $(HEADERS)

format-tests:
	$(FORMATTER) $(FORMATTER_FLAGS) $(TESTS_SOURCES)

format: format-source format-tests

.PHONY: default, all, main, clean

