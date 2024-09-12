#
# Compile multiple_group
#

# -- Env_variable
include ../../../make.inc
ART_PATH := $(TOPDIR)

# -- VAriables
MPIF := mpif90
FFLAGS := -g -cpp -Wall #-DMPIF08 #-fcheck=all

SRC = $(PWD)
OBJ = $(SRC)/Obj
MOD = -I$(OBJ) -J$(OBJ) -I$(ART_PATH)/src/Obj

MAIN = single.x
MAIN_MULTI = multiple.x
MAIN_MULTIGROUP = multiple_group.x

LAMMPSLIB = $(LAMMPS_PATH)/liblammps.so -Wl,-rpath,$(LAMMPS_PATH)
ARTLIB = $(ART_PATH)/lib/libartn-lmp.so -Wl,-rpath,$(ART_PATH)/lib

LIB = $(LAMMPSLIB) $(ARTLIB)

#==============
# object files
fsrc := $(SRC)/single.f90
osrc := $(patsubst $(SRC)%,$(OBJ)%,$(fsrc:%.f90=%.o))

multi_fsrc := $(SRC)/multiple.f90
multi_osrc := $(patsubst $(SRC)%,$(OBJ)%,$(multi_fsrc:%.f90=%.o))

multigroup_fsrc := $(SRC)/multiple_group.f90
multigroup_osrc := $(patsubst $(SRC)%,$(OBJ)%,$(multigroup_fsrc:%.f90=%.o))

flmp := $(LAMMPS_PATH)/../fortran/lammps.f90
olmp := $(patsubst $(LAMMPS_PATH)/../fortran%, $(OBJ)%, $(flmp:%.f90=%.o))
#==============

# -- Command
default: help


$(OBJ)/%.o: $(SRC)/%.f90
	$(MPIF) $(FFLAGS) $(MOD) -c $< -o $@
$(OBJ)/%.o: $(LAMMPS_PATH)/../fortran/%.f90
	$(MPIF) $(FFLAGS) $(MOD) -c $< -o $@


single: $(OBJ) lammps control_flag $(MAIN)
multiple: $(OBJ) lammps $(MAIN_MULTI)
multiple_group: $(OBJ) lammps $(MAIN_MULTIGROUP)
all: single multiple multiple_group

help:
	@echo :: use one of the following:
	@echo ":: make single         --  for single-cpu program"
	@echo ":: make multiple       --  for mpi"
	@echo ":: make multiple_group --  for mpi split into groups"
	@echo ":: make all            -- all of the above"

# dependencies
lammps: $(OBJ)/lammps.o

control_flag:
	@if [ -n "$(MACOS)" ]; then \
	echo "\nWARNING: Verify if pARTn path is in DYLD_LIBRARY_PATH\n"; fi

$(OBJ):
	@if [ ! -d $(OBJ) ]; then mkdir $(OBJ) ; fi




$(MAIN): $(olmp) $(osrc)
	$(MPIF) $(FFLAGS) $(MOD) $^ -o $(SRC)/$@ $(LIB)

$(MAIN_MULTI): $(olmp) $(multi_osrc)
	$(MPIF) $(FFLAGS) $(MOD) $^ -o $(SRC)/$@ $(LIB)

$(MAIN_MULTIGROUP): $(olmp) $(multigroup_osrc)
	$(MPIF) $(FFLAGS) $(MOD) $^ -o $(SRC)/$@ $(LIB)


clean:
	rm -rf $(OBJ)
	rm -rf $(MAIN)
	rm -rf $(MAIN_MULTI)
	rm -rf $(MAIN_MULTIGROUP)
