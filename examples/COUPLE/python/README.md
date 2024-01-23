To run this test, you need:
 - lammps compiled for python:
   ```
   cd /your-lammps-path/src
   make install-python
   ```

 - set the environment variable `PYTHONPATH` to include path to `/artn-plugin/interface`:
   ```
   export PYTHONPATH=/your-path-to/artn-plugin/interface:$PYTHONPATH
   ```

The python pARTn interface module `pypARTn` has some documentation accessible with the intrinsic `help()` of python:
```
import pypARTn
help( pypARTn )
```

When python loads shared libraries, it checks immediately if all symbols are resolved. If not, it will complain. Practically, this means that `lammps` module needs to be initialised *before* `pypARTn`, since some symbols from `liblammps.so` are referenced in `libartn-lmp.so`:
```
## first load and initialise lammps
import lammps
lmp = lammps.lammps( args = ... )

## then load and initialise artn
import pypARTn
artn = pypARTn.artn( engine = "lmp" )

## now you can use both modules normally
## note: lammps still needs the command "plugin load ...../lib/libartn-lmp.so" to access fix artn
## note2: artn still needs the proper "engine_units" variable set
```
