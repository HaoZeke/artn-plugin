#!/bin/bash
nsteps=5;          # number of KMC steps
temp=800;          # temperature for chosing events
nparf=2;           # number of cores used to parallelise forces
nparev=2;          # number of groups of nparf cores used to parallelize events searches
choicealgo="minE"; # algorithm that chose the atomistic event: "minE" or "Monte-Carlo"
#declare -a listfiles
#declare -a listE

for istep in `seq 1 $nsteps`; do                                
    echo KMC step number $istep
 
########### --------Search for atomistic events--------- ###########
    for igroup in `seq 1 $nparev`; do            
       echo  Running events searches with group $igroup containing $nparf cores
       mkdir events_group_$igroup
       cp lammps.in conf.sw Si.sw artn.in events_group_$igroup 
       cd events_group_$igroup
       sed -i '20d' artn.in
       sed -i '20i\  push_ids= '$((1 + $RANDOM % 1000))' ' artn.in    # Modify ARTn parameters if needed, here the central atom for the event
       mpirun -np $nparf ../../../../mylammps/src/lmp_mpi -in lammps.in >>artn.log &  # The & permits to place all the processes in background
       cd ../
    done
    wait  # wait that the mpi processes of each group are well finished
    echo "End of events searches"
 
########### -Extract minima and saddles to create lists- ###########
    i=0
    for igroup in `seq 1 $nparev`; do     # listfile=[g1/sad1.xyz g1/min1.xyz g1/min2.xyz g1/sad2.xyz g1/min3.xyz g1/min4.xyz  ... g2/sad1.xyz g1/min1.xyz g1/min2.xyz ...]   
       cd events_group_$igroup 
       for isad in sad*.xyz; do
         listfile[$i]="events_group_$igroup/$isad";
         i=`echo "$(($i+1))"`;
         mininit=$(grep "> Configuration Files" artn.out |grep $isad | awk 'BEGIN {FS= "|"}; {print $5}'| sed 's/ //g');
         listfile[$i]="events_group_$igroup/$mininit";
         i=`echo "$(($i+1))"`;
         minfinal=$(grep "> Configuration Files" artn.out |grep $isad | awk 'BEGIN {FS= "|"}; {print $4}'| sed 's/ //g');
         listfile[$i]="events_group_$igroup/$minfinal";
         i=`echo "$(($i+1))"`;
       done
       cd ../
    done
    
    j=0
    for ifile in "${listfile[@]}"; do
       listE[$j]=$(grep energy $ifile |awk 'BEGIN {FS= "="};  {print $4}'); # Exctract the energy from each xyz file
       j=`echo "$(($j+1))"`;
    done
 
    for iinit in `seq 1 3 ${#listfile[@]}`; do # Calculate barriers and summary
       isad=`echo  "$(($iinit-1))"`;
       ifinal=`echo "$(($iinit+1))"`;
       ibar=`echo   "$((($iinit-1)/3))"`;
       listbarriers[$ibar]=`echo  "${listE[$isad]}- ${listE[$iinit]}" |bc -l`;
      echo Event $ibar Barrier= ${listbarriers[$ibar]} Einit= ${listE[$iinit]} Efinal= ${listE[$ifinal]};
    done
 
########### -Choose the event using your favorite algo-- ###########
    Emin=${listE[0]};
    inewmin=0;
    case $choicealgo in
    minE)        ##########  This algo choses the event that decreases the most the energy
         for i in "${!listE[@]}"; do
            if (( $(echo "$Emin > ${listE[$i]}" |bc -l) ))
            then
               Emin=${listE[$i]}
               inewmin=$i
            fi
         done   
         isad=`echo "$(($inewmin-2))"`;
    ;;     
    Monte-Carlo)  ##########  This algo is Monte-Carlo: it randomly choses the event as a function of its temperature dependant Boltzmann probability 
         Probatot=0              
         for isad in "${!listbarriers[@]}"; do
             Probatot=$(echo "scale=150; $Probatot + e(-${listbarriers["$isad"]}*1.6028/(1.380649*10^(-4)*$temp) )"|bc -l)
         done
         R=`echo ${RANDOM}/32767 |bc -l` #this is a random between 0 and 1
         Probai=0
         for isad in "${!listbarriers[@]}"; do
             Probai=$(echo "scale=150;$Probai + e(-${listbarriers["$isad"]}*1.6028/(1.380649*10^(-4)*$temp) )/$Probatot"|bc -l)
             if (( $(echo "$Probai > $R" |bc -l) ))
             then
                inewmin=`echo "$(($isad*3+2))"`;
                isad=`echo "$(($isad*3))"`;
                echo MC chosen event= $isad Barrier= ${listbarriers[$isad]}; 
                break 
             fi    
         done
    ;;     
    esac   
 
########### ----Replace old min coords with new one----- ###########
    echo Newmin= ${listfile["$inewmin"]} E= $Emin; 
    sed -i '11, $d' conf.sw;
    awk 'NR>2' ${listfile["$inewmin"]}  |awk -v ln=1 '{print ln++ " " $1 " " $2 " " $3 " " $4}' >>conf.sw;
    cat ${listfile[$isad]}    >>KMC.xyz #save chosen saddle
    cat ${listfile[$inewmin]} >>KMC.xyz #save chosen min
   
########### ------Move and save all previous files------ ###########
    mkdir step_$istep
    mv events_group_* step_$istep
   
done
