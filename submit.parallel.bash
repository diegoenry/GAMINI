#!/bin/bash
escreve() {
echo "
#!/bin/bash
#PBS -l nodes=1:ppn=8
# job name (default = name of script file)
#PBS -N disp_${disp}
#PBS -o ./PBS/disp_${disp}.o
#PBS -e ./PBS/disp_${disp}.e

CHARMMEXEC=/home/lpscott/dgomes/software64/c36b1/exec/em64t_M/charmm
cd $PWD/

mpirun -n 8 \$CHARMMEXEC \
-i optimize.NM.displacement.inp \
modnu=${mode} disp=${disp} \
-o ./output/${mode}/${disp}.log
" > tmp.qsub
}

for mode in 7 8 9 10 11 12; do
mkdir output/$mode
done


for mode in  7 8 9 10 11 12; do
  for disp in -2.0 -1.9 -1.8 -1.7 -1.6 -1.5 -1.4 -1.3 -1.2 -1.1 -1.0 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1  1.2  1.3  1.4  1.5  1.6  1.7  1.8  1.9  2.0 ; do
  escreve
  qsub tmp.qsub
  done
done
