
CC = gcc
CFLAGS =
LFLAGS = -fopenmp -lm

VERSIONS := $(shell ls trap-omp-*.c | sed 's/omp-\(.*\).c$'/\1/') 

all:  $(VERSIONS)

trap-%: trap-omp-%.c
	$(CC) -o trap-$* trap-omp-$*.c $(LFLAGS)
	
clean:
	rm -f a.out $(VERSIONS)

