#!/bin/bash

PROGNAME="$( basename $0 )"
LOGFILE="`pwd`/calc_crack_init.log"
touch $LOGFILE
# 環境変数整備
export MODULEDIR=~/misrc_fatigue_high_prediction/script/high_precision/2.2.3/
export FMSPROG=${MODULEDIR}/fmsprog/
export DAMASK_SETUPFILE=${MODULEDIR}/damask_setupfile/
export PYTHONDIR=${MODULEDIR}/python
export DAMASK_NUM_THREADS=8

python2 ${PYTHONDIR}/grain_data.py grain.dat
ln -s ${DAMASK_SETUPFILE}* ./
${FMSPROG}/04_damask_u-tokyo/damask_pre1
${FMSPROG}/04_damask_u-tokyo/damask_pre2
targetdirs=`cat ${FMSPROG}/04_damask_u-tokyo/damask_exec_dir`
for dir in ${targetdirs[@]}
do
    ${FMSPROG}/04_damask_u-tokyo/damask_job_xargs $dir
done
${FMSPROG}/04_damask_u-tokyo/damask_post
zip -r output.zip m*/*.odb m*/*.inp m*/*.png *.png


