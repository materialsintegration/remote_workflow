# -*- coding: utf-8 -*-
'''
Created on August 29, 2017

@author: endo

高速疲労計算におけるAbaqusの入力データ作成を行う。
出力ファイル名は[XX.inp]とする。
メッシュデータに関しては「Abaqus.inp」データを前提として作成している。

現在はSS曲線と荷重だけ変更するので、
メッシュ、境界条件、リスト類はそのままAbaqus.inpデータを使用し、
Step条件、Materialの部分のみ変更する。

'''

import sys
import os
import csv

if __name__ == '__main__':
	argvs = sys.argv
	argc = len(argvs)
	ReturnCode = -1
 
    ## 入出力ファイルの確認
	if  argc < 2 : 
		print "args need at least 3"
		sys.exit(ReturnCode)

	# 入出力ファイル名
	mesh_filename = argvs[1] 		# メッシュデータのファイル
	sscurve_filename = argvs[2]		# 繰り返しSS曲線のファイル
	out_filename = "XX_inp"
	print "Mesh filename : " + mesh_filename
	print "Cyclic SS-Curve filename  : " + sscurve_filename

	# ヘッダ情報
	print "This module is createing Abaqus Input Data"
	print "" 


	## 入力ファイルの読込み
	print "InputData Reading... "

	## Abaqus.inpを読み込む
	## Flagで管理
	## -1 : そのまま飛ばす
	## 0 : Abaqus.inpをそのまま記入
	## 1 : MaterialsはSS曲線を使用
	out_flag = 0

	with open(mesh_filename,"r") as mesh_file :
		## 出力ファイル
		with open(out_filename,"w") as out_file :
			for line in mesh_file:
				if "*Plastic" in line:
					out_flag = 1
				elif "**" in line:
					out_flag = 0

				if out_flag == 0 :
					out_file.write(line)
				elif out_flag == 1 :
					## SS曲線
					out_file.write(line)
					with open(sscurve_filename ,"r") as inp_file:
						sscurve_data = csv.reader(inp_file)
						for ss_str in sscurve_data: 
							out_file.writelines(ss_str[0]+","+ss_str[1])
							out_file.write("\n")
					out_flag = -1
				elif out_flag == -1:
					continue
					
	
	print ""
	print "Createing Abqus Input Data  End"
