#include ../environment_variables
#include ../.func4makefile
include ../make.inc

## change by your lua library (also possible from file environment_variables)
#LUALIB := -llua5.3



LIB_PARTN_LUA := partn_lua.so
LIBS := $(LUALIB) $(TOPDIR)/src/libartn.so

OBJ := Obj
SRC := .


ifeq ($(INTEL),YES)
   FLAGS := -fpp -fPIC
else
   FLAGS := -cpp -g -fPIC
endif

MOD := $(FC_MODOUT)$(OBJ) $(FC_MODINC)$(OBJ) $(FC_MODINC)$(TOPDIR)/src/Obj




default: all
all: $(OBJ) lib_partnlua


LUAINT_O := $(OBJ)/lua.o


$(OBJ):
	@if [ ! -d $(OBJ) ]; then mkdir $(OBJ) ; fi

lib_partnlua: $(SRC)/partn_lua.f90 $(LUAINT_O)
	@$(call check_defined, MPIF90)
	@$(call check_defined, LUALIB)
	$(MPIF90) $(FLAGS) $(MOD) -shared -fPIC -o $(LIB_PARTN_LUA)  $^ $(LIBS)
	ln -sf $(TOPDIR)/Files_Siesta/$(LIB_PARTN_LUA) $(TOPDIR)/lib/$(LIB_PARTN_LUA)
	@echo '============ NOTE: ====================='
	@echo ' Before using siesta with pARTn, make sure lua knows the path to:'
	@echo ''
	@echo '     Files_Siesta/partn_lua.so'
	@echo ''
	@echo ' The simplest way is to add the following line to your .bashrc (with appropriate path):'
	@echo ''
	@echo '     export LUA_CPATH=$$LUA_CPATH:";$$HOME/artn-plugin/Files_Siesta/?.so;"'
	@echo ''
	@echo 'Alternatively, edit the artn.lua script to add the path.'
	@echo '========================================'

$(OBJ)/%.o: $(SRC)/%.f90
	$(F90) $(MOD) -c $(FLAGS)  $^ -o $@


clean:
	rm -rf $(OBJ) $(LIB_PARTN_LUA)
