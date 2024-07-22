#
# Makefile for LAMMPS interface
#

# Load the environment variable
include ../environment_variables
include ../.func4makefile

# Library Name
LIBLMP:=libartn-lmp.so

LIBLAMMPS := $(shell if [ -n "${MACOS}" ]; then echo "${LAMMPS_PATH}/src/liblammps.so" ; fi )



default: lmplib



## ----- Plugin for lammps (After lammps2022)
lmplib: lammps
	@echo "\n>>>> Shared library link..."
	ln -sf ../Files_LAMMPS/$(LIBLMP) ../lib/$(LIBLMP)
	@echo "\n>>>> Shared library $(LIBLMP) is in lib/\n"
	@echo " 1) In LAMMPS Package PLUGIN must be loaded"
	@echo " 2) LAMMPS must be compiled with mode=shared"
	@echo " 3) To launch LAMMPS, lammps/src path should be loaded in LD_LIBRARY_PATH"
	@echo " 4) Enjoy ;) "
	@echo ""


lammps:
	@echo "\n>>>> environment_variable verification"
	@$(call check_defined, CXX)
	@$(call check_defined, LAMMPS_PATH)
	@$(call check_defined, FORT_LIB)
	@$(call check_defined, BLAS_LIB)
	@$(call check_defined, BLAS_LIB)
	@echo "<<<< OK "; echo ""
	@echo cxx is: "${CXX}"
	@if  echo "${CXX}" | grep -q "mpi" ; then \
	$(CXX) -fPIC -c fix_artn.cpp -o fix_artn.o -I${LAMMPS_PATH}/src; \
	$(CXX) -fPIC -c artnplugin.cpp -o artnplugin.o -I${LAMMPS_PATH}/src; \
	else \
	$(CXX) -fPIC -c fix_artn.cpp -o fix_artn.o -I${LAMMPS_PATH}/src -I${LAMMPS_PATH}/src/STUBS; \
	$(CXX) -fPIC -c artnplugin.cpp -o artnplugin.o -I${LAMMPS_PATH}/src -I${LAMMPS_PATH}/src/STUBS; \
	fi
	@echo "\n>>>> Shared library build..."
	${CXX} -shared -rdynamic -o  ./$(LIBLMP)  ../src/Obj/*.o  ./*.o  $(FORT_LIB) $(BLAS_LIB)  $(LIBLAMMPS) 


## ----- Copy fix files in lammps (Before lammps2022)
patch-lammps:
	@$(call check_defined, LAMMPS_PATH)
	@cp Files_LAMMPS/*artn.*  ${LAMMPS_PATH}/src/
	@echo " ***** File artnplugin.cpp copied"
	@echo " ***** You have to compile LAMMPS before useing it"

unpatch-lammps:
	@$(call check_defined, LAMMPS_PATH)
	@rm ${LAMMPS_PATH}/src/fix_artn.* ${LAMMPS_PATH}/src/artn.h
	@echo " ***** Fix/artn files removed from $LAMMPS_PATH/src"
	@echo " ***** You have to compile LAMMPS to have the effect"


clean:
	rm *.o *.so ../lib/$(LIBLMP)



