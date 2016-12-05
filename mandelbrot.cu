
/************************************\
| filename: escape.c
|
| description: sequential version
| of code that outputs a .PGM file of
| a Mandelbrot fractal.
|
| notes: the number of pixels, 2400x2400
| was chosen so that it would take a fair
| amount of time to compute the image so
| that speedup may be observed on in a parallel
| implementation.  it might be advisable
| to change the #defines for the purposes
| of developing a parallel version of the
| code.
|
| hint: the file output is a .PGM file which
| is viewable with the linux utility gimp.
| The 'convert' utility can convert
| from .pgm to .gif, which will save lots of disk
| space.
|
| authors: Bryan Schlief, Daegon Kim, Wim Bohm
|
\***********************************/


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "timer.h"
#include <cuda.h>

#define   RADIUS_SQ  4.0     /* 2^2                              */
#define   X_RANGE    2400    /* # of pixels wide                 */
#define   Y_RANGE    2400    /* # of pixels high                 */

/*  helper function written to create a .pgm file,        */
/*  which is viewable with the program /usr/local/bin/xv  */
/*  alternately you can use /usr/bin/convert to convert   */
/*  the file from .pgm to any other file format           */
/*  type: convert seq_output.pgm seq_output.gif           */

static void HandleError( cudaError_t err, const char *file, int line) {

	if (err != cudaSuccess){
		printf("%s in %s at line %d\n", cudaGetErrorString(err), file, line);
		exit (EXIT_FAILURE);
	}
}

#define HANDLE_ERROR(err)(HandleError(err, __FILE__, __LINE__))


void writePGM (char * filename, int * data, int width, int height);

__global__ void mandelbrotRUN(double MAX_ITER, char* outfilename, int* output){

  int i,j;                            /* index variables */

   int  counter;                       /* measures the "speed" at which   */
                                       /* a particular point diverges.    */

   double real_max, real_min,
          imag_max, imag_min;          /* varibles that define the 'c' plane; */

   double real_range, imag_range;      /* distance per pixel */

   double c_real, c_imag,              /* c and z variables  */
          z_real, z_imag, z_magnitude; /* for inner for loop */

   double z_current_real;              /* temporary variable that holds the value */
                                       /* of z_real for the calculation of z_imag  */

   real_min = 0.3129928802767, real_max =  0.31299305009252;  /* define the 'c' plane */
   imag_min = 0.0345483210604, imag_max =  0.0345485012278;   /* you can change these for fun */

   real_range = (real_max - real_min) / (X_RANGE - 1);
   imag_range = (imag_max - imag_min) / (Y_RANGE - 1);

   for(i=0; i<Y_RANGE; ++i) {
      for(j=0; j<X_RANGE; ++j) {

        c_real = real_min + i * real_range;
        c_imag = imag_min + j * imag_range;

        z_real = 0.0;
        z_imag = 0.0;

        for(counter = 0; counter < MAX_ITER; ++counter) {
           z_current_real = z_real;

           z_real = (z_real * z_real) - (z_imag * z_imag) + c_real;
           z_imag = (2.0 * z_current_real * z_imag) + c_imag;

           z_magnitude = (z_real * z_real) + (z_imag * z_imag);

           if(z_magnitude > RADIUS_SQ) {
              break;
           }
        }  //end for

        output[i*X_RANGE+j] = (int)floor(((double)(255 * counter)) / (double)MAX_ITER);
      } // end for
   } // end for

}

int main(int argc, char ** argv) {


	// parse command line arguments
	if ( argc < 4 ) {
		printf("Usage : %s SIZE PERTHREAD BLOCKSIZE ITERATIONS\n", argv[0]);
		exit(0);
	}

	int size = atoi(argv[1]);
	int perThread = atoi(argv[2]);
	int blockSize = atoi(argv[3]);

   double MAX_ITER = atoi(argv[4]);    /* first command line argument... */

	/* allocate memory to store output values for pixels */
    int * output = (int*) malloc(sizeof(int) * X_RANGE * Y_RANGE);
	int *d_output;

	HANDLE_ERROR(cudaMalloc((void**)&d_output,sizeof(int)*X_RANGE*Y_RANGE));
    char * outfilename = "Mandelbrot.pgm";  /* the sequential output filename */
    double time; 	/*timer*/
	cudaEvent_t start, stop;
	HANDLE_ERROR(cudaEventCreate(&start));
	HANDLE_ERROR(cudaEventCreate(&stop));
	HANDLE_ERROR(cudaEventRecord(start, 0));

	//need more in here I think
	//E.G vecAdd4.cu Line 76-85

	int calcPerBlock = blockSize*perThread;
	int numBlocks = size/calcPerBlock;
	if(size%calcPerBlock); numBlocks++;

   mandelbrotRUN<<<numBlocks, blockSize>>>(MAX_ITER, outfilename, d_output );

   HANDLE_ERROR(cudaMemcpy(output, d_output, sizeof(int)*X_RANGE*Y_RANGE, cudaMemcpyDeviceToHost));

   HANDLE_ERROR(cudaEventRecord(stop, 0));
   HANDLE_ERROR(cudaEventSynchronize(stop));
  // HANDLE_ERROR(cudaEventElaspedTime(&time, start, stop));


   /* write the pgm file to the file specified */
   /* in the first command line argument.      */
   writePGM(outfilename, output, X_RANGE, Y_RANGE);

   free(output);

   return 0;
}


void writePGM (char * filename, int * data, int width, int height) {
   int i, j;    /* index variables */
   int max=-1;  /* for pgm file output */

   /* PGM file format requires the largest */
   /* pixel value.  Calculate this.        */
   for(i=0; i<width*height; ++i) {
      if (data[i] > max) {
         max = data[i];
      }
   }

   /* open the file for writing. omit error checking. */
   FILE * fout = fopen(filename, "w");

   /* PGM file header */
   fprintf(fout, "P2\n");
   fprintf(fout, "%d\t%d\n", width, height);
   fprintf(fout, "%d\n",max);

   /* throw out the data */
   for(i=0; i<height; ++i) {
      for(j=0; j<width; ++j) {
         fprintf(fout, "%d\t", data[i*width+j]);
      }
      fprintf(fout,"\n");
   }

   /* flush the buffer and close the file */
   fflush(fout);
   fclose(fout);
}
