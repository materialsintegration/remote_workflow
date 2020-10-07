#!/bin/bash
/usr/local/bin/abaqus Job=XX interactive cpus=4 interactive mp_mode=threads
python2 ~/misrc_remote_workflow/scripts/remote-side_scripts/create_sscurve.py yeild_strength.dat tesile_strength.dat reduction_area.dat
python2 ~/misrc_remote_workflow/scripts/remote-side_scripts/create_inputdata.py ~/misrc_remote_workflow/scripts/input_data/Modeldata.inp Cyclic_SSCurve_csv
mv XX_inp XX.inp
