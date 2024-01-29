#
# Compile multiple_group and multiple_serial
#

# -- Env_variable
include ../../../environment_variables
ART_PATH := ../../../

# -- VAriables
MPIF := mpif90
FFLAGS := -g -cpp -fcheck=all -Wall -I./ -I${LAMMPS_PATH}/fortran/

API := $(ART_PATH)/interface


# -- Command
default: group #single



group: interface lammps control_flag
	${MPIF} -o multiple_$@.x  ${FFLAGS} multiple_$@.f90 ${API}/f_partn.o ${LAMMPS_PATH}/fortran/lammps.o $(ART_PATH)/lib/libartn-lmp.so ${LAMMPS_PATH}/src/liblammps.so 

single: interface lammps
	${MPIF} -o multiple_$@.x  ${FFLAGS} multiple_$@.f90 ${API}/f_partn.o ${LAMMPS_PATH}/fortran/lammps.o $(ART_PATH)/lib/libartn-lmp.so ${LAMMPS_PATH}/src/liblammps.so 



# dependancies
interface: $(API)/f_partn.o

lammps: ${LAMMPS_PATH}/fortran/lammps.o

control_flag:
	@if [ -n "$(MACOS)" ]; then \
	echo "\nWARNING: Verify if pARTn path is in DYLD_LIBRARY_PATH\n"; fi

# object file
%.o: %.f90
	${MPIF} -c $^ -o $@
	#${F90} -c $^ -o $@


clean:
	rm ${API}/f_partn.o ${LAMMPS_PATH}/fortran/lammps.o multiple_*.x *.mod 
	rm -r multiple_*.x.dSYM
