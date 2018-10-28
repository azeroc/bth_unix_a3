# Tutorial: http://nuclear.mutantstargoat.com/articles/make/
# == == == Configuration logic == == ==
BISON = bison
FLEX = flex
CC = gcc
AR = ar

LEXYACC_SRCDIR = lexyacc-code
SRCDIR = src
BUILD_DIR = build
LIBDIR = lib
BINDIR = bin

SRCS = $(wildcard $(SRCDIR)/*.c)
OBJS = $(patsubst $(SRCDIR)/%.c, $(BUILD_DIR)/%.o, $(SRCS))
CFLAGS = -Wall -g
ARFLAGS = rcs

# == == == Makefile logic == == ==

# Default make target
all: calc3 calc3libs test

calc3: $(BINDIR)/calc3a.exe $(BINDIR)/calc3b.exe $(BINDIR)/calc3g.exe $(BINDIR)/calc3i.exe

calc3libs: $(LIBDIR)/libfact.a $(LIBDIR)/libgcd.a $(LIBDIR)/liblntwo.a $(LIBDIR)/libmyprint.a

test: $(BUILD_DIR)/test.o
	$(CC) $(CFLAGS) $(BUILD_DIR)/test.o -o $(BINDIR)/test

# Generalized calc3 .exe compiling from calc3 prog's .c file and lexyacc_dep dependencies
$(BINDIR)/%.exe: $(LEXYACC_SRCDIR)/%.c lexyacc_dep
	$(CC) $(CFLAGS) -I$(BUILD_DIR) $(BUILD_DIR)/y.tab.o $(BUILD_DIR)/lex.yy.o $< -o $@

# Generalized .a library compiling from .o objects
$(LIBDIR)/lib%.a: $(BUILD_DIR)/%.o
	$(AR) $(ARFLAGS) $@ $<

# Generalized .o file compiling .s from src dir
$(BUILD_DIR)/%.o: $(SRCDIR)/%.s
	$(CC) $(CFLAGS) -c $< -o $@

# Bunch of manual compile commands for compiling lexyacc dependencies with 'bison' and 'flex' commands
lexyacc_dep:	
	bison -y -d $(LEXYACC_SRCDIR)/calc3.y -o $(BUILD_DIR)/y.tab.c
	$(FLEX) -o $(BUILD_DIR)/lex.yy.c $(LEXYACC_SRCDIR)/calc3.l 
	$(CC) $(CFLAGS) -I$(LEXYACC_SRCDIR) -c $(BUILD_DIR)/y.tab.c -o $(BUILD_DIR)/y.tab.o
	$(CC) $(CFLAGS) -I$(LEXYACC_SRCDIR) -c $(BUILD_DIR)/lex.yy.c -o $(BUILD_DIR)/lex.yy.o

# Non-file targets (.PHONY)
.PHONY: clean
clean:
	rm -f -v $(LIBDIR)/*
	rm -f -v $(BUILD_DIR)/*
	rm -f -v $(BINDIR)/*