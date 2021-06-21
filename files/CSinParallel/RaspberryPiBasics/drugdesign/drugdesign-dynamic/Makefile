# makefile for drug design, for Raspberry Pi

OBJ = drugdesign-dynamic

CC = g++
CFLAGS = -Wall -pedantic -std=c++11 
LFLAGS = -o $(OBJ) -lm -fopenmp

$(OBJ): $(OBJ).cpp
	$(CC) $(CFLAGS) $(OBJ).cpp $(LFLAGS)

clean:
	rm -f a.out $(OBJ)
