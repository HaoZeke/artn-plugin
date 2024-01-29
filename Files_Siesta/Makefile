include ../environment_variables

MPIF90 := mpifort

LIB_PARTN_LUA := partn_lua.so


OBJ := Obj
SRC := .

LIBS := -llua5.3 ../src/libartn.a

FLAGS := -fdefault-real-8
MOD := -I$(OBJ) -J$(OBJ)




default: all
all: $(OBJ) lib_partnlua


LUAINT_O := $(OBJ)/lua.o


$(OBJ):
	@if [ ! -d $(OBJ) ]; then mkdir $(OBJ) ; fi

lib_partnlua: $(SRC)/partn_lua.f90 $(LUAINT_O)
	$(MPIF90) $(FLAGS) $(MOD) -shared -fPIC -o $(LIB_PARTN_LUA)  $^ $(LIBS)
	@echo '============ NOTE: ====================='
	@echo ' Before using siesta with pARTn, make sure lua knows the path to:'
	@echo ''
	@echo '     Files_Siesta/partn_lua.so'
	@echo ''
	@echo ' The simplest way is to add the following line to your .bashrc (with appropriate path):'
	@echo ''
	@echo '     export LUA_CPATH=$$LUA_CPATH:";$$HOME/artn-plugin/Files_Siesta/?.so;"'
	@echo ''
	@echo '========================================'

$(OBJ)/%.o: $(SRC)/%.f90
	$(F90) $(MOD) -c $(FLAGS)  $^ -o $@


clean:
	rm -rf $(OBJ) $(LIB_PARTN_LUA)
