#!/bin/bash -x

#sleep 10
in_file=""
out_file=""
NUMPROCS=4

# 引数解釈
infiles=("max_s1.py" "weld_shape_pf_param.py" "grain.dat" "tanaka_a.py")
#ssh_client="192.168.1.234"
ssh_client="rme-u-tokyo"
client_cmd="~/misrc_remote_workflow/scripts/remote-side_scripts/fatigue_high_prediction_ssh.sh"
calc_dir=`cat  /proc/sys/kernel/random/uuid`

# 作業ディレクトリ作成
ssh $ssh_client "if [ -e /tmp/$calc_dir ]; then rm -rf /tmp/$calc_dir; fi; mkdir /tmp/$calc_dir"
# ファイルを転送
for item in ${infiles[@]}; do
    rsync -av -L -e ssh $item $ssh_client:/tmp/$calc_dir > /dev/null 2>&1
done

# プログラム実行
echo `date '+%Y-%m-%d %T'`": start: abaqus: unknown" >> /home/misystem/assets/workflow/$MISYSTEM_SITEID/solver_logs/solver_execute.log
# 外部計算実行
ssh $ssh_client "cd /tmp/$calc_dir; $client_cmd > /tmp/$calc_dir/remote_program_exec.log 2>&1"
if [ $? = 0 ]; then
    echo "外部計算実行完了"
else
    echo "外部計算実行失敗"
    exit 1
fi

# 出力結果の取得
if [ -e /tmp/$calc_dir ]; then
    rm -rf /tmp/$calc_dir
fi
rsync -av -e ssh $ssh_client:/tmp/$calc_dir/ ./

exit 0
