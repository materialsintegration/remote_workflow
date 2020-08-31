#!/bin/bash
python ~/remote_workflow/abaqus_scripts/create_sscurve.py yeild_strength.dat tesile_strength.dat reduction_area.dat
python ~/remote_workflow/abaqus_scripts/create_inputdata.py ~/remote_workflow/input_data/Modeldata.inp Cyclic_SSCurve_csv
mv XX_inp XX.inp
