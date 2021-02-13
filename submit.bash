#!/bin/bash
escreve() {
echo "
#!/bin/bash
#PBS -l nodes=1:ppn=1
# job name (default = name of script file)
#PBS -N disp_$1
#PBS -o disp_$1.o
#PBS -e disp_$1.e

cd $PWD/
$CHARMMEXEC -i ./input/$1.inp > ./output/$1.log
}

" > tmp.qsub
}

num=-20
for disp in -2.0 -1.9 -1.8 -1.7 -1.6 -1.5 -1.4 -1.3 -1.2 -1.1 -1.0 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1  1.2  1.3  1.4  1.5  1.6  1.7  1.8  1.9  2.0 ; do
echo $disp>disp.dat
./combine.NM.and.opt.by.dynamics.bash ${num} > ./input/${num}.inp
escreve $num
let num=$num+1
qsub tmp.qsub
done
