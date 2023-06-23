# Example: NH3 inversion with QE 


## Description:

An example of identifying a saddle point for a molecular reconfiguration, the inversion of the ammonia (NH_3) molecule.
The starting configuration is an NH3 molecule in a box. 
The ARTn input file `artn.in` specifies the initial push on one atom, specifically the index 1:
```
    push_mode = 'list'
    push_ids = 1
```

The direction of the initial push is specified along the z-axis:

    add_const(3,1) = -1.0


## Launch command:

You can launch the example with the command: 
`./run_example.sh`

Or as any QE calculation, by specifying the `-partn` flag:

```bash
    mpirun -np N /QE_path/bin/pw.x -partn -in relax.NH3.in > relax.NH3.out
```
## Expected results:

Read more about pARTn output files [here](https://mammasmias.gitlab.io/artn-plugin/sections/Output.html).

You should hopefully obtain similar results as the ones reported in directory `reference.d`, i.e., a barrier of 0.0165 Ry (0.22 eV).
