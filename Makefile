INC=-I./includes -I/usr/local/lib
SRC=./sources
objects=

FLAGS= -g -Wall  -std=c++11
COMPILER=g++

LIBFCGI=-lfcgi++ -lfcgi
LIBCTEMPLATE=-lctemplate

all: buildDir main clean

main:
	$(COMPILER) $(FLAGS) $(SRC)/main.cpp $(objects) $(INC) $(LIBFCGI) $(LIBCTEMPLATE) -o ./bin/main

run:
	./bin/main

clean:
	rm -rf *.o

buildDir:
	if [ ! -d ./bin ]; then mkdir ./bin; fi
