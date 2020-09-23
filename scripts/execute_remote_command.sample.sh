#!/bin/bash -x

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
#ssh_client="192.168.1.234"
ssh_client="rme-u-tokyo"
client_cmd="~/misrc_remote_workflow/scripts/execute_remote-side_program_ssh.sh"
calc_dir=`cat  cat /proc/sys/kernel/random/uuid`

# 作業ディレクトリ作成
ssh $ssh_client "if [ -e /tmp/$calc_dir ]; then rm -rf /tmp/$calc_dir; fi; mkdir /tmp/$calc_dir"
# ファイルを転送
for item in ${infiles[@]}; do
    rsync -av -L -e ssh $item $ssh_client:/tmp/$calc_dir > /dev/null 2>&1
done

# プログラム実行
echo `date '+%Y-%m-%d %T'`": start: abaqus: unknown" >> /home/misystem/assets/workflow/$MISYSTEM_SITEID/solver_logs/solver_execute.log
# inp ファイル作成
ssh $ssh_client "cd /tmp/$calc_dir; $client_cmd > /tmp/$calc_dir/remote_program_exec.log 2>&1"
if [ $? = 0 ]; then
    ech "created inp file"
else
    echo "faild create inp file"
    exit 1
fi
ssh $ssh_client "cd /tmp/$calc_dir; $exec_path >> /tmp/$calc_dir/remote_program_exec.log 2>&1"
if [ $? = 0 ]; then
    echo "success to execute abaqsu"
else
    echo "abaqus execute faild."
    exit 1
fi
if [ $? != 0 ]; then
    echo `date '+%Y-%m-%d %T'`": abnormal end: abaqus: unknown" >> /home/misystem/assets/workflow/site00002/solver_logs/solver_execute.log
    rsync -av -e ssh $ssh_client:/tmp/$calc_dir/remote_program_exec.log ./
    echo "---------- remote side log ----------------"
    cat remote_program_exec.log
    echo "---------- remote side log ----------------"
    exit 1
fi
echo `date '+%Y-%m-%d %T'`": normal end: abaqus: unknown" >> /home/misystem/assets/workflow/site00002/solver_logs/solver_execute.log

# 出力結果の取得
if [ -e /tmp/$calc_dir ]; then
    rm -rf /tmp/$calc_dir
fi
rsync -av -e ssh $ssh_client:/tmp/$calc_dir/ ./

exit 0
