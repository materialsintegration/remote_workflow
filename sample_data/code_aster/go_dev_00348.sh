#!/bin/bash

# パラメータ取得用
#python3.6 ~/assets/modules/workflow_python_lib/workflow_params.py workflow_id:W000020000000348 misystem:nims-dev.mintsys.jp version:v4

# 実行
python3.6 ~/assets/modules/workflow_python_lib/workflow_execute.py \
workflow_id:W000020000000348 \
misystem:nims-dev.mintsys.jp \
siteid:site00002 \
version:v4 \
グループリスト_01:GroupList.txt \
プロジェクトプロパティ_01:property.xml \
二次元メッシュ入力ファイル_01:Mesh2D.inp \
溶接パラメータ入力ファイル_01:weldparam.inp \
溶接溶解状態データ_01:weldsolun.dat \
溶接複数レイヤーデータ_01:WeldMultiLayerData.xml \
熱源情報_01:HeatSource.txt \
複数パス入力ファイル_01:MultiPass.inp \
解析モデル指定子_01:argument.txt \
downloaddir:results \
--download
