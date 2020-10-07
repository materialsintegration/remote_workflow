#!/usr/bin/python3.6
# -*- coding: utf-8 -*-
# Copyright (c) The University of Tokyo and
# National Institute for Materials Science (NIMS). All rights reserved.
# This document may not be reproduced or transmitted in any form,
# in whole or in part, without the express written permission of
# the copyright owners.

import sys, os
import subprocess
import uuid

def goRemoteSession(client_name, client_cmd, client_files):
    '''
    外部計算機資源の実行を行う。
    @param client_name(string)
    @param client_cmd(string)
    @param client_files(string)
    '''

    # 作業ディレクトリ作成
    calc_dir = str(uuid.uuid4())
    cmd = 'ssh %s "if [ -e /tmp/%s ]; then rm -rf /tmp/%s; fi; mkdir /tmp/%s"'%(client_name, calc_dir, calc_dir, calc_dir)
    print("execute %s"%cmd)
    p = subprocess.call(cmd, shell=True)
    print(p)
    if p == 0:
        print("/tmp/%s で外部計算基資源にディレクトリを作成しました、"%calc_dir)
    else:
        sys.exit(1)

    # 作業ディレクトリへファイルの転送
    files = client_files.split(",")
    for item in files:
        cmd = "rsync -av -L -e ssh %s %s:/tmp/%s > /dev/null 2>&1"%(item, client_name, calc_dir)
        print("execute %s"%cmd)
        p = subprocess.call(cmd, shell=True)
        if p != 0:
            sys.exit(1)

    # コマンドの実行
    cmd = 'ssh %s "cd /tmp/%s; %s > /tmp/%s/remote_program_exec.log 2>&1"'%(client_name, calc_dir, client_cmd, calc_dir)
    print("execute %s"%cmd)
    p = subprocess.call(cmd, shell=True)
    if p == 0:
        print("/tmp/%s でコマンド(%s)を実行しました。"%(calc_dir, client_cmd))
    else:
        sys.exit(1)

    # 作業ディレクトリから全ファイルの取得
    cmd = "rsync -av -e ssh %s:/tmp/%s/ ./"%(client_name, calc_dir)
    p = subprocess.call(cmd, shell=True)
    if p == 0:
        print("%s:/tmp/%s より全ファイルを送信しました。"%(client_name, calc_dir)
    else:
        sys.exit(1)


def main():
    '''
    開始点
    '''

    client_name = None
    client_cmd = None
    client_files = None
    # 引数解釈
    for items in sys.argv:
        items = items.split(":")
        if items[0] == "client_name":
            client_name = items[1]
        elif items[0] == "client_cmd":
            client_cmd = items[1]
        elif items[0] == "client_files":
            client_files = items[1]
        else:
            pass

    # help表示
    if client_name is None or client_cmd is None or client_files is None:
        print("")
        print("遠隔実行スクリプト")
        print("Usage:")
        print("$ python3 %s [options]"%sys.argv[0])
        print("  Options:")
        print("")
        print("     client_name  : sshクライアントのIPアドレス、ホスト名、ssh config名")
        print("     client_cmd   : sshクライアント側で実行されるスクリプトまたはソルバー名")
        print("     client_files : sshクライアント側で実行に必要なファイル名を,（カンマ）区切りで")
        sys.exit(1)

    goRemoteSession(client_name, client_cmd, client_files)

    sys.exit(0)

# コマンドライン実行
if __name__ == "__main__":
    main()
