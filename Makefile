#
# Makefile for pARTn compilation 
#
#

# Load external variable/function
-include make.inc




default : help


folder-lib:
	@if [ ! -d lib ]; then mkdir lib ; fi


lib : folder-lib
	@$(call check_defined, F90)
	( cd src && $(MAKE) && cd - )
	@if [ ! -d lib ]; then mkdir lib ; fi
	ln -sf ../src/libartn.a ./lib/libartn.a
	ln -sf ../src/libartn.so ./lib/libartn.so
	ln -sf ../src/libartn.a ./lib/libartn-qe.a


lmplib: lib
	( cd Files_LAMMPS && $(MAKE) $@ && cd - )

siestalib: lib
	( cd Files_Siesta && $(MAKE) && cd - )

patch-qe: lib
	( cd Files_QE && $(MAKE) patch-qe-only && cd - )

unpatch-qe:
	( cd Files_QE && $(MAKE) unpatch-qe && cd - )

patch-vasp: lib
	( cd Files_VASP && $(MAKE) patch-vasp-only && cd - )

unpatch-vasp:
	( cd Files_VASP && $(MAKE) unpatch-vasp-only && cd - )

clean : clean-lmp clean-siestalib
	@( cd src; $(MAKE) clean; cd - )

veryclean: clean
	@rm -rf lib make.inc

clean-lmp:
	@( cd Files_LAMMPS; $(MAKE) clean; cd - )

clean-siestalib:
	@( cd Files_Siesta; $(MAKE) clean; cd - )





# ---------------------------------------------
help:
	@echo ""
	@echo "*******************************************************************************"
	@echo "*                    Plugin-ARTn Library "
	@echo "*******************************************************************************"
	@echo ""
	@echo " ** NOTE: Launch the configure script with appropriate arguments,"
	@echo "          and follow the instructions on screen:"
	@echo ""
	@echo " ./configure --with-<engine> <ENGINE>_PATH=/path/to/engine"
	@echo ""
	@echo ""
	@echo " ** pARTn library compilation: **"
	@echo " ./configure"
	@echo " make lib                compile the libartn.a and libartn.so library into lib/ folder"
	@echo " make clean              delete the object files and library from everywhere"
	@echo " make veryclean          delete the configure file make.inc"
	@echo ""
	@echo ""
	@echo " ** Engine interfaces: **"
	@echo ""
	@echo " ** LAMMPS: **"
	@echo " ./configure --with-lammps LAMMPS_PATH=<your_path>"
	@echo " make lmplib             compile libartn-lmp.so with plugin interfaces for LAMMPS"
	@echo ""
	@echo " ** Quantum Espresso: **"
	@echo " ./configure --with-qe QE_PATH=<your_path>"
	@echo " make patch-qe           copy Files_QE/plugin_ext_forces.f90 to QE_PATH/src"
	@echo " make unpatch-qe         delete the changes in plugin_ext_forces.f90 from QE_PATH/src"
	@echo ""
	@echo " ** Siesta/lua: **"
	@echo " ./configure --with-siesta SIESTA_PATH=<your_path>"
	@echo " make siestalib          compile partn_lua.so needed for Siesta/lua"
	@echo " make clean-siestalib    delete partn_lua.so and associated files"
	@echo ""
	@echo " ** VASP: ** "
	@echo " ./configure --with-vasp VASP_PATH=<your_path>"
	@echo " make patch-vasp         copy Files_VASP/ARTN_VASP.F to VASP_PATH/src, modify associated files "
	@echo " make unpatch-vasp       delete VASP_PATH/src/ARTN_VASP.F, modify associated files"
	@echo ""
	@echo "*******************************************************************************"
	@echo ""
