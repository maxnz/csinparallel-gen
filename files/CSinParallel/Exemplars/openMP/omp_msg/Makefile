CC=gcc-7
OMP=-fopenmp
DEBUG=-DDEBUG
#DEBUG=

all_mp: omp_msgps omp_msglk

omp_msgps: omp_msgps.c queue.c queue.h
	$(CC) $(DEBUG) -Wall $(OMP) -o omp_msgps omp_msgps.c queue.c

omp_msglk:
	$(CC) $(DEBUG) -Wall $(OMP) -o omp_msglk omp_msglk.c queue_lk.c

queue_test: queue.c queue.h
	$(CC) -g -Wall -DUSE_MAIN -o queue queue.c

queue_lk_test: queue_lk.c queue_lk.h
	$(CC) -g -Wall -DUSE_MAIN -fopenmp -o queue_lk queue_lk.c

clean:
	rm -f omp_msgps omp_msglk queue queue_lk
