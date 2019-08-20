#!/bin/sh

QE_PATH='mpirun -np 12'

echo " all program is started "

for e in 0.004 0.0276 0.037 0.125 ; do

##for e in $(seq 0.0 0.1 1.0) ; do
cat > scf-C.$e.in << EOF

&control
    calculation = 'scf',
    restart_mode='from_scratch',
    prefix='di',
    pseudo_dir='/home/nambiyrk/vca/doped-pseudo',
    outdir='tmp/'
    verbosity='high',
  wf_collect=.false. ,
/
&SYSTEM
  ibrav=4,
  celldm(1)=4.75915, celldm(3)=1.63492,
  nat=4,
  ntyp=2,
    ecutwfc         = 60
    occupations     = 'smearing'
    smearing        = 'mp'
    degauss         = 0.02
    nbnd            = 25
 /
 &electrons
    diagonalization = 'david'
    mixing_beta     = 0.7
    conv_thr        = 1.0d-10
 /


ATOMIC_SPECIES
  C 12.010700d0 C.pbe-n-rrkjus_psl.0.1.UPF
 C1 12.010700d0 CN-pseudo_$e.UPF
ATOMIC_POSITIONS {crystal}
   C   0.3333333333d0   0.6666666667d0   0.0626069786d0
   C   0.3333333333d0   0.6666666667d0   0.4373930214d0
   C   0.6666666667d0   0.3333333333d0   0.9373930214d0
   C1  0.6666666667d0   0.3333333333d0   0.5626069786d0

K_POINTS {automatic}
  8 8 4 1 1 1

EOF
cat > thermo_control << EOF
 &INPUT_THERMO
  what='mur_lc', 
  lmurn=.FALSE.,
/
EOF
echo " murghan is started "
$QE_PATH thermo_pw.x < scf-C.$e.in > scf-C.$e.out
du -ch tmp/ >tmpsize
rm -rf tmp/* 
ps2pdf output_mur.ps output_mur.pdf

echo " murghan is completed "
mkdir murfit_$e 
mv gnuplot_files/ energy_files/ restart/ tmpsize thermo_control scf-C.$e.* output_* murfit_$e/

a="$(grep -A 1 obtained murfit_$e/scf-C.$e.out |tail -n1|awk '{printf $1}')"
c="$(grep -A 1 obtained murfit_$e/scf-C.$e.out |tail -n1|awk '{printf $3}')"

##t="$(grep 'equilibrium' murfit_$e/scf-C.$e.out |awk '{print $6}')"

################################MURGHAN_FIT-FINISHED#################################################

echo " relax-after murghan is started "
cat > relax-C.$e.in << EOF

&control
    calculation = 'relax',
    restart_mode='from_scratch',
    prefix='di',
    pseudo_dir='/home/nambiyrk/vca/doped-pseudo',
    outdir='tmp/'
    verbosity='high',
  wf_collect=.false. ,
/
&SYSTEM
  ibrav=4,
  celldm(1)=$a, celldm(3)=$c,
  nat=4,
  ntyp=2,
    ecutwfc         = 60
    occupations     = 'smearing'
    smearing        = 'mp'
    degauss         = 0.02
    nbnd            = 25
 /
 &electrons
    diagonalization = 'david'
    mixing_beta     = 0.7
    conv_thr        = 1.0d-10
 /
&ions

/
ATOMIC_SPECIES
  C 12.010700d0 C.pbe-n-rrkjus_psl.0.1.UPF
 C1 12.010700d0 CN-pseudo_$e.UPF
ATOMIC_POSITIONS {crystal}
   C   0.3333333333d0   0.6666666667d0   0.0626069786d0
   C   0.3333333333d0   0.6666666667d0   0.4373930214d0
   C   0.6666666667d0   0.3333333333d0   0.9373930214d0
   C1  0.6666666667d0   0.3333333333d0   0.5626069786d0

K_POINTS {automatic}
  8 8 4 1 1 1


EOF
$QE_PATH pw.x < relax-C.$e.in > relax-C.$e.out

echo " relax-after murghan is completed "

sed -n -e '/Begin final coordinates/,/End final coordinates/{ /Begin final coordinates/d; /End final coordinates/d; p;}' relax-C.$e.out >relax-C.$e.txt

################################RELAX-AFTER-MURFIT#################################################

echo " band is started "
cat > scf-C.$e.in << EOF
&control
    calculation = 'scf',
    restart_mode='from_scratch',
    prefix='di',
    pseudo_dir='/home/nambiyrk/vca/doped-pseudo',
    outdir='tmp/'
    verbosity='high',
  wf_collect=.false. ,
/
&SYSTEM
  ibrav=4,
  celldm(1)=4.75915, celldm(3)=1.63492,
  nat=4,
  ntyp=2,
    ecutwfc         = 60
    occupations     = 'smearing'
    smearing        = 'mp'
    degauss         = 0.02
    nbnd            = 25
 /
 &electrons
    diagonalization = 'david'
    mixing_beta     = 0.7
    conv_thr        = 1.0d-10
 /


ATOMIC_SPECIES
  C 12.010700d0 C.pbe-n-rrkjus_psl.0.1.UPF
 C1 12.010700d0 CN-pseudo_$e.UPF

`while read line; do echo $line; done < relax-C.$e.txt`

K_POINTS {automatic}
  8 8 4 1 1 1

EOF
cat > thermo_control << EOF
 &INPUT_THERMO
  what='scf_bands',
 /
EOF

$QE_PATH thermo_pw.x < scf-C.$e.in > scf-C.$e.out

du -ch tmp/ >tmpsize
rm -rf tmp/* 

ps2pdf output_band.ps output_band.pdf
echo " band is completed "
mkdir band_$e 
mv gnuplot_files/ band_files/ restart/ thermo_control scf-C.$e.out tmpsize output_band.* band_$e/
cp scf-C.$e.in  band_$e/

################################BAND-FINISHED#################################################

cat > thermo_control << EOF
 &INPUT_THERMO
  what='scf_dos',
 /
EOF

cat > eps_control << EOF
&input_epsilon
  prefix='pervos_i'
  outdir='tmp/g1/'
  calculation='eps'
  wmin=0.05
  wmax=1.6
  nfs=1000
 /
EOF

cat > pdos.in << EOF
&PROJWFC
    outdir='tmp/g1/'
    prefix='di',
    filpdos='i.pdos'
    Emin=-5.0, Emax=35.0, DeltaE=0.01
 /
EOF

cat > pp.in << EOF
 &inputpp
    prefix  = 'di'
    outdir = 'tmp/g1/'
    filplot = 'icharge'
    plot_num= 0
 /
 &plot
    nfile = 1
    filepp(1) = 'icharge'
    weight(1) = 1.0
    iflag = 3
    output_format = 5
    fileout = 'i.rho.xsf'
    e1(1) =1.0, e1(2)=0.0, e1(3) = 0.0,
    e2(1) =0.0, e2(2)=1.0, e2(3) = 0.0,
    nx=56, ny=40
 /
EOF
echo " dos is started "
$QE_PATH thermo_pw.x < scf-C.$e.in > scf-C.$e.out
echo " dos is completed "
echo " dielectric is started "
##$QE_PATH epsilon_tpw.x <eps_control> eps.out
echo " dielectric is completed "
echo " pdos is started "
$QE_PATH projwfc.x < pdos.in > pdos.out
echo " pdos is completed "
echo " charge-density is started "
$QE_PATH pp.x <pp.in > pp.out
echo " charge-density is completed"
echo "scf-C.$e. is completed"
du -ch tmp/ >tmpsize
rm -rf tmp/* 

#ps2pdf output_epsilon.ps output_epsilon.pdf 
ps2pdf output_eldos.ps output_eldos.pdf

mkdir pdos
mv i.pdos.pdos_* pdos/
mkdir dos-optical_$e

mv *.ps *.pdf *.out i* gnuplot_tmp_epsilon epsilon* tmpsize pdos/ gnuplot_files/ therm_files/ restart/ dos-optical_$e/

cp pdos.in pp.in thermo_control eps_control dos-optical_$e/

echo "scf-C for celldm=$e is done"
done

################################DOS-OPTICAL-FINISHED#################################################
