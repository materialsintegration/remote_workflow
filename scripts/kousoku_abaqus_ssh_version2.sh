#!/bin/sh
# 二期外部計算機資源実行、東大榎研サーバー
PROGNAME="$( basename $0 )"
# 入出力ポートのリスト（入力⇒出力の順で、要素に通し番号をつける）
inports=("モデルデータ")
# リンクを作成するファイル名 
inlinks=("Modeldata.inp")

outports=("応力分布データ" "Abaqus入力データ")
outlinks=("XX.dat" "XX.inp")

# 並列数取得
NUMPROCS=`wc -l < $PBS_NODEFILE`
# ソルバー実行コマンド
#EXEC_SOLVER="/opt/Abaqus/Commands/abaqus_u-tokyo Job=XX interactive cpus=$NUMPROCS interactive mp_mode=threads"
EXEC_SOLVER="/opt/Abaqus/Commands/abaqus_u-tokyo Modeldata.inp"
pwd

# -----------------------------------------------------------------
#  User functions
# -----------------------------------------------------------------
#
# 引数チェック関数
function check_arg () {
    if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
        echo "$PROGNAME: option requires an argument -- $1 (Debug: $(timestamp))" 1>&2
        exit 1   
    fi
}
# ファイルの存在チェック
function check_exist () {
    if [ ! -f $1 ]; then
        echo "$PROGNAME: requires a file -- $1 (Debug: $(timestamp))" 1>&2
        exit 1   
    fi
}
# タイムタンプ関数
function timestamp () {
    echo "timestamp[$(date '+%Y-%m-%d %T')]"
}

# -----------------------------------------------------------------
#  Main 
# -----------------------------------------------------------------
#
## inports & outports の要素数と順序に対応するファイルパスリストを準備し、空要素を入れておく  
infiles=(); outfiles=()
for port in ${inports[@]}; do
    infiles=(${infiles[@]} "_")
done
for port in ${outports[@]}; do
    outfiles=(${outfiles[@]} "")
done

# 引数処理（WFプレイヤにより自動生成される実行スクリプトの入出力ファイルに関する引数解析）
for OPT in "$@"; do
    i=0
    for port in ${inports[@]}; do
        if [ "$1" = "--$port" ]; then
            check_arg $1 $2
            check_exist $2
            infiles[$i]=$(readlink -f $2)
            break
        fi
        let i++
    done
    i=0
    for port in ${outports[@]}; do
        if [ "$1" = "--$port" ]; then
            check_arg $1 $2
            # check_exist $2
            work_dir=$(dirname $(readlink -f $2))
            break
        fi
        let i++
    done
    shift 2
done

#
# ソルバー & 入出力ファイル 依存部
#
# ディレクトリ移動
cd $work_dir

# 事前処理
## 必須となる入力ファイル生成/リンク作成
i=0
for link in ${inlinks[@]}; do
    if [ -e ${infiles[$i]} ]; then
        ln -s ${infiles[$i]} $link
    fi
    let i++
done

# ソルバーの実行
$EXEC_SOLVER
if [ $? = 0 ]; then
    echo "ソルバー実行成功"
else
    echo "ソルバー実行失敗"
    exit 1
fi
# 事後処理
## 出力ファイルの解釈
i=0
for links in ${outlinks[@]}; do
        if [ -e $links ]; then
            ln -s $links ${outports[$i]}
        fi
        let i++
done
exit 0
