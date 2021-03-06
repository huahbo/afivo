Instructions for compiling the code
=====

QUICK guide: on an up-to-date system with gfortran, simply type 'make' in the
Afivo directory to compile afivo and the examples.

If you want to compile with runtime checks (useful for debugging) and profiling
options, then do:

$ make clean

$ make DEBUG=1

More information
=====

Afivo requirements:
* Fortran 2008 compatible compiler (gfortran >= 4.8 has been tested)
* C/C++ compiler for compiling Silo (see below).

A recent version of the Intel compiler ifort *should* in also work, however, I've
had some problems with them (reporting wrong error message, not being up-to-date
with the F2008 standard, crashes). You can try this with

$ make COMPILER=ifort

Afivo has one dependency: Silo. The script build_silo.sh automatically
downloads, configures and compiles Silo into your afivo directory. If this
fails, then you should probably download, configure and install Silo yourself.
If you really do not want to use Silo (Afivo also supports .vtu output), you
could remove the Silo routines.
