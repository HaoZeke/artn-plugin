
-include ../make.inc

#SRC := $(TOPDIR)/src
SRC := .
OBJ := Obj
#OBJ := $(SRC)/Obj
LIBARTN_PATH := $(TOPDIR)/lib
LIBARTN_STATIC := libartn.a
LIBARTN_SHARED := libartn.so
LIBARTN_SONAME := artn

LIB_OBJECTS := \
	    $(OBJ)/m_artn_info.o \
	    $(OBJ)/m_artn_precision.o \
	    $(OBJ)/m_artn_tools.o \
	    $(OBJ)/units.o \
	    $(OBJ)/m_artn_data.o \
	    $(OBJ)/m_error.o \
	    $(OBJ)/string_tools.o \
	    $(OBJ)/permute.o \
            $(OBJ)/artn_params.o \
	    $(OBJ)/m_datainfo.o \
	    $(OBJ)/m_fire.o \
	    $(OBJ)/convert_units.o \
	    $(OBJ)/m_block_lanczos.o \
	    $(OBJ)/m_artn_report.o \
	    $(OBJ)/m_option.o \
	    $(OBJ)/write_report.o \
            $(OBJ)/set_params.o \
            $(OBJ)/get_params.o \
            $(OBJ)/set_runparam.o \
            $(OBJ)/get_runparam.o \
            $(OBJ)/set_data.o \
            $(OBJ)/get_data.o \
            $(OBJ)/fill_param_step.o \
            $(OBJ)/constrained_draw.o \
	    $(OBJ)/pbc.o \
	    $(OBJ)/compute_delr.o \
            $(OBJ)/center.o \
	    $(OBJ)/sum_force.o \
            $(OBJ)/perpforce.o \
            $(OBJ)/smooth_interpol.o \
	    $(OBJ)/move_mode.o \
	    $(OBJ)/write_struct.o \
            $(OBJ)/nextmin.o \
            $(OBJ)/make_filename.o \
            $(OBJ)/nperp_limitation.o \
	    $(OBJ)/random.o \
            $(OBJ)/check_artn_params.o \
            $(OBJ)/block_lanczos.o \
	    $(OBJ)/lanczos.o \
            $(OBJ)/m_setup_artn.o \
	    $(OBJ)/save_step_data.o \
            $(OBJ)/clean_artn.o \
            $(OBJ)/artn.o \
            $(OBJ)/check_force_convergence.o \
            $(OBJ)/push_over_procedure.o \
            $(OBJ)/push_init.o \
            $(OBJ)/block_pushinit.o \
            $(OBJ)/block_perprelax.o \
            $(OBJ)/block_pusheigen.o \
            $(OBJ)/block_pushover.o \
            $(OBJ)/block_finalize.o \
            $(OBJ)/start_guess.o \
            $(OBJ)/diag.o \
	    $(OBJ)/restart.o \
	    $(OBJ)/serialize.o \
            $(OBJ)/artn_step.o \
            $(OBJ)/artn_c_wrappers.o \
	    $(OBJ)/artn_api.o \
            $(OBJ)/artn_siesta.o \
            $(OBJ)/artn_QE.o


MOD := $(FC_MODOUT)$(OBJ) $(FC_MODINC)$(OBJ)

ifeq ($(INTEL),YES)
  FDEBUG := -stand f08  -traceback #-check all -check nouninit
  CPPFLAG := -fpp
else #($(F90),gfortran)
  FDEBUG := -Wunused -Wall -Wconversion-extra -Wextra -Wimplicit-interface -Wimplicit-procedure -Wsurprising -pedantic -std=f2008 -ffree-line-length-512 #-fcheck=all -fbacktrace -DDEBUG
  CPPFLAG := -cpp
endif
FLAGS := $(FCFLAGS) $(FDEBUG) -fPIC $(CPPFLAG) -funroll-loops

#
# add local lapack routines to compilation, if BLAS_LIB is not defined
#
ifndef BLAS_LIB
LIB_OBJECTS:=$(OBJ)/dgeev.o $(LIB_OBJECTS)
endif

# ---------------------------------------------------------------------------

default: lib

check_configure:
	@if [ "${artn_configured}" != "yes" ]; then echo " ** ERROR :: pARTn has not been configured."; exit 1; fi

lib: check_configure gitinfo create-folder libartn.a libartn.so makepub


# --- create folder for .o files
create-folder:
	@if [ ! -d $(OBJ) ]; then mkdir $(OBJ) ; fi
# ----------------------------------------------------------------------------


libartn.a: $(LIB_OBJECTS)
	$(AR) $(ARFLAGS) $@ $?
	@if [ -f "$@" ]; then echo "" ; echo "LIBRARY COMPILATION: SUCCESS!!" ; echo "" ; fi

libartn.so: $(LIB_OBJECTS)
	${F90} -shared  -o $@ $^ $(BLAS_LIB)  # Needs BLAS_LIB for compilation on macos 

# ...............................................................................

$(OBJ)/%.o: $(SRC)/%.f90
	$(F90) $(MOD) -c $(FLAGS)  $^ -o $@

#
# dgeev.f file from lapack
# compiler flags from: https://gcc.gnu.org/testing/testing-lapack.html
# keep -O0
#
$(OBJ)/dgeev.o: $(SRC)/dgeev.f
	$(F90) $(MOD) -fPIC -c -g -O0 -funroll-loops $^ -o $@


# get info from the git repo (if we are pulled from git)
gitinfo:
	@echo 'Getting version info from git'
	@if (type git && test -e ../.git ) >> /dev/null 2>> /dev/null ; then \
	  branch=$$(git rev-parse --abbrev-ref HEAD);  \
	  commit=$$(git rev-parse --short=8 HEAD); \
	else \
	  branch='(unknown)' ; \
	  commit='(unknown)' ; \
	fi; \
	echo "#define ARTN_INFO_GIT_BRANCH \"$${branch}\"" >  artn_gitinfo.h ;\
	echo "#define ARTN_INFO_GIT_COMMIT \"$${commit}\"" >> artn_gitinfo.h
	@touch artn_info.f90
	@touch write_report.f90


# write the file make.public, with path and names of the pARTn library,
# which can be useful for another program that wish to use pARTn as library.
makepub:
	@echo "## Values used at 'make lib' by 'src/Makefile'." > make.public
	@echo "## This file can be directly included by other projects" >> make.public
	@echo "##" >> make.public
	@echo "## NOTE: these are only correct if pARTn was compiled in the default way." >> make.public
	@echo "##" >> make.public
	@echo "" >> make.public
	@echo "## path to generated libraries (symlinks)" >> make.public
	@echo "LIBARTN_PATH=${LIBARTN_PATH}" >> make.public
	@echo "" >> make.public
	@echo "## the static library" >> make.public
	@echo "LIBARTN_STATIC=${LIBARTN_PATH}/${LIBARTN_STATIC}" >> make.public
	@echo "" >> make.public
	@echo "## the shared library" >> make.public
	@echo "LIBARTN_SHARED=${LIBARTN_PATH}/${LIBARTN_SHARED}" >> make.public
	@echo "" >> make.public
	@echo "## 'soname' for using as: -L\$$(LIBARTN_PATH) -l\$$(LIBARTN_SONAME)" >> make.public
	@echo "LIBARTN_SONAME=${LIBARTN_SONAME}" >> make.public
	@echo "" >> make.public
	@echo "## include path for fortran modules: -I\$$(LIBARTN_FINCLUDE)" >> make.public
	@echo "LIBARTN_FINCLUDE=$(realpath ${SRC}/${OBJ})" >> make.public
	@echo "" >> make.public
	@echo "## file containing C headers" >> make.public
	@echo "LIBARTN_CHEADER=artn.h" >> make.public
	@echo "" >> make.public
	@echo "## include path for C headers: -I\$$(LIBARTN_CINCLUDE)" >> make.public
	@echo "LIBARTN_CINCLUDE=${TOPDIR}/Files_LAMMPS" >> make.public
	@echo "" >> make.public
	@echo "## python interface path: \`export PYTHONPATH=${TOPDIR}/interface:\$$(PYTHONPATH)\`" >> make.public
	@echo "LIBARTN_PYTHONPATH=${TOPDIR}/interface" >> make.public



# --- CLEANUP
clean:
	rm -rf *.a *.so $(OBJ) make.public artn_gitinfo.h
