# Example: Si vacancy diffusion in QE

## Description:

This example shows how to use pARTn in QE, to compute the diffusion of a single vacancy in a Si crystal.

The input structure is given in the QE input file `relax.Si-vac.in`.

## Launch command:

The example can be launched as: 

```bash
./run_example.sh
```

or like a regular QE calculation:

```bash
mpirun -np N /QE_path/bin/pw.x -partn -in relax.Si-vac.in > relax.Si-vac.out
```

## Expected results:

The computed energy barrier should be around 0.018 Ry. See also the reference result files in the `reference.d` directory. The reference results were obtained with QE7.0.
