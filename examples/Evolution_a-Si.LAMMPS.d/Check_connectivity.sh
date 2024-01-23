#!/bin/bash

########### -Extract minima and saddles to create lists- ###########
i=0
nevents=0
for isad in sad*.xyz; do
  listfile[$i]="$isad";
  i=`echo "$(($i+1))"`;
  nevents=`echo "$(($nevents+1))"`;
  mininit=$(grep "> Configuration Files" artn.out |grep $isad | awk 'BEGIN {FS= "|"}; {print $5}'| sed 's/ //g');
  listfile[$i]="$mininit";
  i=`echo "$(($i+1))"`;
  minfinal=$(grep "> Configuration Files" artn.out |grep $isad | awk 'BEGIN {FS= "|"}; {print $4}'| sed 's/ //g');
  listfile[$i]="$minfinal";
  i=`echo "$(($i+1))"`;
done

############# read energies and distances in artn.out ###############
rm sad min1 min2
grep "DEBRIEF(S" artn.out>sad
grep "DEBRIEF(RLX :1" artn.out>min1
grep "DEBRIEF(RLX :2" artn.out>min2

j=1
nconnect=0
for (( ifile=1; ifile<=$nevents; ifile++));
do
   listES[$j]=$( sed -n "$j p" sad  |awk '{print $6}');
   listLS[$j]=$( sed -n "$j p" sad  |awk '{print $18}');
   listRS[$j]=$( sed -n "$j p" sad  |awk '{print $27}');
   listE1[$j]=$(sed -n "$j p" min1 |awk '{print $7}');
   listL1[$j]=$(sed -n "$j p" min1 |awk '{print $19}');
   listR1[$j]=$(sed -n "$j p" min1 |awk '{print $28}');
   listE2[$j]=$(sed -n "$j p" min2 |awk '{print $7}');
   listL2[$j]=$(sed -n "$j p" min2 |awk '{print $19}');
   listR2[$j]=$(sed -n "$j p" min2 |awk '{print $28}');

   ############ Check connectivity #################
   epsE=0.001
   epsR=0.7
   listConnect[$j]=0
   if (( $(echo "($epsE > ${listE1[$j]})*($epsR > ${listR1[$j]})+($epsE > ${listE2[$j]})*($epsR > ${listR2[$j]})" |bc -l) ))
   then
      listConnect[$j]=1
      nconnect=`echo "$(($nconnect+1))"`;
   fi

   echo "Event $j Barrier= ${listES[$j]} R= ${listRS[$j]} E1= ${listE1[$j]} R1= ${listR1[$j]} E2= ${listE2[$j]} R2= ${listR2[$j]} Connect= ${listConnect[$j]}" ;
   j=`echo "$(($j+1))"`;
done

echo "$nconnect of the $nevents events are connected"
