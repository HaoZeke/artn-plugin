
# How to install ARTN/VASP

1. Edit the file `environment_variables`:
   - Define your compilator in the variable `F90`
   - Define the path of VASP in the variable `VASP_PATH`

2. Write the command: `make vasp`
   It will copy the file `ARTn_VASP.F` in `VASP_PATH/src` directory

3. In VASP directory:
   - Edit the file `${VASP_PATH}/src/.objects` to add the file `ARTn_VASP.o` at the compilation
   - Write in `${VASP_PATH}/src/main.F` after the `CALL CHAIN_FORCE()` the call to `artn_vasp()` subroutine (l.3190)
   ```Fortran
    CALL CHAIN_FORCE(...)

    CALL ARTN_VASP(...)
   ```
   - Edit `Makfile.include` to add the path for the libartn.a:
   ```Makefile
   LLIBS += /path-to-artn/lib/libartn.a
   ```

4. Compile VASP


