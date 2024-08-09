include ../environment_variables
include ../.func4makefile

default: msg

#
# main targets
#
patch-qe: patch-qe-only make-qe
unpatch-qe: unpatch-qe-only make-qe


# patch the QE
patch-qe-only :
	$(call check_defined, QE_PATH)
	$(call check_defined, ART_PATH)
	echo "LIBOBJS += ${ART_PATH}/src/libartn.so" >> ${QE_PATH}/make.inc
	echo "QELIBS += ${ART_PATH}/src/libartn.so" >> ${QE_PATH}/make.inc
	cp ${QE_PATH}/PW/src/plugin_ext_forces.f90 .
	cat ./PW-src-modified/plugin_ext_forces.f90 > ${QE_PATH}/PW/src/plugin_ext_forces.f90

# unpatch the QE
unpatch-qe-only :
	$(call check_defined, QE_PATH)
	cp ./plugin_ext_forces.f90 ${QE_PATH}/PW/src/plugin_ext_forces.f90
	head -n -1 ${QE_PATH}/make.inc > ${QE_PATH}/make.inc_tmp
	mv ${QE_PATH}/make.inc_tmp ${QE_PATH}/make.inc
	rm ./plugin_ext_forces.f90

# recompile QE
make-qe:
	$(call check_defined, QE_PATH)
	( cd ${QE_PATH}; $(MAKE) pw; cd - )

msg:
	@echo "  Use one of the following:"
	@echo
	@echo " make patch-qe        -> patch QE with pARTn, and recompile QE"
	@echo " make unpatch-qe      -> unpatch QE, and recompile QE"
	@echo " make patch-qe-only   -> patch QE with pARTn, and don't recompile QE"
	@echo " make unpatch-qe-only -> unpatch QE, and don't recompile QE"
	@echo " make make-qe         -> recompile QE"
