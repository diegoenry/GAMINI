#!/bin/bash
outdir=analysis
#rm ${outdir}/*

run() {
echo $disp>disp.dat
./combine.NM.and.opt.by.dynamics.bash $1 > ./input/$1.inp
mpirun -n 8 /home/lpscott/dgomes/software64/c36b1/exec/em64t_M/charmm -i ./input/$1.inp > ./output/$1.log
}

ener_min() {
ener=`awk '/ENER>/ {print $3}' ./output/${mode}/${disp}-final.out| tail -1`
echo $disp $ener >> ${outdir}/ener_min.${mode}.dat
}

ener_dyn() {
ener=`awk '/AVER>/ {print $6}' ./output/${mode}/${disp}.log| tail -1`
fluc=`awk '/FLUC>/ {print $6}' ./output/${mode}/${disp}.log| tail -1`
echo $disp $ener $fluc >> ${outdir}/ener_dyn.${mode}.dat
}

mmfp2_min() {
mmfp2=`awk '/CONJ MMFP2>/ {print $3}' ./output/${mode}/${disp}.log | tail -1`
echo $disp $mmfp2 >> ${outdir}/mmfp2_min.${mode}.dat
}

mmfp2_dyn() {
mmfp2=`awk '/AVER MMFP2>/ {print $3}' ./output/${mode}/${disp}.log | tail -1`
mmfp2_fluc=`awk '/FLUC MMFP2>/ {print $3}' ./output/${mode}/${disp}.log |tail -1`
echo $disp $mmfp2 $mmfp2_fluc >> ${outdir}/mmfp2_dyn.${mode}.dat
}

for mode in 7 8 9 10 11 12 ; do
echo "running mode ="${mode}
for disp in -2.0 -1.9 -1.8 -1.7 -1.6 -1.5 -1.4 -1.3 -1.2 -1.1 -1.0 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1  1.2  1.3  1.4  1.5  1.6  1.7  1.8  1.9  2.0 ; do
echo -ne "running disp: " ${disp} "\r"
ener_min
ener_dyn
mmfp2_min
mmfp2_dyn
done
echo 
done

