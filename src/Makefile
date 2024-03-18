
include ../environment_variables

OBJ := Obj
SRC := .
#F90 := gfortran #ifort
#AR := ar

LIB_OBJECTS := \
	    $(OBJ)/precision.o \
	    $(OBJ)/tools.o \
	    $(OBJ)/string_tools.o \
	    $(OBJ)/units.o \
	    $(OBJ)/artn_data.o \
            $(OBJ)/artn_params_mod.o \
	    $(OBJ)/option.o \
            $(OBJ)/setup_artn.o \
            $(OBJ)/check_force_convergence.o \
            $(OBJ)/displacement_validation.o \
	    $(OBJ)/pbc.o \
            $(OBJ)/diag.o \
            $(OBJ)/center.o \
            $(OBJ)/push_init.o \
	    $(OBJ)/sum_force.o \
            $(OBJ)/perpforce.o \
            $(OBJ)/smooth_interpol.o \
            $(OBJ)/push_over_procedure.o \
	    $(OBJ)/move_mode.o \
	    $(OBJ)/write_report.o \
	    $(OBJ)/write_struct.o \
	    $(OBJ)/restart.o \
            $(OBJ)/nextmin.o \
            $(OBJ)/get_functions.o \
            $(OBJ)/make_filename.o \
            $(OBJ)/read_guess.o \
            $(OBJ)/start_guess.o \
            $(OBJ)/nperp_limitation.o \
            $(OBJ)/fperp_min_alignment.o \
            $(OBJ)/clean_artn.o \
            $(OBJ)/check_artn_params.o \
	    $(OBJ)/artn_save_data.o \
	    $(OBJ)/lanczos.o \
            $(OBJ)/artn.o \
            $(OBJ)/artn_api.o \
	    $(OBJ)/refresh_artn.o \
            $(OBJ)/artn_QE.o
	    #$(OBJ)/DEBUG.o \


FDEBUG := -g -fcheck=all -Wall #-DDEBUG #-check all  #-fcheck=all

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


