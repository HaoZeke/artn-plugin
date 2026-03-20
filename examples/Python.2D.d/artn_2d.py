
import numpy as np
import pypARTn
import matplotlib.pyplot as plt
from my_function import *


## load libartn.so
artn=pypARTn.artn( engine="other" )

## initialize the 2D function
me=function()

## specify the initial point for ARTn
# xinit = 1.07
# yinit = 0.04
xinit = 15.77
yinit = 16.89
fshift=me.func(xinit,yinit)

## specify ARTn parameters
artn.set( "engine_units", "lammps/metal")
artn.set( "verbose", 3 )
artn.set( "ninit", 2)
artn.set( "nsmooth", 0)
artn.set( "nperp_limitation", np.array([2,4,6]) )
## init push
artn.set( "push_mode", "list")
artn.set( "push_ids", [1])
add_const = np.ndarray([1,4])
z=np.random.rand(2) - 0.5
# hardcode values
# z[0] = -0.05
# z[1] = 0.25
print("initial push is:", z)
add_const[0] = [z[0], z[1], 0.0, 0.0]
artn.set( "push_add_const", add_const )
artn.set( "push_step_size", 0.3 )

## lanczos is limited to size nat*Dim, which in this case == 1*2
artn.set( "lanczos_min_size",0)
artn.set( "lanczos_max_size",2)
artn.set( "lanczos_disp",1e-4)

## the force threshold is interesting to play with
artn.set( "forc_thr",0.05)
artn.set( "eigval_thr", -0.01)
artn.set("nnewchance",3)
maxstep=2000
artn.set( "nevalf_max", maxstep-1)
artn.set( "lpush_final", False )


## =================
## plotting options:
## =================
##
## plot inflection lines
plot_inflection = True
##
## plot normalized force vectors on a grid
plot_force      = True
##
## plot minima basins
plot_basin      = False
##
## compute saddles points analytically over the PES (on a grid) and plot them
compute_saddle  = False
##
## compute minima analytically over the PES (on a grid) and plot them
compute_minima  = False
##
## create animation
animate         = True
##
## export images of the animation
export_imgs     = False
## =================


##
## setup arrays with suitable shape for calling pARTn
##
## we have only "one atom", but need 3 dimensional arrays
nat=1

## the positions array, set z-value to zero; x, and y to initial
pos = np.zeros([nat,3], dtype=np.float64)
pos[0][0] = xinit
pos[0][1] = yinit

## the array to fix certain coords, we completely fix the z-value
if_pos = np.ndarray([nat,3], dtype=np.int32 )
if_pos[0][0]=1
if_pos[0][1]=1
if_pos[0][2]=0

## chemical species
ityp = np.ones([1], dtype=np.int32)

## simulation box (set something big, we don't actually need it)
box = np.zeros([3,3], dtype=np.float64)
box[0][0] = 50.0
box[1][1] = 50.0
box[2][2] = 50.0

## the array to hold forces at each step
force = np.ndarray([nat,3],dtype=np.float64)
## the array to hold displacement vector of each step
displ_vec = np.ndarray([nat,3], dtype=np.float64)


# arrays for plotting later
all_x=[]
all_y=[]
dcode=[]
linit=[]
lperp=[]
llanc=[]
xin=[]
yin=[]
xsad=[]
ysad=[]
# save initial positions for plotting later
all_x.append( pos[0][0] )
all_y.append( pos[0][1] )
xin.append( pos[0][0])
yin.append( pos[0][1])
xsad.append( np.nan )
ysad.append( np.nan )


# computation loop
for istep in range(maxstep):


    # energy is value of function
    etot = me.func( pos[0][0], pos[0][1], fshift )
    # force is -grad(f)
    force[0][0], force[0][1] = me.grad( pos[0][0], pos[0][1] )
    force[0][2] = 0.0
    force *= -1.0


    # get artn step
    displ_vec, lconv = artn.next_displ( nat, etot, force, ityp, pos, box, if_pos )

    if( lconv ):
        # converged, break this loop
        break

    # displace
    pos = pos + displ_vec

    # save current positions for plotting later
    all_x.append( pos[0][0] )
    all_y.append( pos[0][1] )

    # save some flags
    dcode.append( artn.disp_code() )
    linit.append( artn.get_runparam("linit") )
    lperp.append( artn.get_runparam("lperp") )
    llanc.append( artn.get_runparam("llanczos") )
    xin.append(np.nan)
    yin.append(np.nan)
    if( artn.extract("has_sad") ):
        sad_pos = artn.extract("tau_sad")
        xsad.append( sad_pos[0][0] )
        ysad.append( sad_pos[0][1] )
    else:
        xsad.append(np.nan)
        ysad.append(np.nan)


## check if there was any error
ierr,msg=artn.get_error()
if( ierr != 0 ):
    raise ValueError(msg)
# extract saddle
sad_pos = artn.extract("tau_sad")
# all_x.append( sad_pos[0][0] )
# all_y.append( sad_pos[0][1] )
# xsad.append( sad_pos[0][0] )
# ysad.append( sad_pos[0][1] )

## determine the min and max visited coordinates
xmin=min(all_x) - 0.8
xmax=max(all_x) + 0.8
ymin=min(all_y) - 0.8
ymax=max(all_y) + 0.8

fig, ax = plt.subplots(figsize=(8,8), constrained_layout=True)
## setup grid of config space which was visited
isosamples=200
x=np.linspace( xmin, xmax, isosamples )
y=np.linspace( ymin, ymax, isosamples )
X,Y=np.meshgrid(x,y)
Z = me.func( X, Y, fshift )
## plot the function
im=ax.imshow(Z, extent=[xmin, xmax, ymin, ymax], origin="lower", cmap="rainbow" )
ax.contour(X,Y,Z, levels=25, colors="k", linewidths=0.1 )

## two grids: 
xs=np.linspace( xmin, xmax, 40 )
ys=np.linspace( ymin, ymax, 40 )
XS,YS=np.meshgrid(xs,ys)
xdense=np.arange( xmin, xmax, 0.005 )
ydense=np.arange( ymin, ymax, 0.005 )
XD,YD=np.meshgrid(xdense,ydense)

## plot the inflection
if( plot_inflection ):
    lmin = me.hess_eigval( XD, YD )[0]
    lmax = me.hess_eigval( XD, YD )[1]
    # plot contour at value 0.0 => this is the inflection line
    plt.contour( XD, YD, lmin, levels=[0.0], colors="blue", linewidths=0.8 )


## plot force vectors (normalzied)
if( plot_force ):
    # compute the force on smaller grid
    fx,fy = me.grad( XS, YS )
    fx=-fx
    fy=-fy
    fn = np.sqrt( fx**2 + fy**2 )
    # plot force vectors, normalized
    plt.quiver( XS,YS, fx/fn, fy/fn, alpha=0.3, scale=50.0 )

if( plot_basin ):
    lmin_s=me.hess_eigval( XS, YS )[0]
    lmax_s=me.hess_eigval( XS, YS )[1]
    basin_mask= (lmin_s > 0.0) & (lmax_s > 0.0)
    ax.scatter( XS[basin_mask], YS[basin_mask], color="blue", marker="o", alpha=0.5, s=1.8)

## compute the saddle points "analytical"
if( compute_saddle ):
    fdense=me.grad(XD,YD)
    fdense_n = np.sqrt( fdense[0]**2 + fdense[1]**2 )
    saddle_mask = ( lmin < artn.get_param("eigval_thr")) & \
                   (lmax > 0.0) & \
                   (fdense_n < artn.get_param("forc_thr") )
    plt.scatter( XD[saddle_mask], YD[saddle_mask], color="magenta")

## compute the minima "analytical"
if( compute_minima ):
    fdense=me.grad(XD,YD)
    fdense_n = np.sqrt( fdense[0]**2 + fdense[1]**2 )
    min_mask = (lmin >0.0) & (lmax >0.0) & (fdense_n < artn.get_param("forc_thr") )
    plt.scatter( XD[min_mask], YD[min_mask], color="yellow")




##
## plot all visited positions as points
ax.plot( all_x, all_y,
         marker='.', markersize=3, #mec="black", mfc="black",
         # linestyle="-", color="black", linewidth=0.0,
         linestyle="--", color="black", linewidth=0.8,
         label="ARTn path", visible=True
        )

# initial point
ax.plot( xin, yin, marker="x", color="black", markersize=8.0 )

# saddle
ax.plot( sad_pos[0][0], sad_pos[0][1], marker="o", color="black", markersize=8)


fig.colorbar(im,ax=ax, shrink=0.9)
# ax.set_xticks([])
# ax.set_yticks([])

# fig.savefig("path.png", dpi=80, format="png", transparent=False)
plt.show()



###
### animation
###
if( animate ):
    import matplotlib.animation as animation

    fig, ax = plt.subplots(figsize=(8,8),constrained_layout=True)
    ax.set_xticks([])
    ax.set_yticks([])
    im=ax.imshow(Z, extent=[xmin, xmax, ymin, ymax], origin="lower", cmap="rainbow" )
    plt.contour(X,Y,Z, levels=25, colors="k", linewidths=0.1 )
    # plt.contour( XD, YD, lmin, levels=[0.0], colors="blue", linewidths=0.8, algorithm="mpl2005")
    # plt.quiver( XS,YS, fx/fn, fy/fn, alpha=0.4, scale=50.0 )
    line, = ax.plot([],[], marker=".",markersize=4,linestyle="--",linewidth=0.8, color="black")
    # dots, = ax.plot([],[], "ro", markersize=2 )
    # lanc, = ax.plot([],[], "*", markersize=8, mfc="yellow", mec="black" )
    ini, = ax.plot([],[],"x", markersize=8, color="black" )
    sad, = ax.plot([],[],"o", markersize=8, color="black" )
    ax.set_ylim(ymin, ymax)
    ax.set_xlim(xmin, xmax)

    def update(frame):
        if( frame-10 < 0 ):
            i = 1
        elif( frame-10 < len(xsad) ):
            i = frame-10+1
        else:
            i = len(xsad)-1

        line.set_xdata( all_x[0:i] )
        line.set_ydata( all_y[0:i] )
        ini.set_xdata( xin[0:i])
        ini.set_ydata( yin[0:i])
        sad.set_xdata( xsad[0:i])
        sad.set_ydata( ysad[0:i])

        # dots.set_xdata( perpx[0:i] )
        # dots.set_ydata( perpy[0:i] )
        # lanc.set_xdata( lancx[0:i] )
        # lanc.set_ydata( lancy[0:i] )
        return line, ini, sad #dots, lanc

    ani = animation.FuncAnimation(fig, update, frames=len(xsad)+20, interval=80, repeat=True, repeat_delay=2000)
    fig.colorbar(im,ax=ax,shrink=0.9)
    plt.show()
    # ani.save( "anim_1.gif", writer="pillow", fps=20, optimize=True )


##
## export images of animation
##
if( export_imgs ):
    for step in range(len(xsad)+20):
        fig,ax=plt.subplots(figsize=(8,8),constrained_layout=True)
        ax.set_xticks([])
        ax.set_yticks([])
        im=ax.imshow(Z, extent=[xmin, xmax, ymin, ymax], origin="lower", cmap="rainbow" )
        plt.contour(X,Y,Z, levels=25, colors="k", linewidths=0.1 )
        plt.colorbar(im,ax=ax,shrink=0.9)

        imin=0
        if( step-10 < 0 ):
            imax=1
        elif( step-10+1 < len(xsad) ):
            imax = step-10+1
        else:
            imax = len(xsad)-1

        print(step, imax )
        ax.plot( all_x[imin:imax], all_y[imin:imax], \
             marker='.', markersize=4, mec="black", mfc="black", \
             linestyle="--", color="black", linewidth=0.8, label="ARTn path", visible=True )
        ax.plot( xinit, yinit, marker="x", markersize=8, color="black" )
        ax.plot( xsad[imin:imax], ysad[imin:imax], marker="o", markersize=8, color="black" )

        fig.savefig("im_"+str(step)+".png", dpi=80, format="png", transparent=False)
        plt.close(fig)
