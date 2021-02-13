#!/bin/bash
###########################################################
# Programa CAPES/COFECUB 2009-2011
# 
# Diego E. Barreto Gomes 1,2  | diego@biof.ufrj.br
# Luis P. B. Scott       3    |
# Pedro G. Pascutti      1    | pascutti@biof.ufrj.br
# Paulo M. Bisch         1    | pmbisch@biof.ufrj.br
# David Perahia          2    | david.perahia@ens-cachan.fr
# 
###########################################################

# This is a script to generate a CHARMM input file combining multiple
# normal modes and their associated amplitudes and generate one file
# containing a minimized structure along the vectors of the combined
# normal modes
#
# Optimization of the final structure is done by Molecular Dynamics Simulation
# at 30 Kelvin, then a final steepest descent minimization.
#
#Ter Dec  6 19:03:12 BRT 2011

# ! set number of modes that will be combined
# This will be replaced by a read of a file containing the max displacements for each mode.
### need to read the disp.dat file.

echo "* energy minimization for a given combination of modes 
* For a given number of modes do a displacement along a combination of them.
* The amplitude along each of the modes is chosen randomly
*

bomlev -2

! faster routines are used
faster on

!==========
!directory name where the coordinates and trajectory will be written
set dirnam output
set temperature 30.0
set kmod 20000
set istr $1
!normal mode file name
set modnam modes.mod

open read file unit 40 name @modnam

! initial structure
set minic step1_pdbreader.pdb

!Read topology and parameter files ! protein topology and parameter
open read card unit 10 name toppar/top_all22_prot.rtf
read  rtf card unit 10

open read card unit 20 name toppar/par_all22_prot.prm
read para card unit 20 flex

!read the psf
open unit 4 read card name step1_pdbreader.psf
read psf card unit 4
close unit 4

! read the initial coordinates (energy minimized or X-ray one)
! for which the modes were computed
open read card unit 12 name @minic
read coor pdb resi unit 12
close unit 12
coor copy comp

! Define energy model
! Parameters from Paulo Ricardo Batista 
! define force field 2
set par1 8.0
set par2 10.0
set par3 12.0
set par4 2.0
updat  inbfrq -1 -
atom rdiel switch vswitch -
ctonnb @par1 ctofnb @par2 cutnb @par3 eps @par4 e14fac 1.0 wmin 1.5
"

#read the displacements provided by GAmini program (or manually).
nummod=0
while read line
do
let nummod=$nummod+1
q[$nummod]=$line
done<disp.dat

echo "
! set number of modes that will be combined
set nummod $nummod
!Range of displacement values for each mode

open read card unit 12 name @minic
read coor pdb resi unit 12
close unit 12
coor copy comp

!open a trajectory file for the normal mode coordinates
open write card unit 17 - 
   name @dirnam/@istr.qcr
"

for ((i=1; i<=nummod ;i++)) do
echo "set q${i}  ${q[$i]}"
done

echo "
!------------
!minimization
!------------
! Set up MMFP (umbrella) potential
! mxmd = maximum number of modes (read only once)
! kmdn = force constant for all the modes
! qn  =constrained coordinate value for mode imdn
! umdn = unit number for the modes
! imdn = mode number
! uout = unit for storing the normal coordinates
! krot = force constant for the overall rotation
! kcgr=force constant for the overall translation
! nsvq = normal coordinates saving frequency

mmfp
vmod init mxmd @nummod krot 0.000001 kcgr 1000 umdn 40 uout 17 nsvq 100 
"
for ((i=1; i<=nummod ;i++)) do
let j=$i+6 #from mode 7
echo "vmod add  qn @q${i} imdn ${j} kmdn 1000"
done

echo "
end

!##### md1 just relax a little #####
open write file unit 14 name @dirnam/@istr.md1.dcd
open write card unit 17 name @dirnam/@istr.md1.qcr
open write card unit 19 name @dirnam/@istr.md1.rst

dyna start nstep 5000  timestep 0.001  ntrfrq 10  -
    iseed $RANDOM -
    iprfrq 1000  ihtfrq 0 ieqfrq 500 imgfrq -1 inbfrq -1 -
    iunwri 19 iunrea -16  iuncrd 14 -
    nprint 100 nsavc 1000 echeck 100000 -
    ihbfrq 0 isvfrq 1000 -
    iasors 0 iasvel 1 iscvel 0 ichecw 0 -
    firstt 30.0 finalt @temperature teminc 0.0 tstruc @temperature -
    TConstant TCouple 0.1 TReference @temperature

set i 1000

close unit 14
close unit 17
close unit 19

!##### md2 increasing KMOD #####

label kmdn_loop

open read  card unit 16 name @dirnam/@istr.md1.rst
open write file unit 14 name @dirnam/@istr.md2.dcd
open write card unit 17 name @dirnam/@istr.md2.qcr
open write card unit 19 name @dirnam/@istr.md2.rst

mmfp
"

for ((i=1; i<=nummod ;i++)) do
let j=$i+6 #from mode 7
echo "vmod change nrestraint  ${i}  qn @q${i}  kmdn @i"
done

echo "

end

dyna cpt restart nstep  5000  timestep 0.001  ntrfrq 10  -
    iprfrq 1000  ihtfrq 0 ieqfrq 500 imgfrq -1 inbfrq -1 -
    iunwri 19 iunrea 16  iuncrd 14 -
    nprint 100 nsavc 1000 echeck 100000 -
    ihbfrq 0 isvfrq 1000 -
    iasors 0 iasvel 0 iscvel 0 ichecw 0 -
    firstt @temperature finalt @temperature teminc 0.0 tstruc @temperature -
    TConstant TCouple 0.1 TReference @temperature

increment i by 1000

!we need to restart from a restart file :(
system \"cp output/$1.md2.rst output/$1.md1.rst\"

if i .lt. 10000 goto kmdn_loop

close unit 14
close unit 16
close unit 17
close unit 19

!##### md3 production #####
!# Here we increase (put 20000) the KMOD back to the original value and run the simulation
set i @kmod
mmfp
"
for ((i=1; i<=nummod ;i++)) do
let j=$i+6 #from mode 7
echo "vmod change nrestraint  ${i}  qn @q${i}  kmdn @i"
done

echo "
end

open read  card unit 16 name @dirnam/@istr.md2.rst
open write file unit 14 name @dirnam/@istr.md3.dcd
open write card unit 17 name @dirnam/@istr.md3.qcr
open write card unit 19 name @dirnam/@istr.md3.rst

!sample
dyna cpt restart nstep 10000  timestep 0.001  ntrfrq 10  -
    iprfrq 1000  ihtfrq 0 ieqfrq 500 imgfrq -1 inbfrq -1 -
    iunwri 19 iunrea 16  iuncrd 14 -
    nprint 100 nsavc 1000 echeck 100000 -
    ihbfrq 0 isvfrq 1000 -
    iasors 0 iasvel 0 iscvel 0 ichecw 0 -
    firstt @temperature finalt @temperature teminc 0.0 tstruc @temperature -
    TConstant TCouple 0.1 TReference @temperature

close unit 14
close unit 16
close unit 17
close unit 19

!wrap up with a final minimization
mini conj nstep 500 tolgrd 0.01


open write card unit 19 name -
   @dirnam/@istr-final.out

outu 19

! compute the energy of the final structure
ener

! compute the rmsd from the initial structure
coor rms

write title unit 19
* system name
* NORMAL_MODES=
* TARGET_NORMAL_COORDINATES= ${dmrms[@]:1:5}
* TOTAL_E= ?ENER RMSD= ?RMS
*

mmfp
vmod print
end

outu 6

! write the final minimized coordinates
open write card unit 12 name - 
   @dirnam/@istr.pdb
write coor pdb unit 12
* system name
* minimized coordinates
* TOTAL_E= ?ENER RMSD= ?RMS
*

time diff 
! close the normal mode file
close unit 40

close unit 12
close unit 17
close unit 19

outu 6
stop
"
