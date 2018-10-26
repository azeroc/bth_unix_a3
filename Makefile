# Tutorial: http://nuclear.mutantstargoat.com/articles/make/
# == == == Configuration logic == == ==
BISON = bison
FLEX = flex
CC = gcc

LEXYACC_SRCDIR = lexyacc-code
SRCDIR = src
BUILD_DIR = build
BINDIR = bin

SRCS = $(wildcard $(SRCDIR)/*.c)
OBJS = $(patsubst $(SRCDIR)/%.c, $(BUILD_DIR)/%.o, $(SRCS))
CFLAGS = -Wall

# == == == Makefile logic == == ==

# Default make target
all: calc3

# I can't be bothered to make generalized solution for lexyacc stuff, so here is some simple hardcoded makefile logic for compiler building
calc3: calc3a.exe calc3b.exe calc3g.exe

calc3a.exe: lexyacc_dep
	$(CC) -I$(BUILD_DIR) $(BUILD_DIR)/y.tab.o $(BUILD_DIR)/lex.yy.o $(LEXYACC_SRCDIR)/calc3a.c -o $(BINDIR)/calc3a.exe

calc3b.exe: lexyacc_dep
	$(CC) -I$(BUILD_DIR) $(BUILD_DIR)/y.tab.o $(BUILD_DIR)/lex.yy.o $(LEXYACC_SRCDIR)/calc3b.c -o $(BINDIR)/calc3b.exe

calc3g.exe: lexyacc_dep
	$(CC) -I$(BUILD_DIR) $(BUILD_DIR)/y.tab.o $(BUILD_DIR)/lex.yy.o $(LEXYACC_SRCDIR)/calc3g.c -o $(BINDIR)/calc3g.exe

calc3i.exe: lexyacc_dep
	$(CC) -I$(BUILD_DIR) $(BUILD_DIR)/y.tab.o $(BUILD_DIR)/lex.yy.o $(LEXYACC_SRCDIR)/calc3i.c -o $(BINDIR)/calc3i.exe

lexyacc_dep:	
	bison -y -d $(LEXYACC_SRCDIR)/calc3.y -o $(BUILD_DIR)/y.tab.c
	$(FLEX) -o $(BUILD_DIR)/lex.yy.c $(LEXYACC_SRCDIR)/calc3.l 
	gcc -I$(LEXYACC_SRCDIR) -c $(BUILD_DIR)/y.tab.c -o $(BUILD_DIR)/y.tab.o
	gcc -I$(LEXYACC_SRCDIR) -c $(BUILD_DIR)/lex.yy.c -o $(BUILD_DIR)/lex.yy.o

# Non-file targets (.PHONY)
.PHONY: clean
clean:
	rm -f -v $(BUILD_DIR)/*
	rm -rf -v $(BINDIR)/*