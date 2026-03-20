
-- #### Make sure LUA knows where to search for `libartn_lua.so`, there are 2 ways to do it:
-- #### 1) specify the environemnt path by:
-- ####
-- #### export LUA_CPATH=$LUA_CPATH:";/<your-path-to-artn-plugin>/lib/?.so;"
-- ####
-- #### 2) Or uncomment the following line `package.cpath = ...`
-- ####    and modify the path to artn-plugin/lib/libartn_lua.so;
-- package.cpath = package.cpath .. ";/home/mgunde/artn_devel/lib/libartn_lua.so"

local Unit = siesta.Units

-- load artn_lua module
require("libartn_lua")




-- This is the main function called from Siesta.
function siesta_comm()

  -- Create new return table;
  -- this will contain keys/names of which arguments/data are returned to siesta
  -- after the modifications to them are made.
  -- For now it's just empty.
  ret_tbl = {}



  -- In the siesta.INITIALIZE step, call artn_setup
  if siesta.state == siesta.INITIALIZE then

    -- siesta.print_allowed()
    -- siesta.send({"Stop"})

    -- request data from siesta, by variable name as string
    -- geom.na_u is number of atoms
    siesta.receive({"geom.na_u"})

    -- call artn setup function (from `ENGINES/Siesta/libartn_lua.so`)
    lerr = artn_setup( siesta.geom.na_u ); local info = debug.getinfo(1, "Sl")
    if lerr then
      -- we have an error in setup, stop siesta
      artn_err_write( info.short_src, info.currentline )
      artn_destroy()
      siesta.send({"Stop"})
    end

    -- Print information
    IOprint("artn_lua setup successful.")

  end


  -- In siesta.MOVE step, move the ions according to artn
  if siesta.state == siesta.MOVE then

    -- specify which properties will be needed from siesta
    siesta.receive( {"geom.na_u",
                     "geom.cell",
                     "geom.species",
                     "geom.xa",
                     "geom.fa",
                     "MD.Relaxed",
                     "E.total" })
                     -- "geom.mstep"})
    -- print("iam in siesta.MOVE")

    -- call the function  which does things:
    -- input arg `siesta` contains table of properties/data from siesta.receive;
    -- the result `ret_tbl` is the table of properties/data returned by `move_artn` lua function.
    ret_tbl = move_artn( siesta )

    -- send table of results to siesta
    siesta.send( ret_tbl )

  end

end




-- compute artn_step and move ions
function move_artn( siesta )

  -- if siesta.IONode then
  --   print( "iam in move_me function")
  --   -- print( "units.Ang", siesta.Units.Ang )
  --   -- print( "units.eV ", siesta.Units.eV )
  -- end

  -- to get eV/Ang forces, need to * Units.Ang / Units.eV

  -- setup the needed variables

  -- istep = siesta.geom.mstep

  -- number of atoms
  nat = siesta.geom.na_u

  -- current positions in Bohr
  tau = siesta.geom.xa

  -- current force in Ry/Bohr
  force = siesta.geom.fa
  -- for i = 1, nat do
  --   for j = 1, 3 do
  --     force[i][j] = force[i][j] * siesta.Units.Ang / siesta.Units.eV
  --   end
  -- end
  -- test( force )


  -- lattice vectors in bohr, i think not scaled with alat?
  at = siesta.geom.cell

  -- energy in Ry
  etot = siesta.E.total

  -- atomic types
  ityp = siesta.geom.species

  -- setup if_pos to all 1
  local if_pos = {}
  for i = 1, nat do
    if_pos[i] = {}
    for j = 1, 3 do
      if_pos[i][j] = 1
    end
  end
  -- ierr = artn_set_runparam( "lrelax", true )
  -- ierr = artn_set_runparam( "linit", false )
  -- ierr = artn_set_runparam( "lperp", false )
  -- ierr = artn_set_runparam( "leigen", false )
  -- ierr = artn_set_runparam( "llanczos", false )
  -- ierr = artn_set_runparam( "lpush_over", false )
  -- ierr = artn_set_runparam( "lbackward", false )
  -- ierr = artn_set_runparam( "fpush_factor", -1 )

  -- ## the `artn_step` function called here is defined in `ENGINES/Siesta/libartn_lua.f90`
  lconv, displ_vec = artn_step( if_pos, at, tau, ityp, force, etot, nat )
  -- test( if_pos )

  if siesta.Node==0 then
    printstruc( at, ityp, tau, force, nat )
  --   print(" printing to conf.xyz before move")
  end

  -- move tau and set geom.xa
  for i = 1, nat do
    for j = 1, 3 do
      tau[i][j] = tau[i][j] + displ_vec[i][j]
      siesta.geom.xa[i][j] = tau[i][j]
    end
  end
  -- if siesta.Node==0 then
  --   printstruc( at, ityp, tau, force, nat )
  --   print(" printing to conf.xyz after move")
  -- end

  -- set the flag to finish
  siesta.MD.Relaxed = lconv

  -- return table to siesta: new positions and relaxed flag
  return { "geom.xa", "MD.Relaxed" }

end

