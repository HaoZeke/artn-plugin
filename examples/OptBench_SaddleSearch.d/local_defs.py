import numpy as np
import random


class conf:

    ## single configuration after artn run.
    ## contains saddle point info, and initial connected min
    def __init__(self):
        self.nat = 0
        self.lat = None
        self.success=False
        self.sad_typ = None
        self.sad_pos = None
        self.sad_ener = None
        self.min_typ = None
        self.min_pos = None
        self.min_ener = None
        self.Eb = None
        self.connected = False
        self.dr = 0.0
        self.nevalf = 0
        self.cr_count = 0

    def print(self, stage = None, fstream=None ):
        '''
        print single conf
        '''
        # choose which stage we print, by default is "sad"
        pos = self.sad_pos
        typ = self.sad_typ
        Eb = self.Eb
        ener = self.sad_ener
        if stage == "min":
            pos = self.min_pos
            typ = self.min_typ
            Eb = 999.9
            ener = self.min_ener

        print( self.nat, file=fstream )
        print( 'Lattice="',\
               self.lat[0][0], self.lat[0][1], self.lat[0][2], \
               self.lat[1][0], self.lat[1][1], self.lat[1][2], \
               self.lat[2][0], self.lat[2][1], self.lat[2][2], \
               '" properties=species:S:1:pos:R:3:id:I:1 energy:',ener, "barrier:",Eb, file=fstream)
        for i in range(self.nat):
            print( typ[i], \
                  "{:9.5f}".format(pos[i][0]), "{:9.5f}".format(pos[i][1]), "{:9.5f}".format(pos[i][2]), \
                  i+1,\
                  file=fstream )

    def extract_conf( self, artn ):
        '''
        extract the conf from artn instance:
        obtain the saddle conf, and initial minimum to determine connectivity of saddle
        '''
        err = artn.extract( "has_error" )
        self.success = not err
        if( err ):
            return

        self.nat = artn.extract("natoms")
        lat = artn.extract("lat")
        self.lat = lat.T
        self.nevalf = artn.extract( "nevalf" )
        self.cr_count = artn.get_runparam( "inewchance" )
        # sad conf
        self.sad_typ = artn.extract("typ_sad")
        self.sad_pos = artn.extract("tau_sad")
        self.sad_ener = artn.extract("etot_sad")

        # max z value threshold: protection against atoms that fly away
        zmax = 17.0
        z = 0.0
        for i in range(self.nat):
           z = max( z, self.sad_pos[i][2] )
           if( z > zmax ):
              # atoms fly
              print("!!! atoms fly?")
              self.success = False
              return


        ## determine which min is closer to init
        dr1 = artn.extract("delr_min1")
        dr2 = artn.extract("delr_min2")
        if( dr1 < dr2 ):
            con = 1
        else:
            con=2

        if( con == 1):
            self.min_typ = artn.extract("typ_min1")
            self.min_pos = artn.extract("tau_min1")
            self.min_ener = artn.extract("etot_min1")
            self.dr = dr1
        elif( con == 2):
            self.min_typ = artn.extract("typ_min2")
            self.min_pos = artn.extract("tau_min2")
            self.min_ener = artn.extract("etot_min2")
            self.dr = dr2

        ## compute barrier
        self.Eb = self.sad_ener - self.min_ener

        ## check if min is connected
        connect_threshold = 0.5
        con = 0
        if( dr1 < connect_threshold ):
            con = 1
        elif( dr2 < connect_threshold ):
            con = 2

        self.connected = True
        ## conf is not connected
        if( con == 0 ):
            self.connected = False

        return







class catalogue:
    ## catalogue of found structures, and run info
    def __init__(self):
        self.nrun = 0
        self.Nf = 0
        self.n_conf = 0
        self.conf = []
        self.n_artn_fail = 0
        self.n_disconnected = 0
        self.n_connected = 0
        self.n_Eb_too_high = 0
        self.n_identical = 0
        # count how many times the same conf is found
        self.count = []
        self.cr_count = 0


    def _check_unique( self, conf):
        '''
        return logical `isnew=True` when conf is new
        return index `idx=m` with the index of conf in catalogue,
               which is equivalent to input conf when `isnew=False`
        '''
        # check if conf is unique in catalogue

        # if d value below thr, confs are equal
        d_thr = 0.1

        # energy difference threshold
        ediff_thr = 0.05

        isnew = True
        idx = -99
        # for all confs already in catalogue
        for i in range(self.n_conf):
           # check on energy
           ediff = conf.Eb - self.conf[i].Eb
           # compute distance
           d = dist( conf, self.conf[i] )
           # print( "check unique", i, d)
           if( d < d_thr and abs(ediff) < ediff_thr ):
              # print( "check unique", i, d)
              # conf is already in catalogue
              isnew = False
              idx = i
              break
        return isnew, idx


    def add_conf(self, conf ):
        '''
        add conf to catalogue if it is new, and increase counters.
        '''
        ## count nevalf
        self.Nf += conf.nevalf

        ## count all cr encountered
        self.cr_count += conf.cr_count

        ## count artn failures
        if( not conf.success ):
            self.n_artn_fail += 1
            return False

        ## check if conf is new
        isnew, idx = self._check_unique( conf )

        ## conf is new
        if( isnew ):
            self.n_conf += 1
            self.conf.append(conf)
            # new entry in counter
            self.count.append(1)
        else:
            ## conf is already known
            self.count[idx] += 1
            self.n_identical += 1

        ## conf is connected or not?
        if( conf.connected ):
            self.n_connected += 1
        else:
            self.n_disconnected += 1
        return isnew


    def print_conf(self, i):
        '''
        print single configuration from the catalogue
        '''
        self.conf[i].print()


    def print_barriers(self, sort=True):
        '''
        print all barriers in the catalogue
        '''
        # create local array of Ebs
        ebs=[]
        for i in self.conf:
           ebs.append(i.Eb)
        if sort:
           # indices that sort Eb
           o = np.argsort(ebs)
        else:
           # array of [0, 1, 2, 3, etc.]
           o = np.linspace(0, self.n_conf-1, self.n_conf, dtype = int)

        # {:>6} means right aligned with 6 places
        print( "{:>6}".format("i"), \
               "{:>6}".format("i_orig"), \
               "{:>12}".format("E_barrier"), \
               "{:>6}".format("count") )
        for i in range(self.n_conf):
           print( "{:6}".format(i), \
                  "{:6}".format(o[i]),\
                  "{:12.6f}".format(self.conf[o[i]].Eb), \
                  "{:6}".format(self.count[o[i]]) )


    def print_run_info(self):
        '''
        print the details of the catalogue
        '''
        print( "===== info of the current run: ====")
        print( "N searches:", self.nrun )
        print( "N force calls:",self.Nf)
        print( "N good conf:", self.n_conf )
        print( "N artn fail:", self.n_artn_fail )
        print( "N disconnected:", self.n_disconnected )
        print( "N connected:", self.n_connected )
        # print( "N Eb beyond 1.5:",self.n_Eb_too_high)
        print( "N identical conf found:",self.n_identical)
        print( "N CR:", self.cr_count)
        print( "===================================")


    def print_catalogue(self, filename=None, sort=True ):
        '''
        Print all structures in the catalogue to screen or file
        '''
        # create local array of Ebs
        ebs=[]
        for i in self.conf:
           ebs.append(i.Eb)
        if sort:
           # indices that sort Eb
           o = np.argsort(ebs)
        else:
           # array of [0, 1, 2, 3, etc.]
           o = np.linspace(0, self.n_conf-1, self.n_conf, dtype = int)

        f = None
        if filename is not None:
           f = open( filename, "w" )

        for i in range(self.n_conf):
           self.conf[o[i]].print(fstream=f)

        if filename is not None:
           f.close()


def dist( conf_A, conf_B, dthr=None):
    '''
    compute distance between conf_A and conf_B
    '''
    # import ira_mod
    # ira = ira_mod.IRA()
    # found, dists = ira.cshda( conf_A.nat, conf_A.sad_typ, conf_A.sad_pos, \
    #                           conf_B.nat, conf_B.sad_typ, conf_B.sad_pos, \
    #                           lat=conf_A.lat, thr=dthr )
    # d = np.max(dists)

    ## WARNING: this is not done in pbc
    d = 0.0
    for i in range( conf_A.nat ):
        rij = conf_A.sad_pos[i] - conf_B.sad_pos[i]
        d = max( d, np.linalg.norm(rij) )
    return d


def gen_random_v( nat, idcs, dmin, dmax ):
   '''
   generate random push vec of size (nat,3), which has nonzero values on indices
   specified by `idcs` array.
   Each atom gets a random displacement with norm in the range [dmin:dmax]
   On input, `dmin` and `dmax` should be in the units of Ang.
   '''
   N = len( idcs )
   # generate for N atoms
   v = np.random.rand(N,3)
   v = v - np.array([0.5, 0.5, 0.0])
   # set all z components to zero
   for i in range(N):
      v[i][2] = 0.0

   # switch to bohrradius
   dmin = dmin/0.529177
   dmax = dmax/0.529177
   for i in range(N):
      r = v[i]
      r = r/np.linalg.norm(r)
      dsize = random.uniform(dmin, dmax)
      r = r*dsize
      v[i] = r
   # set final vec to idcs from input: idcs start at 0
   vec = np.zeros((nat,3), dtype = float)
   for i in range(len(idcs)):
      j = idcs[i]
      vec[j] = v[i]
   return vec
