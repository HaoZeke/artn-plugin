# Example: Si vacancy diffusion in QE

## Description:

This example shows how to use pARTn in QE, to compute the diffusion of a single vacancy in a Si crystal.

The input structure is given in the QE input file `relax.Si-vac.in`.

## Launch command:

The example is launched like a regular QE calculation:

```bash
mpirun -np N /QE_path/bin/pw.x -partn < relax.Si-vac.in
```

## Expected results:

The computed energy barrier should be around 0.018 Ry. See also the reference result files in the `reference.d` directory. The reference results were obtained with QE7.0.
