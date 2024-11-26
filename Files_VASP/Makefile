-include ../make.inc

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
	cp ARTn_VASP.F ${VASP_PATH}/src/                      # Add ARTn_VASP.F into VASP/src/ directory
	if grep -q "ARTn_VASP.o" $VASP_PATH/src/.objects      # Add the ARTn_VASP.o into the VASP/src/.objects file at 2 places if not already there
	then
		echo "ARTn_VASP.o already in objects."  
	else
		echo "ARTn_Vasp.o not set, adding..."  
		n1="`grep -n  -m 1 dmatrix.o ${VASP_PATH}/src/.objects | cut -d : -f 1`"
		n2="`grep -n  -m 2 dmatrix.o ${VASP_PATH}/src/.objects | cut -d : -f 1 |tail -1`"
		sed -i "${n1}i\\\tARTn_VASP.o \\\\" ${VASP_PATH}/src/.objects 
		sed -i "${n2}i\\\tARTn_VASP.o \\\\" ${VASP_PATH}/src/.objects 
	fi
	if grep -q "libartn.a" $VASP_PATH/makefile.include    # Add the needed library lines into the makefile.include
	then
		echo "LIBS and INCS already set."  
	else
		echo "LIBS not set, adding..."  
		echo "LLIBS +=${ARTN_PATH}/lib/libartn.a" >>  ${VASP_PATH}/makefile.include 
		echo "INCS  +=-I${ARTN_PATH}/src/Obj/"    >>  ${VASP_PATH}/makefile.include 
	fi
	if grep -q "ARTN_VASP" ${VASP_PATH}/src/main.F        # Add the CALL ARTn into the main of VASP
	then
		echo "CALL ARTN_VASP already into the main.F, not adding it again"  
	else
		echo "CALL ARTN_VASP not in the main.F, adding this line above CALL PARALLEL_TEMPERING..."  
		sed -i '/PARALLEL_TEMPERING*/i \ \ \ \ \ \ CALL ARTN_VASP( TIFOR, TOTEN, T_INFO, INFO, DYN, LATT_CUR, NSTEP, IO)' ${VASP_PATH}/src/main.F 
	fi

# unpatch the VASP
unpatch-vasp-only : check_configure
	$(call check_defined, VASP_PATH)
	rm ${VASP_PATH}/src/ARTn_VASP.F                       # Remove ARTn_VASP.F from VASP/src/ directory
	sed -i.bak '/ARTn_VASP.o/d' ${VASP_PATH}/src/.objects # Remove ARTn_VASP.o from VASP/src/.objects
	sed -i.bak '/ARTN_VASP/d' ${VASP_PATH}/src/main.F     # Remove CALL ARTN_VASP from VASP/src/main.F
	head -n -2 ${VASP_PATH}/makefile.include > ${VASP_PATH}/makefile.include_tmp # Remove ARTn library lines from the makefile.include
	mv ${VASP_PATH}/makefile.include_tmp ${VASP_PATH}/makefile.include

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
