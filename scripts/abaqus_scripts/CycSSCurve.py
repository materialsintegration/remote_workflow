# -*- coding: utf-8 -*-
'''
Created on August 28, 2017

@author: endo

高速疲労計算におけるSS曲線の導出を行う関数を実装している。
将来的にnumpy,scipyを導入する予定

高速疲労計算はヤング率・ポアソン比を以下の値で固定している

ヤング率	209000[MPa]
ポアソン比	0.3[-]

'''
import sys
import os
import math

## データクラス
class CycSSCurve_Class :
	#コンストラクタ
	def __init__(self):
		# data配列には以下の値を入れる
		# 0: yield_strength(降伏応力）
		# 1: tensile_strength(引っ張り強さ）
		# 2: reduction_area(面積減少率）
		self.data = [0.0] * 5
		
		# 3: ヤング率
		# 4: ポアソン比
		self.data[3] = float(209000)
		self.data[4] = 0.3

		# 曲線を導出するために必要な係数K、m
		self.K = 0.0 
		self.m = 0.0

	def setYield(self,value):
		self.data[0] = float(value)
	def getYield(self):
		return self.data[0]


	def setTensile(self,value):
		self.data[1] = float(value)
	def getTensile(self):
		return self.data[1]

	def setReduction(self,value):
		self.data[2] = float(value)
	def getReduction(self):
		return self.data[2]

	# 応力歪み曲線で用いられるK,mを求める式			
	#													条件分岐
	# 		( 2.16 * 10^(-4) ) * σb^2.1 + 738 			(σb/σy <= 1.2)
	# K =   ( 3.63 * 10^(-4) ) * σb^2 + 0.68σb + 570 	( 1.2 < σb/σy <= 1.4 )
	#		1.21 * σb + 555 							( 1.4 < σb/σy )
	#
	# 	  lnK - ln( 0.089(1+r)^1.35 * σb^1.35 * (-0.002/ln(1-r))^0.216 + 120)
	# m = -------------------------------------------------------------------
	#									ln500
	#
	# σy:Yield Strength  σb:Tensile Strength  r:Reduction Area
	def Calc_Coefficient(self):
		print "Calculate K and m ..."
		YS = self.data[0]
		TS = self.data[1]
		RA = self.data[2]
		# エラー処理
		# Tensile Strength, Yield Strength は0 
		# Reduction Areaは1の場合に計算が破綻する
		if YS <= 0.0 :
			print "Error: Yeild Strength Wrong value : " + str(self.data[0])
			sys.exit(2)
		elif TS <= 0.0 :
			print "Error: Tensile Strength Wrong value : " + str(self.data[1])
			sys.exit(2)
		elif RA < 0.0  or self.data[2] >= 1.0 :
			print "Reduction Area must be in 0 <= r < 1 : " + str(self.data[2])
			sys.exit(2)

		# Kの計算
		coef_value = TS/YS
		print "σB/σY = " + str(coef_value)
		if  coef_value <= 1.2 :
			self.K = ( 2.16 * pow(10,-4) ) * pow(TS,2.1) + 738
		elif coef_value <= 1.4 :
			self.K = ( 3.63 * pow(10,-4) ) * pow(TS,2.0) + 0.68 * TS +  570
		else :
			self.K = 1.21 * TS + 555

		# mの計算
		self.m = (math.log(self.K) - math.log(0.089*pow(1+RA,1.35) * pow(TS,1.35) * pow((-0.002/math.log(1-RA)),0.216) + 120)) / math.log(500)

		#print "math.log(self.K) = " + str(math.log(self.K))  + ", math.log(A) = " + str(math.log(0.089*pow(1+RA,1.35) * pow(TS,1.35) * pow((-0.002/math.log(1-RA)),0.216) + 120)) \
		#		+ ", math.log(500) = " + str(math.log(500))
		print "K = " + str(self.K)
		print "m = " + str(self.m)

        # 歪み値を算出する
        #        σ
        # ε = (---)^(1/m)
        #        K
        # ε:歪み値　K,m:上記式で求めた係数　σ：応力値

	def Calc_PlasticStrain(self,value):
		#strain = self.K * pow( float(value/self.data[3]), self.m)
		strain = pow( (value/self.K) , 1/self.m)
		#print "K=" + str(self.K)  + ", stress = " + str(value) + ", Young_coef= " + str(self.data[3]) + ", m= " + str(self.m)
		#print "value/Young=" + str(float(value/self.data[3])) + " (volue/K)^(1/m)=" + str(pow( (value/self.K) , 1/self.m) )
		#print " stress = " + str(value) + ", σ/E = " + str(float(value/self.data[3])) + ", σ/E^(m) = " + str(pow( float(value/self.data[3]) , self.m)) + ", strain = " + str(strain)
		return strain 
