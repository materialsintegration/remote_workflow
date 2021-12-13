#!/bin/bash -x
# code_aster SSH 実行スクリプト

#sleep 10
in_file=""
out_file=""
token=""
NUMPROCS=4

# 引数解釈
filecount=1
exec_path="/usr/local/bin/abaqus Job=XX interactive cpus=$NUMPROCS interactive mp_mode=threads"
exec_dir=""
infiles=("reduction_area.dat" "tesile_strength.dat" "yeild_strength.dat")
count=0
token=""
instance_id=$1
model_type=$2
ssh_client="ssh -o ProxyCommand='ssh rme-u-tokyo nc $instance_id 50022' -i ~/id_rsa_cloud -p 50022 rme@"$instance_id
rsync_command="ssh -o ProxyCommand='ssh rme-u-tokyo nc '$instance_id' 50022' -i /home/misystem/id_rsa_cloud -p 50022"
client_cmd="~/misrc_remote_workflow/scripts/remote-side_scripts/code_aster_exec_ssh.sh"
calc_dir=`cat /proc/sys/kernel/random/uuid`

# リポジトリの展開
echo "リポジトリの展開"
echo 'rsync -av -L -e "$rsync_command" ~/assets/modules/misrc_remote_workflow/ rme@$instance_id:~/misrc_remote_workflow/ > /dev/null 2>&1'
rsync -av -L -e "$rsync_command" ~/assets/modules/misrc_remote_workflow/ rme@$instance_id:~/misrc_remote_workflow/ > /dev/null 2>&1

# 作業ディレクトリ作成
echo "作業ディレクトリ作成"
ssh_makedir=$ssh_client' "if [ -e /tmp/$calc_dir ]; then rm -rf /tmp/$calc_dir; fi; mkdir /tmp/$calc_dir"'
echo $ssh_makedir
eval $ssh_makedir
# DB複製
#ssh_db_dup=$ssh_client' "cd ~/Database/Material; cp DP_W_600.comm DP-W-600.comm"'
#eval $ssh_db_dup

# ディレクトリを転送
echo "ディレクトリを転送"
echo 'rsync -av -L -e "$rsync_command" ./codeAster/ rme@$instance_id:/tmp/$calc_dir/codeAster/ > /dev/null 2>&1'
rsync -av -L -e "$rsync_command" ./codeAster/ rme@$instance_id:/tmp/$calc_dir/codeAster/ > /dev/null 2>&1

# プログラム実行
echo "プログラム実行"
echo `date '+%Y-%m-%d %T'`": start: code_aster: unknown" >> /home/misystem/assets/workflow/$MISYSTEM_SITEID/solver_logs/solver_execute.log
ssh_remotecmd=$ssh_client' "cd /tmp/$calc_dir/codeAster; $client_cmd > /tmp/$calc_dir/codeAster/remote_program_exec.log 2>&1"'
echo $ssh_remotecmd
eval $ssh_remotecmd
ssh_remotecmd=$ssh_client' "cd /tmp/$calc_dir/codeAster; "$client_cmd" "$model_type".export Static.export Fatigue.export > /tmp/$calc_dir/codeAster/remote_program_exec.log 2>&1"'
echo $ssh_remotecmd
eval $ssh_remotecmd
if [ $? != 0 ]; then
    echo `date '+%Y-%m-%d %T'`": abnormal end: code_aster: unknown" >> /home/misystem/assets/workflow/site00002/solver_logs/solver_execute.log
    rsync -av -e "$rsync_command" rme@$instance_id:/tmp/$calc_dir/codeAster/remote_program_exec.log ./
    echo "---------- remote side log ----------------"
    cat remote_program_exec.log
    echo "---------- remote side log ----------------"
    exit 1
fi
echo `date '+%Y-%m-%d %T'`": normal end: code_aster: unknown" >> /home/misystem/assets/workflow/site00002/solver_logs/solver_execute.log

# 出力結果の取得
echo "出力結果の取得"
echo 'rsync -av -e "$rsync_command" rme@$instalce_id:/tmp/$calc_dir/codeAster/ ./codeAster/'
rsync -av -e "$rsync_command" rme@$instalce_id:/tmp/$calc_dir/codeAster/ ./codeAster/

exit 0
