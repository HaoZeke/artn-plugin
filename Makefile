#
# Makefile for pARTn compilation 
#
# >>> Take care to fill environment_variable before to compile
#


# Load external variable/function
include environment_variables
include .func4makefile


# path to this directory
ART_PATH:=$(realpath .)


default : help


folder-lib:
	@if [ ! -d lib ]; then mkdir lib ; fi


lib : folder-lib
	@$(call check_defined, F90)
	( cd src; $(MAKE); cd - )
	@if [ ! -d lib ]; then mkdir lib ; fi
	ln -sf ../src/libartn.a ./lib/libartn.a
	ln -sf ../src/libartn.so ./lib/libartn.so
	ln -sf ../src/libartn.a ./lib/libartn-qe.a


lmplib: lib
	( cd Files_LAMMPS; $(MAKE) $@ ART_PATH=${ART_PATH}; cd - )

siestalib: lib
	( cd Files_Siesta; $(MAKE); cd - )

patch-qe: lib
	( cd Files_QE; $(MAKE) $@ ART_PATH=${ART_PATH}; cd - )

unpatch-qe:
	( cd Files_QE; $(MAKE) unpatch-qe; cd - )

clean : clean-lmp
	( cd src; $(MAKE) clean; cd - )
	@rm -r lib

clean-lmp:
	( cd Files_LAMMPS; $(MAKE) clean; cd - )

clean-siestalib:
	( cd Files_Siesta; $(MAKE) clean; cd - )



# -------------------------------------------------------------------------- VASP
vasp:  lib
	@$(call check_defined, VASP_PATH)
	cp Files_VASP/ARTn_VASP.F ${VASP_PATH}/src/
	@echo " "; echo " ARTn_VASP.F copied in ${VASP_PATH}/src/"; echo " "
	@echo " WARNING!! "
	@echo " 1. Add ARTn_VASP.o in the ${VASP_PATH}/src/.objects "
	@echo " 2. Include 'CALL ART_VASP(..)' in the ${VASP_PATH}/src/main.F "; echo " "




# ---------------------------------------------
help:
	@echo ""
	@echo "*******************************************************************************"
	@echo "*                    Plugin-ARTn Library "
	@echo "*******************************************************************************"
	@echo ""
	@echo "* WARNNG: Take care to fill the file environment_variables"
	@echo "          before compiling pARTn"
	@echo ""
	@echo "* COMPILATION:"
	@$(call verif_defined, F90)
	@echo "make lib		compile the libartn.a and libartn.so library into lib/ folder"
	@echo "make clean		delete the object files and library from everywhere"
	@echo ""
	@echo ""
	@echo "* LAMMPS Interface:"
	@$(call verif_defined, LAMMPS_PATH)
	@echo "make lmplib		compile dynamic library libartn-lmp.so with plugin interfaces for LAMMPS"
	@echo ""
	@echo "* QE Interface:"
	@$(call verif_defined, QE_PATH)
	@echo "make patch-qe		copy Files_QE/plugin_ext_forces.f90 to QE_PATH/src"
	@echo "make unpatch-qe		delete the changes in plugin_ext_forces.f90 from QE_PATH/src"
	@echo ""
	@echo "* Siesta/lua Interface:"
	@echo "make siestalib    compile partn_lua.so needed for Siesta/lua"
	@echo "make clean-siestalib   delete partn_lua.so and associated files"
	@echo ""
	@echo "* VASP Interface:"
	@$(call verif_defined, VASP_PATH)
	@echo "make vasp    copy Files_VASP/ARTn.F in VASP_PATH/src "
	@echo "make clean-vasp   delete VASP_PATH/src/ARTn.F"
	@echo ""	
	@echo "*******************************************************************************"
	@echo ""
