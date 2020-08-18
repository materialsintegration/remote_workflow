#!/bin/bash
#python3.6 ~/assets/modules/workflow_python_lib/workflow_params.py workflow_id:W000020000000316 token:13bedfd69583faa62be240fcbcd0c0c0b542bc92e1352070f150f8a309f441ed misystem:dev-u-tokyo.mintsys.jp
python3.6 ~/assets/modules/workflow_python_lib/workflow_execute.py workflow_id:W000020000000316 token:13bedfd69583faa62be240fcbcd0c0c0b542bc92e1352070f150f8a309f441ed misystem:dev-u-tokyo.mintsys.jp \
Yield_strength_01:Yield_Strength.dat \
Ferrite_grain_01:Ferrite_grain.csv \
Volume_fraction_of_pearlite_phase_01:volume_fraction_of_pearlite_phase.dat \
Pearlite_thickness_01:Pearlite_thickness.csv \
Stress_condition_csv_01:stress_condition.csv \
モデルデータ_01:Modeldata.inp
