# Example: SN2 reaction with QE 


## Description:

An example of identifying a saddle point for a molecular reaction, an SN2 substitution:
`Cl + CH_3Cl -> ClCH_3 + Cl`
The ARTn input file `artn.in` specifies the initial push on one three atoms, with indeces 1,2,6, corresponding to Cl,C, and Cl, respectively:
```
    push_mode = 'list'
    push_ids = 1,2,6 
```

The direction of the initial push is specified along the z-axis:
```
  add_const(3,1) = -0.2
  add_const(3,2) = 0.2
  add_const(3,6) = 1.0
```
Additionally, in this example the number and step size of initial displacements is increased: 
```
  ninit = 4 
  push_step_size = 0.6

```
## Launch command:

You can launch the example with the command: 
`./run_example.sh`

Or as any QE calculation, by specifying the `-partn` flag:

```bash
    mpirun -np N /QE_path/bin/pw.x -partn -in relax.ClCH3+Cl.in > relax.ClCH3+Cl.out
```
## Expected results:

You should hopefully obtain similar results as the ones reported in directory `reference.d`, i.e., a barrier of 0.054 Ry (0.735 eV). This example was described in greater detail [here](https://doi.org/10.1016/j.commatsci.2022.111363)
