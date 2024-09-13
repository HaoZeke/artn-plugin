-include ../make.inc

ART_PATH:=$(TOPDIR)

default: msg

#
# main targets
#
patch-qe: patch-qe-only make-qe
unpatch-qe: unpatch-qe-only make-qe

check_configure:
	@if [ "${with_qe}" != "yes" ]; then echo " ** ERROR :: pARTn not configured with QE"; exit 1; fi

# patch the QE
patch-qe-only : check_configure
	$(call check_defined, QE_PATH)
	$(call check_defined, ART_PATH)
	echo "LIBOBJS += ${ART_PATH}/src/libartn.so" >> ${QE_PATH}/make.inc
	echo "QELIBS += ${ART_PATH}/src/libartn.so" >> ${QE_PATH}/make.inc
	cp ${QE_PATH}/PW/src/plugin_ext_forces.f90 $(ART_PATH)/Files_QE
	cat $(ART_PATH)/Files_QE/PW-src-modified/plugin_ext_forces.f90 > ${QE_PATH}/PW/src/plugin_ext_forces.f90

# unpatch the QE
unpatch-qe-only : check_configure
	$(call check_defined, QE_PATH)
	cp $(ART_PATH)/Files_QE/plugin_ext_forces.f90 ${QE_PATH}/PW/src/plugin_ext_forces.f90
	head -n -2 ${QE_PATH}/make.inc > ${QE_PATH}/make.inc_tmp
	mv ${QE_PATH}/make.inc_tmp ${QE_PATH}/make.inc
	rm ./plugin_ext_forces.f90

# recompile QE
make-qe: check_configure
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
