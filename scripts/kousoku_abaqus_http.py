#!/usr/bin/python3.6
# -*- coding: utf-8 -*-

'''
高速疲労予測計算、応力分布計算、https経由分散環境用
'''

import sys
sys.path.append("/home/misystem/assets/modules/P67_manaka")
from workflow_lib import *

rundir = os.getcwd()
inputports = {'XX_inp':''}
outputports = {'XX_dat':''}
in_realnames = {'XX_inp':'XX.inp'}
out_realnames = {'XX.dat':'XX_dat'}

wf_tool = MIApiCommandClass()
wf_tool.setInportNames(inputports)
wf_tool.setOutportNames(outputports)
wf_tool.setRealName(in_realnames, out_realnames)
wf_tool.Initialize(translate_input=True, translate_output=True)

cmd = "python3.6 /home/misystem/assets/modules/P67_manaka/mi-system-wf.py https://dev-u-tokyo.mintsys.jp nims-dev %s /opt/mi-remote/abaqus.sh XX.inp XX.dat"%(wf_tool.RunInfo["miwf_api_token"])

wf_tool.solver_name = "mi-system-wf.py"
wf_tool.ExecSolver(cmd)

sys.exit(0)
