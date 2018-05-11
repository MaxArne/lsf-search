INC=-I./includes
SRC=./sources
objects=

FLAGS= -g -Wall -std=c++11
COMPILER=g++

LIBFCGI=-lfcgi++ -lfcgi

all: main clean

main:
	$(COMPILER) $(FLAGS) $(SRC)/main.cpp $(objects) $(INC) $(LIBFCGI) -o ./bin/main

run:
	./bin/main

clean:
	rm -rf *.o
