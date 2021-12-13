#!/bin/bash
export ASTER_HOME="/home/rme/salome_meca/V2018.0.1_public"
export WFAS6_HOME="/home/rme"
source $ASTER_HOME/salome_prerequisites.sh
source $ASTER_HOME/salome_modules.sh

for var in "$@"
do
    echo "$var" >> exec.log
    $ASTER_HOME/tools/Code_aster_frontend-201801/bin/as_run "$var" > /dev/null 2>&1 >> exec.log
done

echo "Finished Execution" >> exec.log
cp -rlf exec.log weldparam.mess
rm exec.log

