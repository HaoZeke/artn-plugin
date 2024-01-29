#
# Makefile for pARTn compilation 
#
# >>> Take care to fill environment_variable before to compile
#


# Load external variable/function
include environment_variables
include .func4makefile


# Library Name
LIBLMP:=libartn-lmp.so


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
	( cd Files_LAMMPS; $(MAKE) $@; cd - )

siestalib: lib
	( cd Files_Siesta; $(MAKE); cd - )


clean : clean-lmp
	( cd src; $(MAKE) clean; cd - )
	@rm -r lib

clean-lmp:
	( cd Files_LAMMPS; $(MAKE) clean; cd - )




# -------------------------------------------------------------------------- Quantum ESPRESSO
patch-qe: patch-QE
patch-QE :
	@$(call check_defined, QE_PATH)
	echo "LIBOBJS += ${ART_PATH}/src/libartn.a" >> ${QE_PATH}/make.inc
	echo "QELIBS += ${ART_PATH}/src/libartn.a" >> ${QE_PATH}/make.inc
	cp ${QE_PATH}/PW/src/plugin_ext_forces.f90 Files_QE/.
	cat Files_QE/PW-src-modified/plugin_ext_forces.f90 > ${QE_PATH}/PW/src/plugin_ext_forces.f90

	( cd ${QE_PATH}; $(MAKE) pw; cd - )

unpatch-qe: unpatch-QE
unpatch-QE :
	@$(call check_defined, QE_PATH)
	#sh unpatch-ARTn.sh
	cp Files_QE/plugin_ext_forces.f90 ${QE_PATH}/PW/src/plugin_ext_forces.f90
	head -n -1 ${QE_PATH}/make.inc > ${QE_PATH}/make.inc_tmp
	mv ${QE_PATH}/make.inc_tmp ${QE_PATH}/make.inc
	rm Files_QE/plugin_ext_forces.f90

	( cd ${QE_PATH}; $(MAKE) pw; cd - )




# ---------------------------------------------
help:
	@echo ""
	@echo "*******************************************************************************"
	@echo "*                    Plugin-ARTn Library "
	@echo "*******************************************************************************"
	@echo ""
	@echo "* WARNNG: The user should take care to fill correctly the file environment_variable"
	@echo "          before to compile ARTn"
	@echo ""
	@echo "* COMPILATION:"
	@$(call verif_defined, F90)
	@echo "make lib		compile the libartn.a and libartn.so library in lib/ folder with ${F90} compiler"
	@echo "make clean		delete the object files and library from everywhere"
	@echo ""
	@echo ""
	@echo "* LAMMPS Interface:"
	@$(call verif_defined, LAMMPS_PATH)
	@echo "make lmplib		compile dynamic library libartn-lmp.so with plugin interfaces for LAMMPS"
	@#echo "make patch-lammps	copy the Files_LAMMPS/fix_artn.* and Files_LAMMPS/artn.h to LAMMPS_PATH/src"
	@#echo "make unpatch-lammps	delete the fix_artn.* and artn.h files from  LAMMPS_PATH/src"
	@echo ""
	@echo "* QE Interface:"
	@$(call verif_defined, QE_PATH)
	@echo "make patch-qe		copy Files_QE/plugin_ext_forces.f90 to QE_PATH/src"
	@echo "make unpatch-qe		delete the changes in plugin_ext_forces.f90 from QE_PATH/src"
	@echo ""
	@echo "*******************************************************************************"
	@echo ""
