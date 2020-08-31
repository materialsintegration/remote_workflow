#!/bin/bash
#cd /tmp/node_calc; python ~/abaqus_scripts/create_inputdata.py Modeldata.inp ~/abaqus_scripts/Cyclic_SSCurve_csv; mv XX_inp XX.inp > /tmp/node_calc/node_calc_exec.log 2>&1
#cd /tmp/node_calc
python ~/abaqus_scripts/create_sscurve.py yeild_strength.dat tesile_strength.dat reduction_area.dat
python ~/abaqus_scripts/create_inputdata.py ~/input_data/Modeldata.inp Cyclic_SSCurve_csv
mv XX_inp XX.inp
