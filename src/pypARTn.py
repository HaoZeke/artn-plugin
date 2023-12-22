from ctypes import *
from os.path import dirname,abspath,join
from inspect import getsourcefile
import numpy as np


class artn():
    _ARTN_DTYPE_UNKNOWN = -1
    _ARTN_DTYPE_INT     = 0
    _ARTN_DTYPE_REAL    = 1
    _ARTN_DTYPE_BOOL    = 2
    _ARTN_DTYPE_STR     = 3

    def __init__(self, engine=None, shlib=None):
        '''
        create a new instance.

        example:
        ========

           >>> import pypARTn
           >>> artn = pypARTn.artn()

        '''
        ## class constructor
        if engine == None:
            msg = "Please specify the engine through keyword 'engine'"
            raise ValueError( msg )
        # path to this file
        mypath=dirname(abspath(getsourcefile(lambda:0)))
        # one dir up
        mypath = dirname(mypath)

        # name of the lib according to engine
        if engine == "lammps" or engine == "lmp":
            libname = "lib/libartn-lmp.so"
        else:
            msg = "Unknown value for 'engine': "+ engine
            raise ValueError( msg )

        path = join(mypath, libname )
        # user provide path
        if shlib:
            path = shlib
        self.lib = CDLL(path)


        self.lib.artn_create.restype = c_void_p
        self.handle = c_void_p( self.lib.artn_create() )



    def destroy(self):
        self.lib.artn_destroy.restype=None
        self.lib.artn_destroy.argtypes=[c_void_p]
        self.lib.artn_destroy( self.handle )

    def __del__(self):
        ## class destructor
        self.destroy()
        del self.handle

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
        if dtyp == self._ARTN_DTYPE_INT:
            return "int"
        elif dtyp == self._ARTN_DTYPE_REAL:
            return "float"
        elif dtyp == self._ARTN_DTYPE_STR:
            return "str"
        elif dtyp == self._ARTN_DTYPE_BOOL:
            return "bool"
        else:
            return "unknown"



    def set(self, name, oval ):
        """
        Set a value to an artn variable.

        input:
        ======
        :param name: string of name of the artn variable.
        :type name: string

        :param oval: value of the variable to be set
        :type oval: same type as the corresponding ARTn variable

        output:
        =======
        None

        Example:
        ========

           >>> artn.set( "verbose", 0 )

        Where applicable, the input variables should be in same units as in the input file, which
        is units defined by the `engine_units` variable.
        """
        self.lib.artn_set.restype=None
        self.lib.artn_set.argtypes=[ c_void_p, c_char_p, c_int, c_int, POINTER(POINTER(c_int)), \
                                     c_void_p, POINTER(c_int) ]

        # keep local copy of original
        val = oval

        # encode name to C
        cname = name.encode()


        # get rank and type of py input
        pyrank, pytyp = self._my_rank_type( val )

        # get expected dtyp
        self.lib.artn_get_datatype.restype = c_int
        self.lib.artn_get_datatype.argtypes = [ c_void_p, c_char_p, POINTER(c_int) ]
        cerr = c_int()
        ctyp = self.lib.artn_get_datatype( self.handle, cname, pointer(cerr) )
        if cerr.value < 0:
            msg = "unknown datatype for input name: "+name
            raise ValueError( msg )

        # check dtyp consistency
        if pytyp != ctyp:
            msg = "Wrong datatype in input! Expected:"+self._dtypstr(ctyp)+" Got:"+self._dtypstr( pytyp )+ \
                "\n >> Input value:\n"+str(oval)
            raise ValueError( msg )

        # get expected drank
        self.lib.artn_get_datarank.restype = c_int
        self.lib.artn_get_datarank.argtypes = [ c_void_p, c_char_p, POINTER(c_int) ]
        cerr = c_int()
        crank = self.lib.artn_get_datarank( self.handle, cname, pointer(cerr) )

        # check drank consistency
        if pyrank != crank:
            msg = "wrong rank in input! Expected:"+str(crank)+" Got:"+str(pyrank)+\
                "\n >> Input value:\n"+str(oval)
            raise ValueError( msg )

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

        # cval = val.ctypes.data_as( c_void_p )
        # cval = cast( val.ctypes.data_as(c_void_p), c_void_p )
        # print( cast(cval, c_char_p).value.decode() )

        # call artn_set
        # self.lib.artn_set( self.handle, cname, ctyp, crank, pointer(csize), pointer(cval), pointer(cerr) )
        self.lib.artn_set( self.handle, cname, ctyp, crank, byref(csize), byref(cval), byref(cerr) )
        if cerr.value != 0:
            msg = "error in artn_set"
            print("cerr = ",cerr.value)
            raise ValueError( msg )

        del s, val, crank, cname, ctyp
        del cval, csize, cerr
        return



    def extract( self, name ):
        '''
        Extract a value from artn instance.

        input:
        ======
        :param name: Name of the artn variable you wish to extract.
        :type name: string

        output:
        =======
        :param dval: value of desired artn variable
        :type dval: same type as corresponding artn variable (np.int32, np.float64, or np.array with same type)

        example:
        ========

           >>> evs = artn.extract( "eigval_sad" )
           >>> pos_min1 = artn.extract( "coords_min1" )

        '''
        self.lib.artn_extract.restype = c_int
        self.lib.artn_extract.argtypes = [c_void_p, c_char_p, POINTER(c_int), POINTER(c_int), \
                                          POINTER(POINTER(c_int)), POINTER(c_void_p) ]

        cname = name.encode()
        ctyp = c_int()
        crank = c_int()
        csize = POINTER(c_int)()
        cdat = c_void_p()

        cerr = self.lib.artn_extract( self.handle, cname, pointer(ctyp), pointer(crank), \
                                      pointer(csize), pointer(cdat) )

        # if cdat == None:
        #     msg = "data not present in artn_data!"
        #     raise ValueError( msg )

        if cerr != 0:
            msg = "Error in artn_extract"
            raise ValueError( msg )

        # tf values into py
        drank = crank.value
        # create size array from ctypes pointer
        dsize = np.ctypeslib.as_array( csize, shape=[drank] )
        # reverse the size array, otherwise we get transpose
        dsize = dsize[::-1]

        # cast data to proper type
        if ctyp.value == self._ARTN_DTYPE_INT:
            val = cast( cdat, POINTER(c_int) )
        elif ctyp.value == self._ARTN_DTYPE_REAL:
            val = cast( cdat, POINTER(c_double) )
        elif ctyp.value == self._ARTN_DTYPE_BOOL:
            val = cast( cdat, POINTER(c_bool) )
        elif ctyp.value == self._ARTN_DTYPE_STR:
            val = cast( cdat, c_char_p )
            return val.value.decode()
        else:
            msg = "data type not implemented in python interf to artn!"
            raise ValueError( msg )

        if drank == 0:
            return val.contents.value
        else:
            dval = np.ctypeslib.as_array( val, shape=dsize )
            return dval

    def dump_input(self, filename = None ):
        '''
        Dump the currently defined variables of artn_data into a file that can
        be used as artn input file.

        input:
        ======
        :optional filename: name of the output file
        :type filename: string


        '''
        self.lib.artn_dump_input.restype = c_int
        if filename:
            print( "filename is there", filename)
            self.lib.artn_dump_input.argtypes = [ c_void_p, c_void_p ]
            cfname = filename.encode()
            cfname = create_string_buffer( cfname )
            cfname = cast( cfname, c_void_p )
            cerr = self.lib.artn_dump_input( self.handle, byref(cfname) )
        else:
            print("filename is not there")
            self.lib.artn_dump_input.argtypes = [ c_void_p, c_void_p ]
            cerr = self.lib.artn_dump_input( self.handle, None )
        return

    def list_set( self ):
        '''
        print all variables which can be set into pARTn from python
        '''
        self.lib.artn_list_set.restype=None
        self.lib.artn_list_set.argtypes=[]
        self.lib.artn_list_set()

    def list_extract( self ):
        '''
        print all variables which can be extracted from pARTn into python
        '''
        self.lib.artn_list_extract.restype = None
        self.lib.artn_list_extract.argtypes = []
        self.lib.artn_list_extract()

    def tt(self):
        self.lib.tt.restype=None
        self.lib.tt.argtypes=[ c_void_p ]
        self.lib.tt( self.handle )
