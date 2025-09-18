# Example: Diffusion of a vacancy in graphene

## Description:

The starting configuration is a minimized graphene sheet, containing a vacancy . pARTn should identify the saddle point for the vacancy migration from one site to the other. The initial displacement is generated on a C atom (index 1) along the y-direction: 
```
push_mode = 'list'
push_ids = 1
add_const(:,1) = 0.0, 1.0, 0.0
```
Additionally, for this example the number of initial displacements is decreased to 2 
```
ninit = 2 
```
## Launch command:

To launch this example simply run:

`./run_example.sh`

or like a regular QE calculation by adding the -partn flag:
```bash 
mpirun -np N /QE_path/bin/pw.x -partn -in relax.graphene-3x2.C-vac.in > relax.graphene-3x2.C-vac.out 
```
## Expected results:

The saddle point should involve a C atom inbetween two vacant sites, and it is associated  with a barrier of 0.0772 Ry ( 1.05 eV). A sample of the expected output is in `reference.d`, this example was based on of the examples presented in the publication discussing the [R-NEB method](10.1021/acs.jctc.8b01229).


Read more about pARTn output files [here](https://mammasmias.gitlab.io/artn-plugin/user_guide/tutorial/partn_output.html).


