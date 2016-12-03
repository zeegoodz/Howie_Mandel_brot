NCC = /usr/local/cuda/bin/nvcc
CC = ${NCC} 
EXEC = vecAdd1 vecAdd2 vecAdd3 vecAdd4
FLAGS = --compiler-bindir /home/faculty/cathie/gcc-4.7/bin -O3 -I/usr/local/cuda/include

all: $(EXEC)

vecAdd1: vecAdd1.cu 
	$(CC) $(FLAGS) -o $@ vecAdd1.cu $(OBJS)

vecAdd2: vecAdd2.cu 
	$(CC) $(FLAGS) -o $@ vecAdd2.cu $(OBJS)

vecAdd3: vecAdd3.cu 
	$(CC) $(FLAGS) -o $@ vecAdd3.cu $(OBJS)

vecAdd4: vecAdd4.cu 
	$(CC) $(FLAGS) -o $@ vecAdd4.cu $(OBJS)


clean: 
	rm -f *.o $(OBJS) $(EXEC)
