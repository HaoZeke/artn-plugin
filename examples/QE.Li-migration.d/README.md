# Example: Diffusion of intercalated Li in graphite 

## Description:

The starting configuration is an intercalated Li atom in graphite. pARTn should identify the saddle point for the diffiusion of the Li atom from one site to the other over the C-C bond. The initial displacement is generated on the Li atom (index 25) along the x-direction: 
```
push_mode = 'list'
push_ids = 25 
add_const(:,25) = 1.0, 0.0, 0.0, 0.0 
```
Additionally, for this example the number of initial displacements and the magnitude of the displacement is slightly increased, by specifying:
```
ninit = 4 
push_step_size  = 0.40
```
## Launch command:

To launch this example simply run:

`./run_example.sh`

or like a regular QE calculation by adding the -partn flag:
```bash 
mpirun -np N /QE_path/bin/pw.x -partn -in relax.Li-migration.graphite-3x2x2.in > relax.Li-migration.graphite-3x2x2.out 
```
## Expected results:

The saddle point should involve the Li atom on a bridge site in graphite, with a barrier of   0.0269 Ry ( 0.37 eV). A sample of the expected output is in `reference.d`, this example was based on of the examples presented in the publication discussing the [R-NEB method](10.1021/acs.jctc.8b01229).


Read more about pARTn output files [here](https://mammasmias.gitlab.io/artn-plugin/user_guide/tutorial/partn_output.html).


