/*
 *  sequential 2D heat example derived from MPI version.
 *
 *  Author: Libby Shoop
 */
 // #include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include "seq_time.h"

#define NXPROB      512                 /* x dimension of problem grid */
#define NYPROB      512                 /* y dimension of problem grid */
#define STEPS       200                /* number of time steps */

struct Parms {
  float cx;
  float cy;
} parms = {0.1, 0.1};

int main (int argc, char *argv[])
{
  void inidat(), prtdat(), update();
  float  u[2][NXPROB][NYPROB];        /* array for grid */
  // int	taskid,                     /* this task's unique id */
	// numworkers,                 /* number of worker processes */
	// numtasks,                   /* number of tasks/processes */
	// averow,rows,offset,extra,   /* for sending rows of data */
	// dest, source,               /* to - from for message send-receive */
	// left,right,               /* neighbor tasks */
	// msgtype,                    /* for message types */
	// rc,                       /*  return code from abort*/
  // start,end,               /* rows of work for each process */
	// i,ix,iy,iz,it;              /* loop variables */

  int iz, it;

  double startTime = 0.0, totalTime = 0.0;   // LS for timing

  int nx, ny, steps;          /* x,y dim of grid and number of steps*/

  // LS get command line args and update
  if (argc > 3) {
    nx = atoi(argv[1]);
    ny = atoi(argv[2]);
    steps = atoi(argv[3]);
    printf("Sizes used: nx, ny, steps: %d, %d, %d\n", nx, ny, steps);
  } else {
    printf("Default sizes used: NXPROB, NYPROB, STEPS: %d, %d, %d\n", NXPROB, NYPROB, STEPS);
    nx = NXPROB;
    ny = NYPROB;
    steps = STEPS;
  }

  // printf("Initializing grid and writing initial.dat file...\n");
  inidat(nx, ny, u);
  // prtdat(NXPROB, NYPROB, u, "initial.dat");


  startTime = c_get_wtime();

  iz = 0;
  for (it = 1; it <= steps; it++)
  {
    /* Now call update to update the value of grid points */
    // update(start,end,NYPROB,&u[iz][0][0],&u[1-iz][0][0]);
    update(0,nx-1,ny,&u[iz][0][0],&u[1-iz][0][0]);
    iz = 1 - iz;
  }

  totalTime = c_get_wtime() - startTime;
  printf("\nTime: %f secs.\n\n", totalTime);

}

/**************************************************************************
 *  subroutine update
 ****************************************************************************/
void update(int start, int end, int ny, float *u1, float *u2)
{
   int ix, iy;
   for (ix = start; ix <= end; ix++)
      for (iy = 1; iy <= ny-2; iy++)
         *(u2+ix*ny+iy) = *(u1+ix*ny+iy)  +
                          parms.cx * (*(u1+(ix+1)*ny+iy) +
                          *(u1+(ix-1)*ny+iy) -
                          2.0 * *(u1+ix*ny+iy)) +
                          parms.cy * (*(u1+ix*ny+iy+1) +
                         *(u1+ix*ny+iy-1) -
                          2.0 * *(u1+ix*ny+iy));
}

/*****************************************************************************
 *  subroutine inidat
 *****************************************************************************/
void inidat(int nx, int ny, float *u) {
int ix, iy;

for (ix = 0; ix <= nx-1; ix++)
  for (iy = 0; iy <= ny-1; iy++)
     *(u+ix*ny+iy) = (float)(ix * (nx - ix - 1) * iy * (ny - iy - 1));
}

/**************************************************************************
 * subroutine prtdat
 **************************************************************************/
void prtdat(int nx, int ny, float *u1, char *fnam) {
int ix, iy;
FILE *fp;

fp = fopen(fnam, "w");
for (iy = ny-1; iy >= 0; iy--) {
  for (ix = 0; ix <= nx-1; ix++) {
    fprintf(fp, "%8.1f", *(u1+ix*ny+iy));
    if (ix != nx-1)
      fprintf(fp, " ");
    else
      fprintf(fp, "\n");
    }
  }
fclose(fp);
}
