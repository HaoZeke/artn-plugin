AC_DEFUN([ARCH_COMPILERS], [
# candidate fortran compilers good for all cases
try_mpif90="mpifort mpif90"
try_f90="gfortran f90"

# candidate compilers and flags based on architecture
case $arch in
ia32 | ia64 | x86_64 )
        dnl try_f90="ifx ifort nvfortran pgf90 nagfor $try_f90"
        dnl try_mpif90="mpiifx mpiifort $try_mpif90"
        try_f90="$try_f90 ifx ifort nvfortran pgf90 nagfor"
        try_mpif90="$try_mpif90 mpiifx mpiifort"

        ;;
arm )
        dnl try_f90="nvfortran pgf90 armflang $try_f90"
        try_f90="$try_f90 nvfortran pgf90 armflang"
        ;;
craype* )
        try_f90="ftn"
        try_mpif90="ftn"
        ;;
mac686 | cygwin )
        dnl try_f90="ifort $try_f90"
        try_f90="$try_f90 ifort"
        ;;
mingw* )
        ld="$F90"
        # this is set for C/C++, but we need it for Fortran, too.
        try_dflags="-D_WIN32"
        ;;
necsx )
        # most likely the following generates a bug
        sxopt=`echo $host|awk '{print substr($1,1,3)}'`
        echo $sxopt $host
        try_mpif90="sxmpif90"
        try_f90="sxf90"
        try_dflags='-D__SX6 '
        # use_fft_asl=0
        # use_fft_mathkeisan=1
        # use_fft_para=0
# default for Nec: no parallel unless explicitly required
        dnl if test "$set_use_parallel" -ne 1 ; then use_parallel=0 ; fi
        dnl if test "$use_parallel" -eq 1 ; then use_fft_para=1 ; fi
        # try_dflags_fft_asl='-DASL'
        # try_dflags_fft_mathkeisan=' '
        # try_dflags_fft_para='-D__USE_3D_FFT'
        ;;
ppc64 )
        try_mpif90="mpxlf90_r mpf90_r mpif90"
        try_f90="xlf90_r $try_f90"
        ;;
# PowerPC little endian
ppc64le )
        try_mpif90="$try_mpif90 mpixlf"
        try_f90="xlf90_r"
        ;;
# IBM BlueGene - obsolete
ppc64-bg | ppc64-bgq )
	dnl if test "$use_openmp" -eq 0 ; then
  dnl         try_mpif90="mpixlf90"
  dnl         try_f90="bgxlf90"
	dnl else
          try_mpif90="mpixlf90_r"
          # Executable paths are usually consistent across several 
          # IBM BG/P BG/Q machine deployed 
          ld="/bgsys/drivers/ppcfloor/comm/xl.ndebug/bin/mpixlf90_r"
          try_f90="bgxlf90_r"
	dnl fi
        try_arflags="ruv"
        ;;
* )
        AC_MSG_WARN($arch : unsupported architecture?)
        ;;
esac


])
