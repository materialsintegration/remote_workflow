#!/bin/bash
#cd /tmp/node_calc
python ~/remote_workflow/scripts/abaqus_scripts/create_sscurve.py yeild_strength.dat tesile_strength.dat reduction_area.dat
python ~/remote_workflow/scripts/abaqus_scripts/create_inputdata.py ~/remote_workflow/scripts/input_data/Modeldata.inp Cyclic_SSCurve_csv
mv XX_inp XX.inp
/usr/local/bin/abaqus Job=XX interactive cpus=4 interactive mp_mode=threads
