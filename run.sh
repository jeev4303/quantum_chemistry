!#/bin/sh
module load fftw/3.3.8/gcc-5.4.0-openmpi-n5dpv4g
mpirun -np 8 ~/qe-6.4.1/bin/pw.x <optimised-scf.in |tee optimised-scf.out
mpirun -np 8 ~/qe-6.4.1/bin/pw.x <optimised-nscf.in |tee optimised-nscf.out
mpirun -np 8 ~/qe-6.4.1/bin/dos.x <dos.in |tee dos.out
mpirun -np 8 ~/qe-6.4.1/bin/projwfc.x <projwfc.in |tee projwfc.out


