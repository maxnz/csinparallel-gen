MPI_CC  = mpicc
CC      = gcc
CFLAGS  = -Wall -ansi -pedantic -std=c99

all: small big seq

small: mpi_heat2D.c
	$(MPI_CC) $(CFLAGS) -o heat2D_small mpi_heat2D.c

big: mpi_heat2D_big.c
	$(MPI_CC) $(CFLAGS) -o heat2D_big mpi_heat2D_big.c

seq: seq_heat2D.c seq_time.h
	$(CC) $(CFLAGS) -o seq_heat2D seq_heat2D.c
