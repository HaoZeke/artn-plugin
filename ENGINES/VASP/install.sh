VASP_PATH=/home/ajay/Programmes/vasp.5.4.4.pl2
ARTN_PATH=/home/ajay/Programmes/artn-plugin/

# Copy ARTn_VASP.F into VASP/src/ directory
cp ARTn_VASP.F $VASP_PATH/src/

# Add the ARTn_VASP.o into the VASP/src/.objects file at 2 places if not already there
if grep -q "ARTn_VASP.o" $VASP_PATH/src/.objects
then
  echo "ARTn_VASP.o already in objects."  
else
  echo "ARTn_Vasp.o not set, adding..."  
  n1="`grep -n  -m 1 dmatrix.o $VASP_PATH/src/.objects | cut -d : -f 1`"
  n2="`grep -n  -m 2 dmatrix.o $VASP_PATH/src/.objects | cut -d : -f 1 |tail -1`"
  sed -i "${n1}i\\\tARTn_VASP.o \\\\" $VASP_PATH/src/.objects 
  sed -i "${n2}i\\\tARTn_VASP.o \\\\" $VASP_PATH/src/.objects 
fi

# Add the needed library lines into the makefile.include
if grep -q "libartn.a" $VASP_PATH/makefile.include
then
  echo "LIBS and INCS already set."  
else
  echo "LIBS not set, adding..."  
  sed -i -e "\$a\\\\nLLIBS +=${ARTN_PATH}/lib/libartn.a" $VASP_PATH/makefile.include 
  sed -i -e "\$a\\\\nINCS  +=-I${ARTN_PATH}/src/Obj/"      $VASP_PATH/makefile.include 
fi

# Add the CALL ARTn into the main of VASP
if grep -q "ARTN_VASP" $VASP_PATH/src/main.F
then
  echo "CALL ARTN_VASP already into the main.F"  
else
  echo "CALL ARTN_VASP not in the main.F, adding..."  
  sed -i '/PARALLEL_TEMPERING*/i \ \ \ \ \ \ CALL ARTN_VASP( TIFOR, TOTEN, T_INFO, INFO, DYN, LATT_CUR, NSTEP, IO)' $VASP_PATH/src/main.F 
fi
