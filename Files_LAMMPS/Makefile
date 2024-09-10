#
# Makefile for LAMMPS interface
#

# Load the environment variable
include ../make.inc

# Library Name
LIBLMP:=libartn-lmp.so

LIBLAMMPS := $(shell if [ -n "${MACOS}" ]; then echo "${LAMMPS_PATH}/src/liblammps.so" ; fi )




STUBS:=$(if $(findstring mpi, ${CXX}),,-I${LAMMPS_PATH}/STUBS)

default: lmplib



## ----- Plugin for lammps (After lammps2022)
lmplib: lammps
	@echo "\n>>>> Shared library link..."
	ln -sf $(TOPDIR)/Files_LAMMPS/$(LIBLMP) $(TOPDIR)/lib/$(LIBLMP)
	@echo "\n>>>> Shared library $(LIBLMP) is in: $(TOPDIR)/lib/\n"
	@echo " 1) In LAMMPS, package PLUGIN must be configured: 'make yes-plugin'"
	@echo " 2) LAMMPS must be compiled in shared mode: 'make mode=shared <machine>'"
	@echo " 3) To launch LAMMPS, lammps/src path should be loaded in LD_LIBRARY_PATH"
	@echo " 4) Load the 'fix artn' with LAMMPS command:"
	@echo "        'plugin load $(TOPDIR)/lib/$(LIBLMP)'"
	@echo " 5) Enjoy ;) "
	@echo ""


lammps:
	@echo "\n>>>> environment variable verification"
	@$(call check_defined, CXX)
	@$(call check_defined, LAMMPS_PATH)
	@$(call check_defined, FORT_LIB)
	@echo "<<<< OK "; echo ""
	@echo cxx is: "${CXX}"
	$(CXX) -fPIC -I${LAMMPS_PATH} ${STUBS} -c fix_artn.cpp -o fix_artn.o
	$(CXX) -fPIC -I${LAMMPS_PATH} ${STUBS} -c artnplugin.cpp -o artnplugin.o
	@echo "\n>>>> Shared library build..."
	${CXX} -shared -rdynamic -o  ./$(LIBLMP)  $(TOPDIR)/src/Obj/*.o  ./*.o  $(FORT_LIB) $(BLAS_LIB)  $(LIBLAMMPS) 


## ----- Copy fix files in lammps (Before lammps2022)
patch-lammps:
	@$(call check_defined, LAMMPS_PATH)
	@cp Files_LAMMPS/*artn.*  ${LAMMPS_PATH}
	@echo " ***** File artnplugin.cpp copied"
	@echo " ***** You have to compile LAMMPS before useing it"

unpatch-lammps:
	@$(call check_defined, LAMMPS_PATH)
	@rm ${LAMMPS_PATH}/fix_artn.* ${LAMMPS_PATH}/artn.h
	@echo " ***** Fix/artn files removed from $LAMMPS_PATH/src"
	@echo " ***** You have to compile LAMMPS to have the effect"


clean:
	@rm -rf *.o *.so $(TOPDIR)/lib/$(LIBLMP)



