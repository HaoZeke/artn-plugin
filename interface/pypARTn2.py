from ctypes import *
from os.path import dirname,abspath,join
from inspect import getsourcefile
import numpy as np

class artn():

    # _ARTN_DTYPE_UNKNOWN = -1
    # _ARTN_DTYPE_INT     = 1
    # _ARTN_DTYPE_REAL    = 2
    # _ARTN_DTYPE_BOOL    = 3
    # _ARTN_DTYPE_STR     = 4

    def __init__( self, engine=None, shlib=None ):
        '''
        create a new instance.

        **== example: ==**

           >>> import pypARTn
           >>> artn = pypARTn.artn( engine="lmp" )

        '''
        ## class constructor
        if engine == None and shlib==None:
            msg = "Please specify the engine through keyword 'engine'. Possible values: ['lmp', 'other']."
            raise ValueError( msg )
        # path to this file
        mypath=dirname(abspath(getsourcefile(lambda:0)))
        # one dir up
        mypath = dirname(mypath)

        # name of the lib according to engine
        libname=None
        if engine == "lammps" or engine == "lmp":
            libname = "lib/libartn-lmp.so"
        elif engine == "other":
            libname ="lib/libartn.so"
        elif engine != None:
            msg = "Unknown value for 'engine': "+ engine
            raise ValueError( msg )

        if libname != None:
            path = join(mypath, libname )

        # user provide path
        if shlib:
            path = shlib
        self.lib = CDLL(path)


        self.lib.artn_create.restype = c_int
        ierr = self.lib.artn_create()
        self._alive = True

        # some common function
        self.lib.get_artn_dtype.restype = c_int
        self.lib.get_artn_dtype.argtypes = [ c_char_p ]
        self.lib.get_artn_drank.restype = c_int
        self.lib.get_artn_drank.argtypes = [ c_char_p ]
        self.lib.get_artn_dsize.restype = c_int
        self.lib.get_artn_dsize.argtypes = [c_char_p, POINTER(POINTER(c_int)) ]

        # get the ARTN_DTYPE_* values
        self.lib.get_dtype_val.restype=c_int
        self.lib.get_dtype_val.argtypes=[c_char_p]
        self._ARTN_DTYPE_UNKNOWN = self.lib.get_dtype_val( "ARTN_DTYPE_UNKNOWN".encode() )
        self._ARTN_DTYPE_INT  = self.lib.get_dtype_val( "ARTN_DTYPE_INT".encode() )
        self._ARTN_DTYPE_REAL = self.lib.get_dtype_val( "ARTN_DTYPE_REAL".encode() )
        self._ARTN_DTYPE_BOOL = self.lib.get_dtype_val( "ARTN_DTYPE_BOOL".encode() )
        self._ARTN_DTYPE_STR  = self.lib.get_dtype_val( "ARTN_DTYPE_STR".encode() )

    def destroy(self):
        # call some destructor
        self._alive = False
        return

    def __del__(self):
        ## class destructor
        if self._alive:
           self.destroy()
        return

    def _my_rank_type(self, val):
        ## return pyrank and pytyp of the input val
        ## the pytyp follows dtype encoders
        pyrank = np.ndim(val)

        # choose value to test:: for arrays need a single element
        # assume all elements in array are of the same type...
        testval = val
        if pyrank == 1:
            testval = val[0]
        elif pyrank == 2:
            testval = val[0][0]

        pytyp = self._ARTN_DTYPE_UNKNOWN
        # check if testval is instance of any of these
        if isinstance( testval, (int, np.int32, np.int64) ):
            pytyp = self._ARTN_DTYPE_INT
        if isinstance( testval, (float, np.float32, np.float64)):
            pytyp = self._ARTN_DTYPE_REAL
        # bool instance is also detected as int, need to overwrite pytyp
        if isinstance( testval, (bool) ):
            pytyp = self._ARTN_DTYPE_BOOL
        if isinstance( testval, (str) ):
            pytyp = self._ARTN_DTYPE_STR

        # check if all elements of array are of the same dtyp
        eq = True
        m = type(testval)
        if pyrank == 1:
            for i in val:
                if type(i) != m:
                    eq = False
        if pyrank == 2:
            for v in val:
                for i in v:
                    if type(i) != m:
                        eq = False
        if not eq:
            msg = "All values in input array should be of equal type!"+\
                "\n >> Input value:\n"+str(val)
            raise ValueError( msg )

        return pyrank, pytyp

    def _dtypstr(self, dtyp ):
        ## return string corresponding to dtype encoder value
        self.lib.get_dtype_str.restype=c_char_p
        self.lib.get_dtype_str.argtypes=[c_int]
        ctyp = c_int(dtyp)
        cstr = self.lib.get_dtype_str( ctyp )
        if cstr.decode()=="invalid":
            msg = "error in _dtypestr, unknown dtyp value: "+str(dtyp)
            raise ValueError(msg)
        return cstr.decode()


    def set( self, name, val ):
        """
        Alternative name for ``set_param()``

        **== Example: ==**

           >>> artn.set( "verbose", 0 )

        """
        return self.set_param( name, val )


    def set_param( self, name, val ):
        """
        Set a value to an artn user parameter (module artn_params).

        **== input: ==**

        :param name: string of name of the artn variable.
        :type name: string

        :param val: value of the variable to be set
        :type val: same type as the corresponding ARTn variable

        **== output: ==**

        None

        **== Example: ==**

           >>> artn.set_param( "verbose", 0 )

        Where applicable, the input variables should be in same units as in the input file, which
        is units defined by the `engine_units` variable.
        """
        # encode name to C
        cname=name.encode()

        # get py rank and dtyp
        pyrank, pytyp = self._my_rank_type( val )

        # get expected dtype
        ctyp=self.lib.get_artn_dtype( cname )
        if ctyp < 0:
            msg = "unknown datatype for name: "+name
            raise ValueError(msg)

        # check consistency of datatype
        if pytyp != ctyp:
            msg="Wrong datatype in input! Expected:"+self._dtypstr(ctyp)+" Got:"+self._dtypstr(pytyp) +\
                "\n >> Input value:\n"+str(val)
            raise ValueError(msg)

        # get expected drank
        crank = self.lib.get_artn_drank( cname )

        # check consistency of rank
        if pyrank != crank:
            msg="Wrong rank in input! Expected:"+str(crank)+" Got:"+str(pyrank)+\
                "\n >> Input value:\n"+str(val)
            raise ValueError(msg)

        # prepare size array
        if crank == 0:
            s = np.array( [1] )
        elif crank == 1:
            s = np.array( [np.size(val)] )
        elif crank == 2:
            # reverse the order to not get transpose
            s = np.array( [np.size(val,1), np.size(val,0)])
        else:
            msg = "rank not implemented in pypARTn: "+crank+\
                "\n >> Input value:\n"+str(oval)
            raise ValueError( msg )

        s = np.intc(s)
        csize = s.ctypes.data_as( POINTER(c_int) )


        # prepare the values
        if ctyp == self._ARTN_DTYPE_INT:
            # create an array
            val = np.intc( [val] )
            # cast it as c_void_p
            cval = val.ctypes.data_as( c_void_p )
        elif ctyp == self._ARTN_DTYPE_REAL:
            val = np.float64( [val] )
            cval = val.ctypes.data_as( c_void_p )
        elif ctyp == self._ARTN_DTYPE_BOOL:
            val = np.bool_( [val] )
            cval = val.ctypes.data_as( c_void_p )
        elif ctyp == self._ARTN_DTYPE_STR:
            # encode str
            val = val.encode()
            # put it in buffer
            cval = create_string_buffer( val )
            # cast the buffer as c_void_p
            cval = cast( cval, c_void_p )
        else:
            msg="datatype not supported in pypARTn:" +self._dtypstr(ctyp)
            print("Input value: ",oval)
            raise ValueError( msg )


        self.lib.set_param.restype = c_int
        self.lib.set_param.argtypes = [c_char_p, c_int, (POINTER(c_int)), c_void_p ]

        # cerr = self.lib.set_param( cname, crank, byref(csize), byref(cval) )
        cerr = self.lib.set_param( cname, crank, csize, cval )

        if cerr != 0 :
            raise ValueError("err here")

        return


    def get_param( self, name ):
        '''
        Get the value of artn user parameter (module artn_params).

        **== input: ==**
        :param name: Name of the artn variable you wish to extract.
        :type name: string

        **== output: ==**
        :param dval: value of desired artn variable
        :type dval: same type as corresponding artn variable (np.int32, np.float64, or np.array with same type)

        **== example: ==**

           >>> fthr = artn.get_param( "forc_thr" )
           >>> pushid = artn.get_param( "push_ids" )

        '''

        self.lib.get_param.restype = c_int
        self.lib.get_param.argtypes = [ c_char_p, c_void_p ]

        cname = name.encode()

        cdat = c_void_p()

        cerr = self.lib.get_param( cname, byref(cdat) )
        if cerr != 0:
            msg = "Error in get_data"
            raise ValueError( msg )

        # get dtype
        ctyp=self.lib.get_artn_dtype( cname )

        # cast data to proper type
        if ctyp == self._ARTN_DTYPE_INT:
            val = cast( cdat, POINTER(c_int) )
        elif ctyp == self._ARTN_DTYPE_REAL:
            val = cast( cdat, POINTER(c_double) )
        elif ctyp == self._ARTN_DTYPE_BOOL:
            val = cast( cdat, POINTER(c_bool) )
        elif ctyp == self._ARTN_DTYPE_STR:
            val = cast( cdat, c_char_p )
            return val.value.decode()
        else:
            msg = "data type not implemented in python interf to artn!"
            raise ValueError( msg )

        # get drank
        crank = self.lib.get_artn_drank( cname )

        if crank == 0:
            return val.contents.value
        else:
            # get dsize
            csize = POINTER(c_int)()
            self.lib.get_artn_dsize( cname, byref(csize) )
            dsize = np.ctypeslib.as_array(csize,shape=[crank])
            # reverse the size array, otherwise we get transpose
            dsize = dsize[::-1]

            dval = np.ctypeslib.as_array( val, shape=dsize )
            return dval




    def set_data( self, name, val ):
        """
        Set a value to art data variable (module m_artn_data).

        **== input: ==**
        :param name: string of name of the artn variable.
        :type name: string

        :param val: value of the variable to be set
        :type val: same type as the corresponding ARTn variable

        **== output: ==**
        None

        **== Example: ==**

           >>> my_sad_array = np.ndarray([natoms, 3] ... )
           >>> artn.set_data( "tau_sad", my_sad_array )

        Where applicable, the variables should be in ARTn units
        """

        # encode name to C
        cname=name.encode()

        # get py rank and dtyp
        pyrank, pytyp = self._my_rank_type( val )

        # get expected dtype
        ctyp=self.lib.get_artn_dtype( cname )
        if ctyp < 0:
            msg = "unknown datatype for name: "+name
            raise ValueError(msg)

        # check consistency of datatype
        if pytyp != ctyp:
            msg="Wrong datatype in input! Expected:"+self._dtypstr(ctyp)+" Got:"+self._dtypstr(pytyp) +\
                "\n >> Input value:\n"+str(val)
            raise ValueError(msg)

        # get expected drank
        crank = self.lib.get_artn_drank( cname )

        # check consistency of rank
        if pyrank != crank:
            msg="Wrong rank in input! Expected:"+str(crank)+" Got:"+str(pyrank)+\
                "\n >> Input value:\n"+str(val)
            raise ValueError(msg)

        # prepare size array
        if crank == 0:
            s = np.array( [1] )
        elif crank == 1:
            s = np.array( [np.size(val)] )
        elif crank == 2:
            # reverse the order to not get transpose
            s = np.array( [np.size(val,1), np.size(val,0)])
        else:
            msg = "rank not implemented in pypARTn: "+crank+\
                "\n >> Input value:\n"+str(oval)
            raise ValueError( msg )

        s = np.intc(s)
        csize = s.ctypes.data_as( POINTER(c_int) )


        # prepare the values
        if ctyp == self._ARTN_DTYPE_INT:
            # create an array
            val = np.intc( [val] )
            # cast it as c_void_p
            cval = val.ctypes.data_as( c_void_p )
        elif ctyp == self._ARTN_DTYPE_REAL:
            val = np.float64( [val] )
            cval = val.ctypes.data_as( c_void_p )
        elif ctyp == self._ARTN_DTYPE_BOOL:
            val = np.bool_( [val] )
            cval = val.ctypes.data_as( c_void_p )
        elif ctyp == self._ARTN_DTYPE_STR:
            # encode str
            val = val.encode()
            # put it in buffer
            cval = create_string_buffer( val )
            # cast the buffer as c_void_p
            cval = cast( cval, c_void_p )
        else:
            msg="datatype not supported in pypARTn:" +self._dtypstr(ctyp)
            print("Input value: ",oval)
            raise ValueError( msg )


        self.lib.set_data.restype = c_int
        self.lib.set_data.argtypes = [c_char_p, c_int, (POINTER(c_int)), c_void_p ]

        # cerr = self.lib.set_param( cname, crank, byref(csize), byref(cval) )
        cerr = self.lib.set_data( cname, crank, csize, cval )

        if cerr != 0 :
            raise ValueError("err here")

        return

    def extract( self, name ):
        """
        Alternative name for `get_data()`

        **== example: ==**

           >>> e_sad = artn.extract( "etot_sad" )
           >>> pos_min2 = artn.extract( "tau_min2" )

        """
        return self.get_data( name )

    def get_data( self, name ):
        '''
        Get the value of artn data variable (module m_artn_data).

        **== input: ==**

        :param name: Name of the artn variable you wish to extract.
        :type name: string

        **== output: ==**

        :param dval: value of desired artn variable
        :type dval: same type as corresponding artn variable (np.int32, np.float64, or np.array with same type)

        **== example: ==**

           >>> e_sad = artn.get_data( "etot_sad" )
           >>> pos_min2 = artn.get_param( "tau_min2" )

        Where applicable, the returned value is in units specified by `engine_units`
        '''

        self.lib.get_data.restype = c_int
        self.lib.get_data.argtypes = [ c_char_p, c_void_p ]

        cname = name.encode()

        cdat = c_void_p()

        cerr = self.lib.get_data( cname, byref(cdat) )
        if cerr != 0:
            msg = "Error in get_data"
            raise ValueError( msg )

        # get dtype
        ctyp=self.lib.get_artn_dtype( cname )

        # cast data to proper type
        if ctyp == self._ARTN_DTYPE_INT:
            val = cast( cdat, POINTER(c_int) )
        elif ctyp == self._ARTN_DTYPE_REAL:
            val = cast( cdat, POINTER(c_double) )
        elif ctyp == self._ARTN_DTYPE_BOOL:
            val = cast( cdat, POINTER(c_bool) )
        elif ctyp == self._ARTN_DTYPE_STR:
            val = cast( cdat, c_char_p )
            return val.value.decode()
        else:
            msg = "data type not implemented in python interf to artn!"
            raise ValueError( msg )

        # get drank
        crank = self.lib.get_artn_drank( cname )

        if crank == 0:
            return val.contents.value
        else:
            # get dsize
            csize = POINTER(c_int)()
            self.lib.get_artn_dsize( cname, byref(csize) )
            dsize = np.ctypeslib.as_array(csize,shape=[crank])
            # reverse the size array, otherwise we get transpose
            dsize = dsize[::-1]

            dval = np.ctypeslib.as_array( val, shape=dsize )
            return dval


    def set_runparam( self, name, val ):
        """
        Set a value to an artn runtime variable (module artn_params).

        **== input: ==**

        :param name: string of name of the artn variable.
        :type name: string

        :param val: value of the variable to be set
        :type val: same type as the corresponding ARTn variable

        **== output: ==**

        None

        **== Example: ==**

           >>> artn.set_runparam( "lperp", True )

        Where applicable, the input variables should be in units of ARTn
        """

        # encode name to C
        cname=name.encode()

        # get py rank and dtyp
        pyrank, pytyp = self._my_rank_type( val )

        # get expected dtype
        ctyp=self.lib.get_artn_dtype( cname )
        if ctyp < 0:
            msg = "unknown datatype for name: "+name
            raise ValueError(msg)

        # check consistency of datatype
        if pytyp != ctyp:
            msg="Wrong datatype in input! Expected:"+self._dtypstr(ctyp)+" Got:"+self._dtypstr(pytyp) +\
                "\n >> Input value:\n"+str(val)
            raise ValueError(msg)

        # get expected drank
        crank = self.lib.get_artn_drank( cname )

        # check consistency of rank
        if pyrank != crank:
            msg="Wrong rank in input! Expected:"+str(crank)+" Got:"+str(pyrank)+\
                "\n >> Input value:\n"+str(val)
            raise ValueError(msg)

        # prepare size array
        if crank == 0:
            s = np.array( [1] )
        elif crank == 1:
            s = np.array( [np.size(val)] )
        elif crank == 2:
            # reverse the order to not get transpose
            s = np.array( [np.size(val,1), np.size(val,0)])
        else:
            msg = "rank not implemented in pypARTn: "+crank+\
                "\n >> Input value:\n"+str(oval)
            raise ValueError( msg )

        s = np.intc(s)
        csize = s.ctypes.data_as( POINTER(c_int) )


        # prepare the values
        if ctyp == self._ARTN_DTYPE_INT:
            # create an array
            val = np.intc( [val] )
            # cast it as c_void_p
            cval = val.ctypes.data_as( c_void_p )
        elif ctyp == self._ARTN_DTYPE_REAL:
            val = np.float64( [val] )
            cval = val.ctypes.data_as( c_void_p )
        elif ctyp == self._ARTN_DTYPE_BOOL:
            val = np.bool_( [val] )
            cval = val.ctypes.data_as( c_void_p )
        elif ctyp == self._ARTN_DTYPE_STR:
            # encode str
            val = val.encode()
            # put it in buffer
            cval = create_string_buffer( val )
            # cast the buffer as c_void_p
            cval = cast( cval, c_void_p )
        else:
            msg="datatype not supported in pypARTn:" +self._dtypstr(ctyp)
            print("Input value: ",oval)
            raise ValueError( msg )


        self.lib.set_runparam.restype = c_int
        self.lib.set_runparam.argtypes = [c_char_p, c_int, (POINTER(c_int)), c_void_p ]

        # cerr = self.lib.set_param( cname, crank, byref(csize), byref(cval) )
        cerr = self.lib.set_runparam( cname, crank, csize, cval )

        if cerr != 0 :
            raise ValueError("err here")

        return


    def get_runparam( self, name ):
        '''
        Get the value of artn runtime variable (module artn_params).

        **== input: ==**

        :param name: Name of the artn variable you wish to extract.
        :type name: string

        **== output: ==**

        :param dval: value of desired artn variable
        :type dval: same type as corresponding artn variable (np.int32, np.float64, or np.array with same type)

        **== example: ==**

           >>> inc = artn.get_runparam( "inewchance" )
           >>> iperp = artn.get_runparam( "iperp" )
           >>> llanc = artn.get_runparam( "llanczos" )

        '''
        self.lib.get_runparam.restype = c_int
        self.lib.get_runparam.argtypes = [ c_char_p, c_void_p ]

        cname = name.encode()

        cdat = c_void_p()

        cerr = self.lib.get_runparam( cname, byref(cdat) )
        if cerr != 0:
            msg = "Error in get_data"
            raise ValueError( msg )

        # get dtype
        ctyp=self.lib.get_artn_dtype( cname )

        # cast data to proper type
        if ctyp == self._ARTN_DTYPE_INT:
            val = cast( cdat, POINTER(c_int) )
        elif ctyp == self._ARTN_DTYPE_REAL:
            val = cast( cdat, POINTER(c_double) )
        elif ctyp == self._ARTN_DTYPE_BOOL:
            val = cast( cdat, POINTER(c_bool) )
        elif ctyp == self._ARTN_DTYPE_STR:
            val = cast( cdat, c_char_p )
            return val.value.decode()
        else:
            msg = "data type not implemented in python interf to artn!"
            raise ValueError( msg )

        # get drank
        crank = self.lib.get_artn_drank( cname )

        if crank == 0:
            return val.contents.value
        else:
            # get dsize
            csize = POINTER(c_int)()
            self.lib.get_artn_dsize( cname, byref(csize) )
            dsize = np.ctypeslib.as_array(csize,shape=[crank])
            # reverse the size array, otherwise we get transpose
            dsize = dsize[::-1]

            dval = np.ctypeslib.as_array( val, shape=dsize )
            return dval

    def get_error( self ):
        self.lib.get_error.restype=c_int
        self.lib.get_error.argtypes=[c_void_p]

        vmsg = c_void_p()
        cerr = self.lib.get_error( byref(vmsg) )
        msg = None
        if( cerr < 0 ):
            msg = cast( vmsg, c_char_p )
            msg = msg.value.decode()
        return cerr, msg

    def reset_input( self ):
        '''
        Reset the user parameters (module artn_params) to their default values.
        This will erase any data set by set_param() function.

        **== example: ==**

           >>> ## set custom value of input parameter
           >>> artn.set_param( "lanczos_max_size", 23 )
           >>> artn.get_param( "lanczos_max_size" )
           23
           >>> ##
           >>> ## reset default values
           >>> artn.reset_input()
           >>> artn.get_param( "lanczos_max_size" )
           16

        '''
        self.lib.reset_params.restype=None
        self.lib.reset_params.argtypes=None

        self.lib.reset_params()
        return


    def list_set( self ):
        '''
        List the variable names that can be set with the `set()` function.
        '''
        self.lib.artn_list_set.restype=None
        self.lib.artn_list_set.argtypes=[]
        self.lib.artn_list_set()
        return

    def list_extract( self ):
        '''
        List the variable names that can be extracted from a finished artn calculation,
        using the `extract()` function.
        '''
        self.lib.artn_list_extract.restype=None
        self.lib.artn_list_extract.argtypes=[]
        self.lib.artn_list_extract()
        return

    def dump_input( self, fname ):
        '''
        Dump the currently set input parameters into a file <fname>, which can
        be used as regular ARTn input file.
        '''
        self.lib.dump_input.restype=None
        self.lib.dump_input.argtypes=[c_char_p]

        self.lib.dump_input( fname.encode() )
        return

    def dump_data( self, fname ):
        '''
        Dump the data generated in currently finished ARTn exploration into file <fname>,
        for later reading.

        **== example: ==**

           >>> ## ----
           >>> ## perform regular artn computation
           >>> ## ----
           >>> ##
           >>> ## dump the generated data to file
           >>> artn.dump_data( "my_artn_dump.dat" )
           >>> ##
           >>> ## quit python

        '''
        self.lib.dump_data.restype=None
        self.lib.dump_data.argtypes=[c_char_p]
        self.lib.dump_data( fname.encode() )
        return

    def read_datadump( self, fname ):
        '''
        Read the ARTn datadump file <fname> produced by `data_dump()`, and fill the variables
        of `module m_artn_data`. After the datadump is read, values can be obtained by `get_data()`

        **== exmaple: ==**

           >>> ## fresh artn instance
           >>> artn = pypARTn.artn( engine="lmp" )
           >>> ##
           >>> ## read datadump from previous computation
           >>> artn.read_datadump( "my_artn_dump.dat" )
           >>> ##
           >>> ## access data
           >>> etot = artn.get_data( "etot_sad" )

        '''
        self.lib.read_datadump.restype=c_int
        self.lib.read_datadump.argtypes=[c_char_p]
        return self.lib.read_datadump( fname.encode() )

    def serialize_run( self ):
        '''
        Tell pART to serialze the exploration. This means the present instance of the process can
        safely quit after this command, and launch a separate process for the engine+pART.
        The data generated by pART will be dumped to a special file,
        for later reading. This can be useful when launching multiple huge runs on HPC.

        The current input parameters will be written to special file, which is automatically read from pART,
        and all generated data will be dumped to special file. A separate process can read that datadump.

        '''

        raise ValueError( "serialize_run() function net yet implemented!")
        return

    def artn_next_displ(self, nat, etot, force, typ, pos, box, if_pos ):
        cnat = c_int(nat)
        cetot = c_double(etot)
        cforce = force.ctypes.data_as( POINTER(c_double) )
        ctyp = np.intc(typ)
        ctyp = ctyp.ctypes.data_as( POINTER(c_int) )
        cpos = pos.ctypes.data_as( POINTER(c_double) )
        cbox = box.ctypes.data_as( POINTER(c_double) )
        cif_pos = np.intc(if_pos)
        cif_pos = cif_pos.ctypes.data_as( POINTER(c_int) )
        # cdispl_vec = (c_double*3*nat)()
        cdispl_vec = c_void_p()
        clconv = c_bool()

        self.lib.artn_step.restype = None
        self.lib.artn_step.argtypes = [ c_int, c_double, POINTER(c_double), POINTER(c_int), POINTER(c_double), \
                                        POINTER(c_double), POINTER(c_int), c_void_p, \
                                        POINTER(c_bool) ]

        self.lib.artn_step( cnat, cetot, (cforce), (ctyp), (cpos), \
                            (cbox), (cif_pos), byref(cdispl_vec), pointer(clconv) )


        val = cast( cdispl_vec, POINTER(c_double) )
        dval = np.ctypeslib.as_array( val, shape=[nat,3] )

        return dval, clconv.value
