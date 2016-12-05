NCC = /usr/local/cuda/bin/nvcc
CC = ${NCC}
EXEC = mandelbrot
FLAGS = --compiler-bindir /home/faculty/cathie/gcc-4.7/bin -O3 -I/usr/local/cuda/include

all: $(EXEC)

mandelbrot: mandelbrot.cu
	$(CC) $(FLAGS) -o $@ mandelbrot.cu $(OBJS)

vecAdd2: vecAdd2.cu
	$(CC) $(FLAGS) -o $@ vecAdd2.cu $(OBJS)

vecAdd3: vecAdd3.cu
	$(CC) $(FLAGS) -o $@ vecAdd3.cu $(OBJS)

vecAdd4: vecAdd4.cu
	$(CC) $(FLAGS) -o $@ vecAdd4.cu $(OBJS)


clean:
	rm -f *.o $(OBJS) $(EXEC)
