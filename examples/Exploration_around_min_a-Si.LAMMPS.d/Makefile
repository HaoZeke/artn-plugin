#
# Compile multiple_group
#

# -- Env_variable
include ../../make.inc

ART_PATH := $(TOPDIR)

# -- VAriables
MPIF := mpif90
FFLAGS := -g -cpp -Wall #-DMPIF08 #-fcheck=all

SRC := $(PWD)
OBJ = $(SRC)/Obj
MOD = -I$(OBJ) -J$(OBJ) -I$(ART_PATH)/src/Obj



MAIN = multiple_group.x

LAMMPSLIB = $(LAMMPS_PATH)/liblammps.so -Wl,-rpath,$(LAMMPS_PATH)
ARTLIB = -Wl,-rpath,$(ART_PATH)/lib $(ART_PATH)/lib/libartn-lmp.so


LIB = $(LAMMPSLIB) $(ARTLIB)

#==============
# object files
fsrc := $(SRC)/multiple_group.f90
osrc := $(patsubst $(SRC)%,$(OBJ)%,$(fsrc:%.f90=%.o))

flmp := $(LAMMPS_PATH)/../fortran/lammps.f90
olmp := $(patsubst $(LAMMPS_PATH)/../fortran%, $(OBJ)%, $(flmp:%.f90=%.o))
#==============

# -- Command
default: group


$(OBJ)/%.o: $(SRC)/%.f90
	$(MPIF) $(FFLAGS) $(MOD) -c $< -o $@
$(OBJ)/lammps.o: $(LAMMPS_PATH)/../fortran/lammps.f90
	$(MPIF) $(FFLAGS) $(MOD) -c $< -o $@



group: $(OBJ) lammps control_flag $(MAIN)


# dependencies
lammps: $(OBJ)/lammps.o

control_flag:
	@if [ -n "$(MACOS)" ]; then \
	echo "\nWARNING: Verify if pARTn path is in DYLD_LIBRARY_PATH\n"; fi

$(OBJ):
	@if [ ! -d $(OBJ) ]; then mkdir $(OBJ) ; fi




$(MAIN): $(olmp) $(osrc)
	$(MPIF) $(FFLAGS) $(MOD) $^ -o $(SRC)/$@ $(LIB)


clean:
	rm -rf $(OBJ)
	rm -rf $(MAIN)
