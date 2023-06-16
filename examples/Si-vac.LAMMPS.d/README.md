## Si vacancy diffusion in LAMMPS

This example shows how to use pARTn in LAMMPS, to compute the diffusion of a single vacancy in a Si crystal.
There are two input structures containing the same defect:

 - `conf.sw` with 511 atoms;
 - `conf_big.sw` with 7999 atoms.

The choice of which simulation box is used affects both input files, the LAMMPS input in `lammps.in`, and the ARTn input `artn.in`, see the comments in both files.

The example is launched like a regular LAMMPS calculation:

```bash
/lammps_path/lmp -in lammps.in
```

The energy barrier should be around 0.5 eV for both simulation boxes.
