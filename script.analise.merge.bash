#!/bin/bash

root=$PWD

for dataset in ener_min mmfp2_min; do
output=$root/$dataset.dat
rm $output
   AnaNum=0
for ana in "analysis"  "analysis.2" "analysis.3" ; do
   cd $root/$ana
   ModNum=0
   for ((mode=7;mode<=12;mode++)) do
      echo "@target G"${ModNum}".S${AnaNum}" >> $output
      echo "@type xy"                        >> $output
      cat $dataset.$mode.dat                 >> $output
      echo "&"                               >> $output
      let ModNum=$ModNum+1
   done
let AnaNum=$AnaNum+1
done
done

for dataset in ener_dyn mmfp2_dyn; do
output=$root/$dataset.dat
rm $output
   AnaNum=0
for ana in "analysis" "analysis.2" "analysis.3" ; do
   cd $root/$ana
   ModNum=0
   for ((mode=7;mode<=12;mode++)) do
      echo "@target G"${ModNum}".S${AnaNum}" >> $output
      echo "@type xydy"                      >> $output
      cat $dataset.$mode.dat                 >> $output
      echo "&"                               >> $output
      let ModNum=$ModNum+1
   done
   let AnaNum=$AnaNum+1
done
done
