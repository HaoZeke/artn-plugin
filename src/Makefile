
include ../environment_variables

OBJ := Obj
SRC := .
#F90 := gfortran #ifort
#AR := ar

LIB_OBJECTS := \
	    $(OBJ)/precision.o \
	    $(OBJ)/m_tools.o \
	    $(OBJ)/units.o \
	    $(OBJ)/m_artn_data.o \
	    $(OBJ)/m_error.o \
	    $(OBJ)/string_tools.o \
	    $(OBJ)/permute.o \
            $(OBJ)/artn_params_mod.o \
	    $(OBJ)/convert_units.o \
	    $(OBJ)/m_datainfo.o \
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
            $(OBJ)/check_force_convergence.o \
            $(OBJ)/displacement_validation.o \
	    $(OBJ)/pbc.o \
	    $(OBJ)/compute_delr.o \
            $(OBJ)/center.o \
	    $(OBJ)/sum_force.o \
            $(OBJ)/perpforce.o \
            $(OBJ)/smooth_interpol.o \
            $(OBJ)/push_over_procedure.o \
	    $(OBJ)/move_mode.o \
	    $(OBJ)/write_struct.o \
	    $(OBJ)/save_step_data.o \
            $(OBJ)/nextmin.o \
            $(OBJ)/make_filename.o \
            $(OBJ)/nperp_limitation.o \
	    $(OBJ)/random.o \
            $(OBJ)/check_artn_params.o \
            $(OBJ)/block_lanczos.o \
	    $(OBJ)/lanczos.o \
            $(OBJ)/m_setup_artn.o \
            $(OBJ)/clean_artn.o \
            $(OBJ)/artn.o \
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
	    $(OBJ)/m_fire.o \
	    $(OBJ)/artn_api2.o \
            $(OBJ)/artn_siesta.o \
            $(OBJ)/artn_step.o \
            $(OBJ)/artn_QE.o
	    #$(OBJ)/DEBUG.o \


FDEBUG := -g -fcheck=all -Wunused -Wall -Wconversion-extra -Wextra -Wimplicit-interface -Wimplicit-procedure -Wsurprising -pedantic -std=f2008 #-DDEBUG #-check all

ifeq ($(F90),ifort)
  MOD   := -module $(OBJ)
  FLAGS := $(FFLAGS) $(FDEBUG) $(LAPACK_LIBS) -fPIC -fpp
else #($(F90),gfortran)
  MOD   := -I$(OBJ) -J$(OBJ) 
  FLAGS := $(FFLAGS) $(FDEBUG) $(LAPACK_LIBS) -fPIC -cpp
endif


# ---------------------------------------------------------------------------

default: lib


lib: create-folder libartn.a libartn.so

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


# --- CLEANUP
clean:
	rm -rf *.a *.so $(OBJ)


