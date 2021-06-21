# makefile for drug design, for Raspberry Pi

all: dd_serial dd_omp dd_threads # dd_mpi

dd_serial:  dd_serial.cpp
	g++ -o dd_serial dd_serial.cpp

dd_omp: dd_omp.cpp
	g++ -o dd_omp dd_omp.cpp -lm -fopenmp -std=c++11

dd_threads: dd_threads.cpp
	g++ -o dd_threads dd_threads.cpp -lm -std=c++11 -pthread

dd_mpi:  dd_mpi.cpp
	mpiCC -std=c++11 -o dd_mpi dd_mpi.cpp

