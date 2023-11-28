import lammps
import pypARTn

lmp = lammps.lammps()
artn = pypARTn.artn( engine="lmp")
#artn = pARTn.artn( )
#artn.command("hi",43)

lmp.command("units metal")
lmp.command("dimension 3")
lmp.command("read_data   pt111_heptamer.in")
lmp.command("pair_style morse/smooth/linear 9.5")
lmp.command("pair_coeff * * 0.7102 1.6047 2.897")
lmp.command("plugin load ../../lib/libartn-lmp.so")
lmp.command("fix 10 all artn")
lmp.command("min_style fire")
lmp.command("dump 10  all custom 1 config.dmp id type x y z fx fy fz")
#lmp.command("minimize 0 1e-3 1 1")

#artn.tt()
#artn.destroy()
#artn.tt()
