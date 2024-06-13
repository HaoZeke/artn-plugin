This is a test example for Siesta-pARTn, the famous sivac.
The DFT parameters are possibly very wrong, the run might randomly crash.

File `artn.lua` is the lua script which calls pARTn at the `siesta.MOVE` hook point.
The main siesta input file is `in.fdf`.

Before running this test you should copy `partn_lua.so` into this directory:

    cp -s ../Files_Siesta/partn_lua.so .

The script `run.sh` gives an idea of how the calculation is launched, it is probably different for your compilation.

This was tested **only** with siesta-v4.1.5.
