# -*- coding: utf-8 -*-
'''
Created on August 28, 2017

@author: endo

高速疲労計算におけるSS曲線の導出を行う
出力ファイル名は[Cyclic_SSCurve.csv]とする。
SScurveは応力値を１～３００[MPa]まで1ずつ増加した場合の
歪み値を取得している。

'''

import sys
import os
import pickle
import CycSSCurve

if __name__ == '__main__':
	argvs = sys.argv
	argc = len(argvs)
	ReturnCode = -1
 
    ## 入出力ファイルの確認
	if  argc < 3 : 
		print "args need at least 3"
		sys.exit(ReturnCode)

	# 入出力ファイル名
	yield_filename = argvs[1] 		# 降伏応力のファイル
	tensile_filename = argvs[2] 		# 引っ張り応力のファイル
	reduction_filename = argvs[3]		# 断面減少率のファイル
	out_filename = "Cyclic_SSCurve_csv"	# 出力ファイル名
	print "Yield File : " + yield_filename
	print "Tensile File : " + tensile_filename
	print "Reduction File : " + reduction_filename

	# ヘッダ情報
	print "This module is createing Cyclic SS-cureve Data"
	print "" 
	SScurve = CycSSCurve.CycSSCurve_Class()
	

	## 入力ファイルの読込み
	print "InputData Reading... "
	## 各ファイルからパラメータ値の取得
	with open(yield_filename,"r") as inp_file :
		inp_str = inp_file.readline()
		SScurve.setYield(inp_str)
	
	with open(tensile_filename,"r") as inp_file :
		inp_str = inp_file.readline()
		SScurve.setTensile(inp_str)
	
	with open(reduction_filename,"r") as inp_file :
		inp_str = inp_file.read()
		SScurve.setReduction(inp_str)

	print "Yield strength = " + str(SScurve.getYield())
	print "Tensile strength = " + str(SScurve.getTensile())
	print "Reduction area = " + str(SScurve.getReduction())
	print ""

	# 係数の導出
	SScurve.Calc_Coefficient()
	# 応力値を1～300[MPa]まで1ずつ増加させる
	print "Output Filename : " + out_filename 
	with open(out_filename , "w") as out_file :
		# 初期値(strain=0.0が最初に存在する必要あり）
		stress = 0.1
		strain = 0.0	
		out_line = str(stress) + "," + str(strain) + "\n"
		out_file.write(out_line)

		for stress in range(1,300):
			strain = SScurve.Calc_PlasticStrain(float(stress))	
			out_line = str(stress) + "," + str(strain) + "\n"
			out_file.write(out_line)
	print ""
	print "Createing Cyclic SS-Curve End"
