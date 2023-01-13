#################
Plugin Philosophy
#################

Plugin-ARTn is linked with Energy/Forces calculation engine through the minimization algorithm FIRE. 
The idea is to launch the engine for a FIRE minimization, and bias the minimization with the plugin-ARTn, to hijack FIRE and perform the ARTn method instead.


How to use
==========

ARTn can be used in different ways, with some optional variables.

- Research from the local minimum...
- Saddle refine...


.. _concept:

Concept
=======

Integration algorithms are generally written in terms of the positions :math:`R(i)`, and displacements :math:`\Delta R`. A generic pseudo-algorithm is shown in Algorithm [REF-image]. 
The atomic positions R(i) at step `i` are updated by the application of :math:`\Delta R`, as Eq. :eq:`R_i+1`.

.. math:: R(i+1) = R(i) + \Delta R
   :label: R_i+1

Depending on the specific algorithm, the term :math:`\Delta R` is some function of the set of instantaneous properties :math:`\left\{q(i)\right\} = \left\{q_1(i), q_2(i), ... , q_n(i)\right\}`, e.g. the force :math:`F(i)`, velocity :math:`v(i)`, or possibly others (charge, polarization, etc), and the timestep :math:`\Delta t`:

.. math:: \Delta R = \Delta R( \left\{ q(i)\right\} ) = \Delta R( F(i), v(i), ... , ∆t) 
   :label: DR_update

A single iteration of the main integration loop consists of two actions: 
first the evaluation of the properties :math:`\left\{q(i)\right\}`, at line 2 of Algorithm [REF-image], and second the subsequent update of the atomic positions :math:`R(i)` to :math:`R(i + 1)`, at line 5 of Algorithm 1, via the :math:`\Delta R` obtained by the integrator (prescribed by Eq. :eq:`DR_update`). 
The form of Eq. :eq:`DR_update` is specific to the integrator algorithm used, and can be seen as application of a function :math:`F`, which returns a displacement :math:`\Delta R`, from a set of given instantaneous properties :math:`\left\{q(i)\right\}`.

.. math:: F : \left\{ q(i) \right\} \rightarrow \Delta R 
   :label: F(q)

In order to hijack an algorithm and overwrite it with another algorithm, the hijacker scheme needs at least two components. 
Firstly, its own hijacker algorithm which prescribes a displacement :math:`\Delta R_{p}`, and secondly, a way to constrain the hijacked/host algorithm to perform the prescribed displacement :math:`\Delta R_{p}` instead of :math:`\Delta R`, such that :math:`R(i+1) = R(i) + \Delta R_{p}`.
The hijacker scheme only enters the main loop of the host algorithm once per iteration step (Algorithm [REF-image] line 3), so it needs to be written such that each time it is called, it only prescribes one displacement :math:`\Delta R_{p}`, which is the displacement following its own internal algorithm.
The imposition of a prescribed displacement ∆Rp on the host algorithm is achieved by modifying the properties :math:`{q(i)} → {q_{mod}(i)}`, such that the calculation of :math:`\Delta R( \left\{q_{mod}(i)\right\} )` in the host algorithm returns :math:`\Delta R_{p}`. 
In other words, the properties :math:`\left\{q_{mod}(i)\right\}` need to be such that the application of :math:`F` (Algorithm [REF-image] line 4) returns the prescribed displacement, :math:`F( \left\{q_{mod}(i)\right\} ) = \Delta R_{p}`.
In order to obtain the proper {qmod(i)}, we define a function G, to be called before :math:`F`, as:

.. math:: G : \Delta R_p \rightarrow \left\{q_{mod}(i)\right\}, 
   :label: G(dR)

which returns the set of modified properties :math:`\left\{q_{mod}(i)\right\}`, given an input :math:`\Delta R_{p}`, such that the subsequent :math:`F( \left\{q_{mod}(i)\right\} ) = \Delta R_p`. 
Function :math:`G` can be seen as an inverse of :math`F`, as :math:`G ∼ F−1`. 
The function G is applied at the end of hijacker scheme, and it converts a displacement :math:`\Delta R_{p}` prescribed by the hijacker internal algorithm, into a set of instantaneous properties :math:`{q_{mod}(i)}`, such that the move performed by the host algorithm (application of :math:`F`) corresponds to :math:`\Delta R( {q_{mod}(i)} ) = \Delta R_p`. 
See also Figure 1 for a schematic representation. 
The instantaneous properties :math:`{q(i)}` can be modified in different ways:
1. trivially, no modification: :math:`{q_{mod}(i)} = {q(i)}`, the resulting displacement will be done according to the host integrator algorithm’s own logic;
2. complete overwrite: :math:`{q_{mod}(i)} = {q_u }`, where :math:`{q_u}` are such that :math:`F( {q_u} ) = \Delta R_p` is a displacement prescribed by the hijacker;
3. partial bias :math:`{q_{mod} (i)} = {q_{mod} ( {q(i)} )}`, the modification of the properties, and thus displacement, depends on the current "state" of the properties :math:`{q(i)}`.
The hijacking concept described above achieves its goal by only modifying the instantaneous properties of the system. 
As such, it is robust with respect to changes in the implementation of the host algorithm. 
By carefully controlling a series of such manoeuvres, the effect of the host algorithm/integrator can be completely overwritten by another algorithm, without requiring extended knowledge on the specific E/F engine implementation details.


.. _hijacking_fire:

Hijacking the FIRE algorithm
============================

The FIRE (Fast Inertial Relaxation Engine) algorithm [2, 12] is an efficient relaxation algorithm (minimization of energy), which is implemented in most of the E/F engines. 
It uses the forces and velocities computed from a molecular dynamics integration step, to constrain the update of the atomic positions and to steer the dynamics of the structure towards a minimum. 
The molecular dynamics integration can follow different schemes and in the case of FIRE, the semi-implicit Euler integration scheme has been shown to be one of the most robust [12]. 
Hence, we chose to hijack the FIRE algorithm employing that integration scheme, and in the following we discuss hijacking the corresponding implementation.
The atomic positions in the FIRE scheme are updated in each step with :math:`\Delta R = v_{eff}(i)\Delta t`:

.. math:: R(i + 1) = R(i) + v_{eff}(i)\Delta t, 
   :label: FIRE_R_i+1

where the effective velocities :math:`v_{eff}(i)` are given by the modified instantaneous velocities :math:`\widetilde{v}(i)`, and instantaneous forces :math:`F(i)`, as:

.. math:: v_{eff}(i+1) = \widetilde{v}(i)+ \frac{F}{m} \Delta t.
   :label: FIRE_v+1

and the :math:`\widetilde{v}(i)` are computed in a mixing scheme of instantaneous velocities :math:`v(i)` and forces :math:`F(i)`, such that:

.. math:: v(i) = (1 − \alpha)v(i) + \alpha F(i) \frac{||v(i)||}{||F(i)||} 
   :label: FIRE_v

where :math:`\alpha` is a mixing factor. 
The specificity of FIRE is the use of a dot product between the forces and velocities :math:`P = F · v`, which determines the behaviour of the timestep :math:`\Delta t`, and the mixing factor :math:`\alpha`. 
If :mth:`P > 0` for a specified number of sequential steps, then :math:`\Delta t` is increased, else :math:`\Delta t` is decreased and v are set to zero. 
Conversely, if :math:`P > 0`, then :math:`\alpha` is decreased by multiplying it with a factor, else :math:`\alpha` is reset to its original value :math:`\alpha_0`.
As it can be observed in Eq. :eq:`FIRE_R_i+1`, the effective :math:`\Delta R` of the FIRE scheme is given by :math:`\Delta R = v_{eff}(i)\Delta t`, which is computed directly from the instantaneous force :math:`F(i)` (in Eq. :eq:`FIRE_v+1` and :eq:`FIRE_v`), instantaneous velocity :math:`v(i)` (in Eq. :eq:`FIRE_v`), and the mixing factor :math:`\alpha` (in Eq. :eq:`FIRE_v`). 
Additionally, the timestep :math:`\Delta t` is modified by FIRE itself. 
In the spirit of the function :math:`F` from Eq. :eq:`F(q)`, the FIRE scheme can be written as

.. math:: F_{FIRE} : \left\{q_{FIRE}(t)\right\} \rightarrow \Delta R 
   :label: FIRE_F

where :math:`\left\{q_{FIRE}(i)\right\} = \left\{F(i),v(i),\alpha,\Delta t\right\}`.
Thus, hijacking the FIRE scheme is done by accessing and modifying these four instantaneous properties through a call to an external function, before inputting them to FIRE. 
This can be seen as the application of function FFIRE with the properties :math:`\left\{q_{mod}(i)\right\}` given from the hijacker function :math:`G`.
If we set the function :math:`G` such that the velocities :math:`v(i) = 0` and the mixing factor :math:`\alpha = 0`, the mixing scheme in Eq. :eq:`FIRE_v` vanishes, and the function FFIRE depends only on the force :math:`F(i)`, and timestep :math:`\Delta t`.

.. math:: F_{FIRE}( F(i),\Delta t ) = \Delta R = \frac{F(i)}{m} \Delta t\Delta t,
   :label: FIRE_F_2

From the expression of Eq. :eq:`FIRE_F_2` we can construct the hijacking function :math:`G`, as follows. 
Given a prescribed displacement :math:`\Delta R_p`, the modified instantaneous properties are set by:

.. math:: G(\Delta R_p) = \left\{q_{mod}(i)\right\} =\begin{cases}
    \textbf{F}_{mod}(i) = \Delta R_p m/\Delta t^2 \\
    v_{mod}(i) = 0 \\
    \Delta t_{mod} = \Delta t \\
    \alpha_{mod} = 0
    \end{cases} 
   :label: FIRE_G

The function :math:`G` from Eq. :eq:`FIRE_G` is executed in the function applying external conditions on the system, which modifies the instantaneous properties. 
The displacement :math:`\Delta R` computed by FIRE afterwards becomes equal to the prescribed displacement :math:`\Delta R_p`, 

.. math:: F_{FIRE}( \left\{q_{mod}(i)\right\} ) = v_{eff}(i) \Delta t = \frac{F_{mod}(i)}{m} \Delta t \Delta t = \Delta R_p 
   :label: FIRE_F_3

and the atomic positions in Eq. :eq:`R_i+1` are updated as desired, :math:`R(i + 1) = R(i) + \Delta R_p`.
In this way, the FIRE algorithm is successfully hijacked by modifying the instantaneous properties, which are all internal to the main integration algorithm itself, and can thus be accessed and modified by an external function called right after their computation.





