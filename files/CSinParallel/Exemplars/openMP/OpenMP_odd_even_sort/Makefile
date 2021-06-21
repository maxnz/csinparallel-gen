CC=gcc-7
DEBUG=-DDEBUG
#DEBUG=
OMP=-fopenmp

all: seq_odd_even omp_odd_even1 omp_odd_even2

seq_odd_even: odd_even.c seq_time.h
	$(CC) $(DEBUG) -o seq_odd_even odd_even.c

omp_odd_even1: omp_odd_even1.c
	$(CC) $(DEBUG) $(OMP) -o omp_odd_even1 omp_odd_even1.c

omp_odd_even2: omp_odd_even2.c
	$(CC) $(DEBUG) $(OMP) -o omp_odd_even2 omp_odd_even2.c

clean:
	rm -f omp_odd_even1 omp_odd_even2 seq_odd_even
