ASFLAGS=-g
LDFLAGS=--nostd
OFFICIAL_DATASET=1

run: all
	./xwrdl

build: all
all: xwrdl

words.s: words.sh
	USE_OFFICIAL=$(OFFICIAL_DATASET) ./words.sh
words.o: words.s
	as $(ASFLAGS) words.s -o words.o
main.o: main.s
	as $(ASFLAGS) main.s -o main.o
raw.o: raw.s
	as $(ASFLAGS) raw.s -o raw.o
xwrdl: main.o words.o raw.o
	ld main.o words.o raw.o $(LDFLAGS) -o xwrdl

clean:
	rm -r words
	rm words.s
	rm *.o
	rm xwrdl

.PHONY: clean build all run
