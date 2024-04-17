-- package.cpath = package.cpath .. ";/home/mgunde/artn_siesta/Files_Siesta/partn_lua.so"

local flos = require "flos"
local Unit = siesta.Units

-- load artn_lua module
require("partn_lua")


-- default initial FIRE params
-- local dt_init = 0.5
local dt_init = 2.0
local alpha_init = 0.1
local f_inc = 1.1
local f_dec = 0.5
local f_alpha = 0.99
local N_min = 5


local lrlx = false

-- init FIRE params
local FIRE = {}
FIRE = flos.FIRE{dt_init = dt_init,
                 alpha_init = alpha_init,
                 f_inc = f_inc,
                 f_dec = f_dec,
                 f_alpha = f_alpha,
                 N_min = N_min,
                 direction="global", correct="global"}

FIRE.max_dF = 20.0 -- Bohr
FIRE.tolerance = 1.0e-1 -- Force tolerance for optimization: if norm():max() is below this, algo exists. units: Ry/bohr



-- This is the main function called from Siesta.
function siesta_comm()

  -- Create new return table;
  -- this will contain keys of which elements are returned to siesta
  -- after the modifications to them are made.
  -- For now it's just empty.
  ret_tbl = {}



  if siesta.state == siesta.INITIALIZE then
    -- siesta.receive( {"geom.xa"} )
    -- xa = siesta.geom.xa
    -- print("iam here")
    -- fprint_stack(xa)

    -- siesta.print_allowed()
    -- siesta.send({"Stop"})


    -- In the initialization step we request the
    -- convergence criteria
    --  MD.MaxDispl
    --  MD.MaxForceTol
    -- We also need the mass for scaling the displacments
    siesta.receive({"MD.MaxDispl",
                    "MD.MaxForceTol",
                    "geom.mass",
                    "geom.na_u"})

    -- Print information
    IOprint("\nLUA convergence information for the FIRE algorithms:")

    -- Ensure we update the convergence criteria
    -- from SIESTA

    -- FIRE.tolerance = siesta.MD.MaxForceTol * Unit.Ang / Unit.eV
    -- FIRE.max_dF = siesta.MD.MaxDispl-- / Unit.Ang
    FIRE.set_mass(siesta.geom.mass)
    -- FIRE.dt = dt_init
    if FIRE.V == nil then
      FIRE:set_velocity( flos.Array.zeros(siesta.geom.na_u, 3) * 0.0 )
    end

    -- Print information
    if siesta.IONode then
      FIRE:info()
    end

  end


  -- moving the ions
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
    print("iam in siesta.MOVE")

    -- siesta.print_allowed()
    -- siesta.send({"Stop"})


    -- call the function  which does things: input arg `siesta`
    -- contains table of properties
    ret_tbl = move_artn( siesta )


    -- if siesta.IONode then
    --   FIRE:info()
    -- end

    -- siesta.send({"Stop"})
    -- do a fire move
    -- ret_tbl = move_FIRE( siesta )


    -- siesta.send({"Stop"})
  end

  -- send table of results to siesta
  siesta.send( ret_tbl )
end



function print_xyz( siesta )
  nat = siesta.geom.na_u
  lat = siesta.geom.cell
  typ = siesta.geom.species
  coords = siesta.geom.xa
  force = siesta.geom.fa

  printstruc( lat, typ, coords, force, nat )
end



function move_artn( siesta )

  if siesta.IONode then
    print( "iam in move_me function")
    print( "::lrlx",lrlx)
    -- print( siesta.Units.Ang)
    -- print( siesta.Units.eV)
  end

  -- to get eV/Ang forces, need to * Units.Ang / Units.eV

  -- setup the needed variables

  -- istep = siesta.geom.mstep

  -- number of atoms
  nat = siesta.geom.na_u

  -- current positions in Bohr
  tau = siesta.geom.xa

  -- current force in Ry/Bohr
  force = siesta.geom.fa

  -- lattice vectors in bohr, i think not scaled with alat?
  at = siesta.geom.cell

  -- energy in Ry
  etot = siesta.E.total

  -- atomic types
  ityp = siesta.geom.species

  -- order of atoms
  order = {}

  -- atomic coords fixed by the engine
  if_pos = flos.Array.empty(nat,3)

  -- current alpha value from FIRE
  alpha_curr = FIRE.alpha

  -- current value of dt from FIRE
  dt_curr = FIRE.dt

  -- n_P_pos from FIRE
  nsteppos = FIRE.n_P_pos

  -- current velocities from FIRE
  vel = FIRE.V

  -- modified force and velocity, to be returned from artn
  force_m = force
  vel_m = vel


  -- local variables
  local displ_vec = flos.Array.zeros(nat,3)
  local lrelax

  -- set the order vector
  -- i think siesta doesn't re-label atom indices, but let's keep
  -- this vector here, just in case. If not it can be generated in Fortran
  for i = 1, nat do
    order[i] = i
  end

  -- print struc before move with correct force
  if siesta.Node == 0 then
    f_p = flos.Array.from(force) * Unit.Ang / Unit.eV
    -- printstruc( at, ityp, tau, f_p, nat, istep )
    printstruc( at, ityp, tau, f_p, nat )
  end


  -- set the if_pos array
  -- this should be done in a better way to receive constr from siesta.
  for i = 1, nat do
    if_pos[i][1] = 1
    if_pos[i][2] = 1
    if_pos[i][3] = 1
  end
  -- need to fix some atom for whatever reason: see comments in FIRE lua files
  if_pos[38][1] = 0
  if_pos[38][2] = 0
  if_pos[38][3] = 0


  -- call fortran: careful to the order of arguments/results
  lconv,
    lrelax,
    alpha_curr_m,
    dt_curr_m,
    nsteppos_m,
    vel_m,
    force_m,
    tau_m      = artn_luasiesta(
                          vel,
                          nsteppos,
                          dt_curr,
                          dt_init,
                          alpha_curr,
                          alpha_init,
                          if_pos,
                          order,
                          at,
                          tau,
                          ityp,
                          etot,
                          force,
                          nat     )

  lrlx = lrelax

  if siesta.IONode then
    print("move me received:")
    print( "move me received lrelax",lrelax)
    print( "dt curr",dt_curr_m )
    print( "alpha_curr",alpha_curr_m)
    print("nsteppos", nsteppos_m)
    -- print( "move me received displ_vec:")
    -- for i =1, nat do
    --   print( i, displ_vec[i][1], displ_vec[i][2], displ_vec[i][3])
    -- end
  end

  -- print struc before move with modif forces
  if siesta.IONode then
    f_p = flos.Array.from(force_m) * Unit.Ang / Unit.eV
    -- printstruc( at, ityp, tau_m, f_p, nat, istep )
    printstruc( at, ityp, tau_m, f_p, nat )
  end

  -- send edited params to FIRE
  FIRE.dt = dt_curr_m
  FIRE.alpha = alpha_curr_m
  FIRE.n_P_pos = nsteppos_m
  FIRE.V = flos.Array.from(vel_m)

  -- if siesta.IONode then
  --   print( "modif fa")
  --   for i=1, nat do
  --     -- print( i, siesta.geom.fa[i][1], siesta.geom.fa[i][2], siesta.geom.fa[i][3] )
  --     print( i, force_m[i][1], force_m[i][2], force_m[i][3] )
  --   end
  -- end

  -- control convergence by lconv retunred from ARTn
  siesta.MD.relaxed = lconv

  -- FIRE part
  if siesta.IONode then
    FIRE:info()
  end

  -- create arrays for fire
  -- local xa = flos.Array.from(siesta.geom.xa)-- / Unit.Ang

  -- local xa = flos.Array.from( tau_m )
  -- local fa = flos.Array.from( force_m ) -- * Unit.Ang / Unit.eV

  local xa = flos.Array.from( tau_m )-- / Unit.Ang
  local fa = flos.Array.from( force_m ) --* Unit.Ang / Unit.eV


  -- if siesta.IONode then
  --   print("fa")
  --   for i=1, nat do
  --     print( i, fa[i][1], fa[i][2], fa[i][3] )
  --   end
  --   print("fa:norm(0)", fa:norm(0) )
  --   print("fa:norm()", fa:norm() )
  -- end

  -- if siesta.IONode then
  --   print("xa[1][1]",xa[1][1])
  --   print( "fa[48]", fa[48][1],fa[48][2],fa[48][3])
  --   print("unit.Ang",Unit.Ang)
  --   print("Unit.eV", Unit.eV)
  --   print("lvonv",lconv)
  -- end

  -- call relax engine
  print( "::: step rlx", lrlx)
  if lrlx then
    -- local xa = flos.Array.from( tau_m )
    -- local fa = flos.Array.from( force_m ) -- * Unit.Ang / Unit.eV
    if siesta.IONode then
      print( ":::: start relax due to lrlx", lrlx )
    end
    local xa = flos.Array.from( tau_m )-- / Unit.Ang
    local fa = flos.Array.from( force_m )-- * Unit.Ang / Unit.eV
    local out_xa = FIRE:optimize( xa, fa )
    -- local relaxed = FIRE:optimized()
    siesta.geom.xa = out_xa-- * Unit.Ang
    -- siesta.MD.Relaxed = false
    -- return { "geom.xa", "MD.Relaxed" }
  end


  -- displace atoms with FIRE
  if not lconv and not lrlx then
    -- call fire step
    local out_xa = FIRE:optimize( xa, fa)

    local diff_xa = flos.Array.zeros(nat,3)
    diff_xa = out_xa - xa
    if siesta.IONode then
      print( diff_xa )
    end
    -- local relaxed = FIRE:optimized()

    -- siesta.geom.xa = out_xa-- * Unit.Ang

    siesta.geom.xa = out_xa-- * Unit.Ang
    -- siesta.MD.Relaxed = relaxed

  end

  siesta.MD.Relaxed = false
  if lconv then
    -- ARTn finished
    siesta.MD.Relaxed = true
  end

  return { "geom.xa", "MD.Relaxed" }

end





function move_FIRE(siesta)

   -- Retrieve the atomic coordinates and the forces
   local xa = flos.Array.from(siesta.geom.xa) / Unit.Ang
   -- Note the FIRE requires the gradient, and
   -- the force is the negative gradient.
   local fa = flos.Array.from(siesta.geom.fa) * Unit.Ang / Unit.eV

   -- call fire step
   local out_xa = FIRE:optimize(xa, fa)
   local relaxed = FIRE:optimized()

   -- Send back new coordinates (convert to Bohr)
   siesta.geom.xa = out_xa * Unit.Ang
   siesta.MD.Relaxed = relaxed

   return {"geom.xa",
	   "MD.Relaxed"}
end
