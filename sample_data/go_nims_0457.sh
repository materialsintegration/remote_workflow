#!/bin/bash
#python3.6 ~/assets/modules/workflow_python_lib/workflow_params.py workflow_id:W000110000000457 token:e7abea75b719f811a7c5b6c75a993352e00ba9eb74bc2717041212865f20a874 misystem:nims.mintsys.jp
python3.6 ~/assets/modules/workflow_python_lib/workflow_execute.py \
workflow_id:W000110000000457 \
token:e7abea75b719f811a7c5b6c75a993352e00ba9eb74bc2717041212865f20a874 \
misystem:nims.mintsys.jp \
siteid:site00011 \
降伏強度_01:Yield_Strength.dat \
断面減少率_01:Reduction_area.dat \
引っ張り強度_01:Tensile_strength.dat \
フェライトの粒径分布_01:Ferrite_grain.csv \
パーライトの体積分率_01:volume_fraction_of_pearlite_phase.dat \
パーライトの厚さ分布_01:Pearlite_thickness.csv \
応力条件_01:stress_condition.csv \
モデルデータ_01:Modeldata.inp
