========
はじめに
========

MIntには、ワークフローを構成するモジュール内の一部分の処理を、MIntの計算ノード以外の「外部計算機」に行わせる機能がある。本機能によって、ユーザには下記に挙げる利点がある。

* 部外秘プログラムの使用
* 部外秘データの使用
* 特殊構成 (MIntの計算ノードでは対応できない) の計算機を使用できる
* 商用ソフトの使用 (MIntの計算ノードにも商用ソフトがインストールされているが、ライセンスの規定上、ほとんどの場合NIMS外からは利用できない)

外部計算資源の利用に際しては、MInt、外部計算機の双方が後述のセキュリティ水準を満たす必要がある。

1. 産学共同研究契約、MIntシステム利用規定など、MInt利用に関わる契約・規定を遵守すること。
2. MInt側は、下記のセキュリティ対策を実施すること。

    * 第三者によるMIntのセキュリティ分析・セキュリティリスク診断を実施し、リストを避ける設計を維持すること。
    * MIntを構成するサーバのOS・ミドルウェア・ライブラリ等に対し、継続的に脆弱性データベースを確認し、必要なアップデートを実施すること。
    * 不正アクセス監視やネットワーク負荷監視を実施すること。
3. 外部計算機側は、外部計算機として利用されるコンピュータに対し、十分なセキュリティ対策を実施すること。継続的に利用する場合には、定期的に対策状況を確認し、セキュリティレベルを維持すること。

外部計算資源利用には、SSH方式とWebAPI方式がある。
前者はMIntから外部計算機へSSHで必要なデータとコマンドをプッシュする方式である。
単純で、外部計算を遅延なく開始できる利点があるが、外部計算機側でMIntに対しSSHのポートを開放してプッシュを受け入れる必要がある点は、特に企業ユーザではハードルが高いことが想定される。
これに対し、後者は数分間隔で外部計算機側からMIntにWebAPI(https)でポーリングし、処理すべき案件が存在した場合は、必要なデータとコマンドがプルされる方式である。
この方式では外部計算機側にポート開放の必要が無いが、外部計算の開始までにポーリング間隔に相当する遅延が生じる。

本機能は外部計算機内にユーザが持つ秘匿データの扱いにも十分な配慮が行われている。
まず、ユーザが持つ秘匿データMIntが収集する情報はワークフローの各モジュールの入出力ポートの情報のみであるため、モジュールの内部で完結する本機能のために、モジュールと外部計算機の間で送受信される情報は収集対象外である。
外部計算機側は、MIntにあらかじめ定められたコマンドのみ実行できるように設定することができる。
また、MIntに処理結果を返送する前に不必要なデータをワーキングディレクトリから削除することができる。

上記の機構によって、安全な外部計算が保証される。下記の各章で具体的な利用方法について記す。
また、外部計算資源の利用に際して本書では不明な点は、ユーザとMInt担当者との協議のうえで決定するものとする。

.. raw:: latex

    \newpage
====
概要
====

利用イメージ
============

外部計算資源の利用イメージを下図に示す。

.. raw:: html

   <A HREF="_images/remote_execution_image.png"><img src="_images/remote_execution_image.png" /></A>

  外部計算資源の利用イメージ
  
.. figure:: images/image_for_use.eps
  :scale: 70%
  :align: center

  外部計算資源の利用イメージ

* MIntはNIMS構内のDMZ [#whatisDMZ]_ に存在する。
* ユーザはMInt上に、外部計算を利用するモジュールを含んだワークフローを持つ。当該モジュールやワークフローの参照・実行権限は自機関内などに限定できる。
* ユーザは当該ワークフローに必要な入力を与えて実行する。
* MIntはモジュールを順次実行する。
* 各モジュールは定義された処理を実行する。外部計算を利用するモジュールでは、一部の処理が外部計算機に受け渡される。
* 外部計算機は処理の過程で、MIntに置けないデータやプログラムにアクセスできる。これらへのアクセスを外部計算機での処理の中で完結させることで、安全な利用が可能となる。
* モジュールは外部計算機から返送された結果を受け取り、定義されていれば必要な後処理を行ってモジュールとしての出力を行う。
* MIntはワークフローの残りの部分を実行し、ユーザに最終結果を出力する。
.. [#whatisDMZ] 物理的にはNIMS構内のサーバ室に存在するが、ネットワーク的には機構内LANとインターネットの双方からファイアウォールで切り離された領域。

SSH方式とWebAPI方式の比較
=======================

* SSH方式
    + MIntからSSHで外部計算機にアクセスし、必要なファイルとコマンドをプッシュし、コマンドを発行し、結果を得る。
    + ファイルは内部でrsync -avを利用して送受信され、サイズは無制限である。
    + コマンドラインなどの文字列はBase64エンコード無しで送受信される。
    + 外部計算機側SSHサーバのポート(TCP/22以外でも可)のインバウンドアクセスの開放が必要である。
* WebAPI方式
    + 外部計算機からMIntのAPIサーバにポーリングを行い、要処理案件の有無を確認する。ポーリング間隔は数分程度を想定している。案件があれば必要なデータとコマンドをプルし、自らコマンドを実行し、APIで結果を送信する。
    + ファイルはBase64エンコードされ、サイズはエンコード後に2GiB未満である必要がある。
    + コマンドラインなどの文字列はBase64エンコード無しで送受信される。(★ホント？★)
    + MIntのAPIサーバへのhttps(TCP/443)のアウトバウンドアクセスの許可が必要である。

.. raw:: latex

    \newpage
========
動作原理
========

SSH方式
=======

動作イメージ
------------

SSH 方式での外部資源利用のイメージを下図に示す。

.. mermaid::
   :caption: SSH方式の外部資源利用のイメージ
   :align: center

   graph LR;

   subgraph NIMS所外
     input3[\秘匿データ/]
     module21[専用プログラム実行]
     module22[データ返却]
   end
   subgraph MIntシステム
     subgraph ワークフロー
       input1[\入力/]
       module11[SSH実行開始]
       module12[SSHデータ受け取り]
       module13[計算]
       output1[/出力\]
     end
   end

   input1-->module11
   module11-->module12
   module12-->module13
   module13-->output1
   input3-->module21
   module11--SSH経由-->module21
   module21-->module22
   module22--SSH経由-->module12

.. raw:: latex

    \newpage

動作イメージ (★この節は必要か？★)
-----------------------------------

下記のサンプルが用意されている。

.. figure:: images/remote_execution_image.eps
  :scale: 70%
  :align: center

  遠隔実行のイメージ

.. raw:: html

   <A HREF="_images/remote_execution_image.png"><img src="_images/remote_execution_image.png" /></A>

  遠隔実行のイメージ

モジュール(Abaqus2017)と、外部計算用の計算ノード(計算ノード２)を用意することで、外部計算資源を利用したワークフローが実行可能となる。
またAbaqus2017と謳ってはいるが実行するプログラムはこれに限らず、様々なコマンド、プログラム、アプリケーションを実行することが可能なように作られている。

.. raw:: latex

    \newpage

ワークフロー例
--------------

.. figure:: images/workflow_with_sshmodule.png
  :scale: 80%
  :align: center

  動作検証用のワークフロー

※赤枠の部分が遠隔実行の行われるモジュールである。

.. raw:: latex

    \newpage

モジュール内の処理
------------------

ワークフローの当該モジュール内で外部計算機側の処理がコマンドが実行されるまでの流れを下記に示す。

.. mermaid::
   :caption: SSH接続経由によるコマンド実行の流れ
   :align: center

   sequenceDiagram;

     participant A as モジュール
     participant B as プログラム（Ａ）
     participant C as プログラム（Ｂ）
     participant D as プログラム（Ｃ）
     participant E as プログラム（Ｄ）

     Note over A,C : MInt内
     Note over D,E : 外部計算機内

     A->>B:モジュールが実行
     B->>C:（Ａ）が実行
     C->>D:（Ｂ）がSSH経由で外部計算機の（Ｃ）を実行
     D->>E:（Ｃ）が実行

* モジュール

    + MIntのワークフローシステムによって実行されるモジュール
    + （Ａ）を実行する
* プログラム（Ａ）: kousoku_abaqus_ssh_version2.sh（例）

    + モジュール固有の前処理を行う。
    + モジュールごとに任意の名前で用意する。
    + :ref:`how_to_use` で説明する編集を行う。
    + （Ｂ）を実行する。
* プログラム（Ｂ）: execute_remote_command.sample.sh

このプログラムが外部計算機と通信を行う。

    + 外部計算の準備を行う。
    + 名前は固定である。
    + :ref:`how_to_use` で説明する編集を行う。
    + SSH経由で（Ｃ）を実行する。

        - 送信するファイルはパラメータとして記述する。
        - 外部計算機上の一時ディレクトリ [#calc_dir1]_ の内容を全部受信するため、MIntに送信しないデータは外部計算機側で（Ｃ）の実行終了前に削除する。
* プログラム（Ｃ）: execute_remote-side_program_ssh.sh

    + 名前は固定である。(インストール時はexecute_remote-side_program_ssh.sample.sh [#sample_name1]_ となっているため、リネームが必要)
    + 外部計算機上で実行するプログラムは、ここへシェルスクリプトとして記述する。
* プログラム（Ｄ）: remote-side_scripts

    + 必要に応じて（Ｃ）から実行される外部計算用スクリプト群。
    + 外部計算機上のプログラムを（Ｃ）のみで完結させ、本スクリプト群は用意しない運用も可。

.. [#calc_dir1] 外部計算機では、処理は/tmpなどに作成した一時ディレクトリで実行される。
.. [#sample_name1] 本システムでは、MIntは「execute_remote_command.sample.sh」を実行し、外部計算機で実行するプログラムとして「execute_remote-side_program_ssh.sh」を呼び出す。外部計算機側ではインストール後にこのファイル（インストール直後は、execute_remote_program_ssh.sample.sh(★正しい？★)と言う名前）を必要に応じて編集して使用することで、別なコマンドを記述することが可能になっている。

.. raw:: latex

    \newpage

WebAPI方式
==========

動作イメージ
------------

WebAPI方式での外部計算の実行イメージを下図に示す。

.. mermaid::
   :caption: WebAPI方式の流れ
   :align: center

   sequenceDiagram;

   participant A as MIntシステム<BR>（NIMS内）
   participant B as WebAPI<BR>(NIMS内)
   participant C as WebAPI方式<BR>（ユーザー側）
   participant D as ユーザープログラム<BR>（ユーザー側）


   C->>B:リクエスト
     alt 計算が存在しない
       B->>C:ありません
       C -->> C:リクエスト継続
     else 計算が存在する
       A->>B:計算要求
       C->>B:リクエスト
       B->>C:存在する
       C->>B:情報取得リクエスト
       alt 計算実行
         B->>C:パラメータ送付、コマンドライン送付
         C->>D:プログラム実行
         alt プログラム実行
           D -->> D:プログラム実行中
         else プログラム終了
           D -->> C:プログラム終了
         end
         C->>B:計算終了通知
       else no seq
       end
       B->>C:計算結果の返却要求
       C->>B:計算結果の返却応答
       B->>A:ジョブの終了要求
     end

.. raw:: latex

    \newpage

動作イメージ (★この節は必要か？★)
-----------------------------------

下記のサンプルが用意されている。

.. figure:: images/remote_execution_image_api.eps
  :scale: 70%
  :align: center

  WebAPI方式を利用した外部計算資源の利用イメージ

.. raw:: html

   <A HREF="_images/remote_execution_image_api.png"><img src="_images/remote_execution_image_api.png" /></A>

  WebAPI方式を利用した外部計算資源の利用イメージ

モジュール(Abaqus2017)と、外部計算用の計算ノード(計算ノード２)を用意することで、外部計算資源を利用したワークフローが実行可能となる。
またAbaqus2017と謳ってはいるが実行するプログラムはこれに限らず、様々なコマンド、プログラム、アプリケーションを実行することが可能なように作られている。

.. raw:: latex

    \newpage

ワークフロー例
--------------

.. figure:: images/workflow_with_apimodule.png
   :scale: 100%
   :align: center

   検証用ワークフロー

※赤枠の部分が外部計算資源を利用するモジュールである。

.. raw:: latex

    \newpage

モジュール内の処理
------------------

ワークフローの当該モジュール内で外部計算機側の処理が実行されるまでの流れを下記に示す。

.. mermaid::
   :caption: WebAPI方式でのコマンドの流れ
   :align: center

   sequenceDiagram;

     participant A as モジュール
     participant B as プログラム（Ａ）
     participant C as API
     participant D as プログラム（Ｃ）
     participant E as プログラム（Ｄ）

     Note over A,C : MInt内
     Note over D,E : 外部計算機内

     A->>B:モジュールが実行
     B->>C:（Ａ）がhttps経由でAPI発行
     D->>C:（Ｃ）がhttps経由でAPI発行
     D->>E:（Ｃ）が実行

APIに設定したプログラムを外部計算機での実行に使用する。
サンプルワークフローでは「execute_remote-side_program_api.sh」となっている。
外部計算機側ではインストール後にこのファイル（インストール直後は、execute_remote_program_api.sample.shと言う名前）を必要に応じて編集して使用する。

.. _how_to_use:

========
使用方法
========

SSH方式、WebAPI方式それぞれのインストールおよびプログラムの実行までを説明する。
なお、外部計算機はbashスクリプトとPythonスクリプトの動作するLinuxホストを想定しているが、MInt側の通信が正常に確立できるならば、これ以外の環境でも構わない。
また、外部計算機側で秘匿データを扱う際は、これに関する仕様をMInt側に開示する必要も無い。

.. _before_descide_items:

事前決定事項
============

事前に決定しておく項目は以下の通り。

1. 環境構築

    + 外部計算機側, MInt側のユーザアカウントの準備
    + SSH or WebAPIの方式選択
    + 認証関連情報の準備
2. ワークフロー・モジュールの仕様策定 (実装調査書の作成)
 
    + MIntと外部計算機の役割分担の決定
    + MIntと外部計算機の間を受け渡すパラメータ・ファイルの設計
    + MInt側の前処理・後処理の設計
    + 外部計算機側スクリプトの設計
3. 資材の展開場所(パス)の決定

    + misrc_remote_workflowリポジトリの展開場所の決定
        - クライアント側のプログラム実行場所として使用する
        - 実行プログラム用のテンプレートなどが入っているのでこれを利用する
    + misrc_distributed_computing_assist_apiリポジトリの展開場所の決定
        - WebAPI方式の場合に必要

SSH, WebAPI方式共通
==================

資材の入手
----------

外部計算資源の利用に必要な資材は GitHub 上のリポジトリ [#whatisRepository]_ に用意されている。
ユーザは外部計算機上にこれらを展開し、必要なカスタマイズを行う。

- misrc_remote_workflow 

    - 主に外部計算機側で実行されるスクリプトのサンプルが同梱されている。
- misrc_distributed_computing_assist.api 

    - WebAPI方式用のプログラムおよびサンプルが同梱されている。
    - MInt側資材は「debug/mi-system-side」、外部計算機側資材は「debug/remote-side」にある。 

リポジトリ上の資材に関しては、以下の条件が適用される。

1. 一部のファイル [#whatisOtherthanfiles]_ を除いてライセンスは「★何？★」が適用され、ソースコードの著作権はMIntが保持する。
2. ユーザはダウンロードしたファイルを改変できるが、この改変が原因で外部計算を利用するワークフローが動作しなかった場合、MInt側は責を負わない。(★この表現で良いのか？★)
3. ユーザが改変したファイルの帰属は………… (★なに？★)
4. 外部計算機側独自の改変を1. 以外のスクリプトに適用したい場合は、MInt担当者(★これでＯＫ？★)と個別に協議する。

.. [#whatisRepository] 本機能を実現する資材などを格納したサーバ。GitHubを利用しているが、MIntがアカウントを発行したユーザのみダウンロードが可能である。
.. [#whatisOtherthanfiles] misrc_remote_workflow/scripts以下にある、SSH方式でのexecute_remote-side_program_ssh.sample.shを複製したファイルと、WebAPI方式でのexecute_remote-side_program_api.sample.shおよびこれらを複製したスクリプトファイルを指す。

資材展開後の外部計算機側のディレクトリ構造は以下のようになる。

* ユーザーディレクトリ

.. code-block:: none
  
  ~/ユーザーディレクトリ
    + remote_workflow
      + scripts
        + input_data
    + misrc_distributed_computing_assist_api
      + debug
        + remote-side

* ワーキングディレクトリ

.. code-block:: none

  /tmp/<uuid>

資材展開後のMInt側のディレクトリ構造は以下のようになる。

* ユーザーディレクトリ

.. code-block:: none

   ~/misystemディレクトリ
    + remote_workflow
      + scripts
    + misrc_distributed_computing_assist_api
      + debug
        + mi-system-side
     
* ワーキングディレクトリ
    + 複雑なので省略する。

(参考) MInt側注意事項
---------------------

* pbsNodeGroup設定でssh-node01を設定する。他の計算機では外へアクセスすることができないため。
* pbsQueueなどCPU数などは指定できない。
* 外部計算機側で別途Torqueなどのバッチジョブシステムに依存する。

SSH方式
=======

公開鍵の用意
----------

パスフレーズ無しの公開鍵認証を原則とする。
外部計算機側で作成したRSA公開鍵 (例: ~/.ssh/id_rsa.pub) をMInt担当者に送付する。
鍵は既存のものでも良いが、下記のコマンドで新規に作成しても良い。

  .. code::

     $ ssh-keygen -t rsa
     Generating public/private rsa key pair.
     Enter file in which to save the key (/home/misystem/.ssh/id_rsa):
     Enter passphrase (empty for no passphrase): 
     Enter same passphrase again: 
     Your identification has been saved in /home/misystem/.ssh/id_test_rsa.
     Your public key has been saved in /home/misystem/.ssh/id_test_rsa.pub.
     The key fingerprint is:
     fd:f6:ab:3c:55:8d:f5:4d:52:60:27:2b:9b:b8:49:fb misystem@zabbix-server
     The key's randomart image is:
     +--[ RSA 2048]----+
     |              +oo|
     |             ..+o|
     |            . .=+|
     |         . . +. =|
     |        S + o  . |
     |         . =  .  |
     |          + o.   |
     |           +..   |
     |            Eoo. |
     +-----------------+

資材の展開
----------

1. misrc_remote_workflowリポジトリを展開する。

  .. code::
  
     $ git clone https://gitlab.mintsys.jp/midev/misrc_remote_workflow
     $ cd misrc_remote_workflow
     $ ls
     README.md  documents  inventories  misrc_remote_workflow.json  modulesxml  sample_data  scripts
     $ cd scripts
     $ ls
     abaqus                                     execute_remote_command.sample.sh  kousoku_abaqus_ssh.sh
     create_inputdata.py                        input_data                        kousoku_abaqus_ssh_version2.py
     execute_remote-side_program_api.sample.sh  kousoku_abaqus_api_version2.py    kousoku_abaqus_ssh_version2.sh
     execute_remote-side_program_ssh.sample.sh  kousoku_abaqus_api_version2.sh    remote-side_scripts
     execute_remote_command.sample.py           kousoku_abaqus_http.py


2. 外部計算機側で実行するスクリプトがあれば「remote-side_scripts」に配置する。
3. MIntが外部計算機へログインして最初に実行するプログラム名は前述のとおり「execute_remote-side_program_ssh.sh」に固定されている。このため「execute_remote-side_program_ssh.sample.sh」をこの名前でコピーするか、新規に作成して、必要な手順をスクリプト化する。

(参考)MInt側準備
----------------

1. 外部計算資源を利用するモジュールが「misrc_remote_workflow/scripts/execute_remote_command.sample.sh」に相当するスクリプト(実際にはリネームされている)が必要なパラメータとともに実行するように構成する。
2. 1.を実行可能なワークフローを、外部計算を含まないものと同じ手順で作成する。

WebAPI方式
==========

認証関連情報の用意
------------------

MInt側担当者に問い合わせて下記の情報を用意する。

* ホスト情報

    + MInt側でAPIの発行者を識別するための文字列。ユーザ企業のドメインなどと一致させる必要は無い。
* APIトークン

    + MIntのAPI認証システムを使用するためのトークン。MInt担当者に問い合わせて取得する。
* MIntのURL

    + MIntのURL(エンドポイントは不要)を、MInt担当者に問い合わせておく。

資材の展開
----------

1. misrc_distributed_computing_assist_apiリポジトリを展開する。

  .. code::
  
     $ git clone https://gitlab.mintsys.jp/midev/misrc_distributed_computing_assist_api
     $ cd misrc_distributed_computing_assist_api
     $ ls
     README.md  logging.cfg     mi_dicomapi_infomations.py           syslogs
     debug      mi_dicomapi.py  mi_distributed_computing_assist.ini
     $ cd debug
     $ ls
     api_status.py  api_status_gui.py  api_status_gui.pyc  mi-system-side  remote-side
     $ cd remote-side
     $ ls
     api-debug.py  debug_gui.py  mi-system-remote.py

2. mi-system-remote.pyを実行する

  .. code::
  
     $ python mi-system-remote.py rme-u-tokyo (★具体名が出ちゃってる？★) https://nims.mintsys.jp <API token>

(参考)MInt側準備
----------------

1. misrc_distributed_computing_assist_apiリポジトリを展開する。
2. mi_dicomapi.pyが未動作であれば、mi_distributed_computing_assist.iniに外部計算機の設定を実施する。動作中であれば、設定を再読み込みする。

  .. code::

     $ python
     >>> import requests
     >>> session = requests.Session()
     >>> ret = session.post("https://nims.mintsys.jp/reload-ini")
     >>>

3. mi_dicomapi.pyを動作させて待ち受け状態にする。

  .. code::

     $ python mi_dicomapi.py

4. モジュールの実行プログラム内で、misrc_distributed_computing_assist_api/debug/mi-system-side/mi-system-wf.py を必要なパラメータとともに実行するように構成する。

.. _sample:

ワークフローサンプル
==================

misrc_remote_workflow/sample_dataに、ワークフロー実行用のサンプルが用意されている。
これを利用して、ワークフローおよび外部計算機側のテストが可能である。

また、misrc_remote_workflow/scriptsに、この時のモジュール実行プログラムがある。
これを参考に、他のモジュール実行プログラムを作成することが可能である。

* kousoku_abaqus_api_version2.py : WebAPI方式のモジュール実行スクリプト
* kousoku_abaqus_ssh_version2.py : SSH方式のモジュール実行スクリプト

ワークフローの廃止
================

ユーザがワークフローの廃止届を提出する。当該ワークフローはMInt上で「無効」のステータスを付与され参照・実行不能となる。

以上


.. [activities_of_NIMS] NIMSの取り組みについて.pdf (★添付？★)
