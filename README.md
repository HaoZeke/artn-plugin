
# plugin-ARTn  {#mainpage}

This is a working repository of the current version of the plugin-ARTn; currently it can be used with Quantum ESPRESSO and LAMMPS.
This code has been developed in collaboration by Matic Poberznik, Miha Gunde, Nicolas Salles and Antoine Jay.

<!-- The repository is developed on [GitLab](https://gitlab.com/mammasmias/artn-plugin). -->
The full documentation is available at: [link](https://mammasmias.gitlab.io/artn-plugin/).
Please post your issue(s) on [GitLab](https://gitlab.com/mammasmias/artn-plugin).

<img src="./.extra/ARTn_workflow-1.png" alt="ARTn-Plugin Work Flow" width="400" size="auto" />

The algorithm [ARTn](https://normandmousseau.com/ART-nouveau.html) allows the exploration of the energetic landscape of an atomic configuration, to find the saddle point (transition state), and the associated energy minima.

## Contains:


- `examples/`: Contains many examples, from molecules to surfaces;
- `Files_LAMMPS/`: Contains the lammps fix, for the LAMMPS/ARTn interface;
- `Files_QE/`: Contains the file `plugin_ext_forces.f90`, for the QE/ARTn interface;
- `README.md`: This file;
- `src/`: ARTn plugin subroutines;
- `Makefile`: Compilation commands, uses the environment variables defined in `environment_variables`;
- `environment_variables`: custom file defining:
    - compilers `F90`, `CXX`/`CC`;
    - the paths to ARTn (current directory), BLAS and FORTRAN libraries, and chosen engine(s) QE/LAMMPS;
    - `PARA_PREFIX` prefix for launching examples via provided run scripts.

## Interface with engine

Two interfaces are available for the moment:

- One for **Quantum ESPRESSO**. To use it read the [manual](./Files_QE/README.md).
- One for **LAMMPS**. Two version exist, one using the class [Plugin](https://docs.lammps.org/plugin.html) of LAMMPS, for this version please read the [manual](./Files_LAMMPS/README.md); The second one does not use the class plugin of LAMMPS because this class exist only since 2022. If you use a version older than 2022 please read the [manual](./Files_LAMMPS/README-old.md)

## Examples

The list of [examples](./examples/README.md) using both interfaces.


## Using ARTn

Please read the [documentation](https://mammasmias.gitlab.io/artn-plugin/), or the [manual](./MANUAL.md).

If you publish results obtained by pARTn, please cite the reference paper:

`pARTn: a plugin implementation of the Activation Relaxation Technique nouveau hijacking a minimisation algorithm`, **Computer Physic Comunication** XXX,XXX (2023), M. Poberznik, M. Gunde, N. Salles, A. Jay, A. Hemeryck, N. Richard, N. Mousseau and L. Martin-Samos


## Issues, bugs, requests

Use the [issue](https://gitlab.com/mammasmias/artn-plugin/-/issues) tracker to report the bugs.

## License

[Terms of use](./TERMS_OF_USE)
