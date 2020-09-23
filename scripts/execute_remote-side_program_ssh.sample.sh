#!/bin/bash
python3 ~/remote_workflow/scripts/abaqus_scripts/create_sscurve.py yeild_strength.dat tesile_strength.dat reduction_area.dat
python3 ~/remote_workflow/scripts/abaqus_scripts/create_inputdata.py ~/remote_workflow/scripts/input_data/Modeldata.inp Cyclic_SSCurve_csv
mv XX_inp XX.inp
