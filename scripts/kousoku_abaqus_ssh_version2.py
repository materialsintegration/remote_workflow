#!/usr/bin/python3.6
# -*- coding: utf-8 -*-

'''
高速疲労予測計算、応力分布計算、https経由分散環境用
'''

import sys
sys.path.append("/home/misystem/assets/modules/P67_manaka")
from workflow_lib import *

rundir = os.getcwd()
inputports ={"断面減少率":"",
            "引っ張り強度":"",
            "降伏強度":""}
outputports = { "応力分布データ":"",
                "Abaqus入力データ":""}
in_realnames = {"断面減少率":"reduction_area.dat",
                "引っ張り強度":"tesile_strength.dat",
                "降伏強度":"yeild_strength.dat"}
out_realnames = {"XX.dat":"応力分布データ",
                 "XX.inp":"Abaqus入力データ"}

REMOTE_SIDE_DIRECTORY = "/home/manaka"
REMOTE_SIDE_SSHKEY = "rme-u-tokyo"

wf_tool = MIApiCommandClass()
wf_tool.setInportNames(inputports)
wf_tool.setOutportNames(outputports)
wf_tool.setRealName(in_realnames, out_realnames)
wf_tool.Initialize(translate_input=True, translate_output=True)

cmd = "python3.6 /home/misystem/assets/modules/misrc_remote_workflow/scripts/execute_remote_command.sample.py client_name:%s client_cmd:%s/misrc_remote_workflow/scripts/execute_remote-side_program_ssh.sh client_files:reduction_area.dat,tesile_strength.dat,yeild_strength.dat"%(REMOTE_SIDE_DIRECTORY,REMOTE_SIDE_SSHKEY)

wf_tool.solver_name = "execute_remote_command.sample.py"
wf_tool.ExecSolver(cmd)

sys.exit(0)
