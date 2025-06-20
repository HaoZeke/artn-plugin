-include ../../make.inc

ART_PATH:=$(TOPDIR)

default: msg

#
# main targets
#
patch-vasp: patch-vasp-only make-vasp
unpatch-vasp: unpatch-vasp-only make-vasp

check_configure:
	@if [ "${with_vasp}" != "yes" ]; then echo " ** ERROR :: pARTn not configured with VASP"; exit 1; fi

# patch the VASP
patch-vasp-only : check_configure
	$(call check_defined, VASP_PATH)
	$(call check_defined, ART_PATH)
	@echo " Copying ARTn_VASP.F into ${VASP_PATH}/src";\
	cp ARTn_VASP.F ${VASP_PATH}/src/ARTn_VASP.F
	@if grep -q "ARTn_VASP.o" ${VASP_PATH}/src/.objects ; then \
		echo " ARTn_VASP.o already in objects."; \
	else \
		echo " ARTn_Vasp.o not set, adding..."  ;\
		n1="`grep -n  -m 1 dmatrix.o ${VASP_PATH}/src/.objects | cut -d : -f 1`";\
		n2="`grep -n  -m 2 dmatrix.o ${VASP_PATH}/src/.objects | cut -d : -f 1 |tail -1`";\
		sed -i "${n1}i\\\tARTn_VASP.o \\\\" ${VASP_PATH}/src/.objects ;\
		sed -i "${n2}i\\\tARTn_VASP.o \\\\" ${VASP_PATH}/src/.objects ;\
	fi
	@if grep -q "lartn" ${VASP_PATH}/makefile.include; then \
		echo " LIBS and INCS already set." ; \
	else \
		echo " LIBS not set, adding..."  ;\
		echo "LLIBS +=-L${ART_PATH}/src -lartn -Wl,-rpath,${ART_PATH}/src" >>  ${VASP_PATH}/makefile.include;\
		echo "INCS  +=-I${ART_PATH}/src/Obj/"    >>  ${VASP_PATH}/makefile.include;\
	fi
	@if grep -qE "[^\!]*ARTN_VASP" ${VASP_PATH}/src/main.F; then \
		echo " CALL ARTN_VASP already in the ${VASP_PATH}/src/main.F";\
	else \
		echo " CALL ARTN_VASP not found in ${VASP_PATH}/src/main.F, adding it above CALL PARALLEL_TEMPERING..";\
		sed -i '/PARALLEL_TEMPERING*/i \ \ \ \ \ \ CALL ARTN_VASP( TIFOR, TOTEN, T_INFO, INFO, DYN, LATT_CUR, NSTEP, IO)' ${VASP_PATH}/src/main.F ;\
	fi
	@echo " :: VASP patched successfully."

# unpatch the VASP
unpatch-vasp-only : check_configure
	$(call check_defined, VASP_PATH)
	@echo " Removing ARTn_VASP.F from ${VASP_PATH}/src/ directory"
	@rm -f ${VASP_PATH}/src/ARTn_VASP.F
	@echo " Removing ARTn_VASP.o from ${VASP_PATH}/src/.objects"
	@sed -i.bak '/ARTn_VASP.o/d' ${VASP_PATH}/src/.objects 
	@echo " Removing CALL ARTN_VASP from ${VASP_PATH}/src/main.F"
	@sed -i.bak '/ARTN_VASP/d' ${VASP_PATH}/src/main.F     
	@echo " Removing ARTn library lines from the ${VASP_PATH}/makefile.include"
	@head -n -2 ${VASP_PATH}/makefile.include > ${VASP_PATH}/makefile.include_tmp 
	@mv ${VASP_PATH}/makefile.include_tmp ${VASP_PATH}/makefile.include
	@echo " :: VASP unpatched successfully."

# recompile vasp
make-vasp: check_configure
	$(call check_defined, VASP_PATH)
	( cd ${VASP_PATH}; $(MAKE) std; cd - )

msg:
	@echo "  Use one of the following:"
	@echo
	@echo " make patch-vasp        -> patch VASP with pARTn, and recompile VASP"
	@echo " make unpatch-vasp      -> unpatch VASP, and recompile VASP"
	@echo " make patch-vasp-only   -> patch VASP with pARTn, and don't recompile VASP"
	@echo " make unpatch-vasp-only -> unpatch VASP, and don't recompile VASP"
	@echo " make make-vasp         -> recompile VASP"
