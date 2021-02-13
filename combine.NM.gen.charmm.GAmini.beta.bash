#!/bin/bash
###########################################################
# Programa CAPES/COFECUB 2009 
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
#Ter Out  4 16:23:12 BRT 2011

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
set istr $1
!normal mode file name
set modnam modes.mod

open read file unit 40 name @modnam

! initial structure
set minic step1_pdbreader.pdb

 !Read topology and parameter files
!Read topology and parameter files
! protein topology and parameter
open read card unit 10 name toppar/top_all22_prot.rtf
read  rtf card unit 10

open read card unit 20 name toppar/par_all22_prot.prm
read para card unit 20 flex

! nucleic acids
!open read card unit 10 name toppar/top_all27_na.rtf
!read  rtf card unit 10 append

!open read card unit 20 name toppar/par_all27_na.prm
!read para card unit 20 append flex

!read the psf
open unit 4 read card name step1_pdbreader.psf
read psf card unit 4
close unit 4

! read the initial coordinates (energy minimized or X-ray one)
! for which the modes were computed
!
open read card unit 12 name @minic
read coor pdb resi unit 12
close unit 12

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
"
echo "
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
"


echo "
! minimize fast up to the target
! Define fast energy model
updat inbfrq -1 eps 2.0 rdie vswit shift ctonnb 10.0 ctofnb 12.0 cutnb 14.0 -
wrnmxd 1.0

! sd =  steepest descent algorithm
! conj =  gradient conjugate algorithm

mini sd nstep 200 tolgrd 0.1

! Define final energy model
updat inbfrq -1 eps 2.0 rdie vswit shift ctonnb 10.0 ctofnb 12.0 cutnb 14.0 -
wrnmxd 1.0

mini conj nstep 200 tolgrd 0.01

! increase the force constant to push  exactly to final position

mmfp
"
for ((i=1; i<=nummod ;i++)) do
echo "vmod change nrestraint  ${i}  qn @q${i}  kmdn 20000"
done

echo "
end
"

echo "
mini conj nstep 200 tolgrd 0.01

! I am minimized
time diff

open write card unit 19 name -
   @dirnam/@istr-final.out

outu 19

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
* NORMAL_MODES= ${mod[@]}
* TARGET_NORMAL_COORDINATES= ${dmrms[@]:1:5}
* TARGET_NORMAL_COORDINATES= ${dmrms[@]:6:5}
* TARGET_NORMAL_COORDINATES= ${dmrms[@]:11:5}
* TARGET_NORMAL_COORDINATES= ${dmrms[@]:16:5}
* TOTAL_E= ?ENER RMSD= ?RMS
*
time diff 
! close the normal mode file
close unit 40
close unit 17
close unit 19

outu 6
stop
"
