CC=gcc-7
OMP=-fopenmp

all:  coinFlip_omp coinFlip_seq


coinFlip_seq: coinFlip_seq.c seq_time.h
	${CC} -o coinFlip_seq coinFlip_seq.c

coinFlip_omp: coinFlip_omp_seeds.c
	${CC} ${OMP} -o coinFlip_omp coinFlip_omp_seeds.c

clean:
	rm -f coinFlip_omp coinFlip_seq
