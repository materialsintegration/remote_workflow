========
はじめに
========

MIntには、ワークフローを構成するモジュール内の一部分の処理を、MIntの計算ノード以外の「外部計算機」に行わせる機能がある。本機能によって、ユーザには下記に挙げる利点がある。

* 秘匿プログラムの使用
* 秘匿データの使用
* 特殊構成 (MIntの計算ノードでは対応できない) の計算機を使用できる
* 商用ソフトの使用 (MIntの計算ノードにも商用ソフトがインストールされているが、ライセンスの規定上、ほとんどの場合NIMS外からは利用できない)

外部計算資源の利用に際しては、MInt、外部計算機の双方が後述のセキュリティ水準を満たす必要がある。

1. MIコンソーシアム会則（秘密保持誓約書含む）、MIntシステム利用規定など、MInt利用に関わる契約・規定を遵守すること。
2. MInt側は、下記のセキュリティ対策を実施すること。

    * 第三者によるMIntのセキュリティ分析・セキュリティリスク診断を実施し、リスクを避ける設計を維持すること。
    * MIntを構成するサーバのOS・ミドルウェア・ライブラリ等に対し、継続的に脆弱性データベースを確認し、必要なアップデートを実施すること。
    * 不正アクセス監視やネットワーク負荷監視を実施すること。
3. 外部計算機側は、外部計算機として利用されるコンピュータに対し、十分なセキュリティ対策を実施すること。継続的に利用する場合には、定期的に対策状況を確認し、セキュリティレベルを維持すること。

外部計算資源利用には、SSH方式とWebAPI方式がある。
前者はMIntから外部計算機へSSHで必要なデータとコマンドをプッシュする方式である。
単純で、外部計算を遅延なく開始できる利点があるが、外部計算機側でMIntに対しSSHのポートを開放してプッシュを受け入れる必要がある点は、特に企業ユーザではハードルが高いことが想定される。
これに対し、後者は数分間隔で外部計算機側からMIntにWebAPI(https)でポーリングし、処理すべき案件が存在した場合は、必要なデータとコマンドがプルされる方式である。
この方式では外部計算機側にポート開放の必要が無いが、外部計算の開始までにポーリング間隔に相当する遅延が生じる。

本機能は外部計算機内にユーザが持つ秘匿データの扱いにも十分な配慮が行われている。
まず、ユーザが持つ秘匿データに関して、MIntが収集する情報はワークフローの各モジュールの入出力ポートの情報のみであり、モジュールの内部で完結する本機能のために、モジュールと外部計算機の間で送受信される情報は収集対象外である。
外部計算機側は、MIntにあらかじめ定められたコマンドのみ実行できるように設定することができる。
また、MIntに処理結果を返送する前に不必要なデータをワーキングディレクトリから削除することができる。

上記の機構によって、安全な外部計算が保証される。下記の各章で具体的な利用方法について記す。
また、外部計算資源の利用に際して本書では不明な点は、ユーザとMInt運用チームとの協議で決定するものとする。

.. raw:: latex

    \newpage
====
概要
====

利用イメージ
============

外部計算資源の利用イメージを( :numref:`image_for_use_eps` )に示す。

* MIntはNIMS構内のDMZ [#whatisDMZ]_ に存在する。
* ユーザはMInt上に、外部計算を利用するモジュールを含んだワークフローを持つ。当該モジュールやワークフローの参照・実行権限は自機関内などに限定できる。
* ユーザが当該ワークフローを実行すると、外部計算を利用するモジュールで一部の処理が外部計算機に受け渡される。
* 外部計算機は処理の過程で、MIntに置けないデータやプログラムにアクセスできる。これらのアクセスを外部計算機の内部で完結させることで、安全な利用が可能となる。

.. raw:: html

   <A HREF="_images/remote_execution_image.png"><img src="_images/remote_execution_image.png" /></A>

  外部計算資源の利用イメージ
  
.. figure:: images/image_for_use.eps
  :scale: 60%
  :align: center
  :name: image_for_use_eps

  外部計算資源の利用イメージ

.. raw:: latex

    \newpage

.. [#whatisDMZ] 物理的にはNIMS構内のサーバ室に存在するが、ネットワーク的には機構内LANとインターネットの双方からファイアウォールで切り離された領域。

SSH方式とWebAPI方式の比較
=======================

* SSH方式
    + MIntからSSHで外部計算機にアクセスし、必要なファイルとコマンドをプッシュし、コマンドを発行し、結果を得る。
    + ファイルは内部でrsync -avを利用して送受信され、サイズは無制限である。
    + コマンドラインなどの文字列はBase64エンコード無しで送受信される。
    + 外部計算機側SSHサーバのポート(TCP/22以外でも可)のインバウンドアクセスの開放が必要である。
    + 通信障害には弱い。計算中などで通信が切れると復帰できず、本バージョンでは実行プロセスが簡易なため計算続行が不可能である。
* WebAPI方式
    + 外部計算機からMIntのAPIサーバにポーリングを行い、要処理案件の有無を確認する。ポーリング間隔は数分程度を想定している。案件があれば必要なデータとコマンドをプルし、自らコマンドを実行し、APIで結果を送信する。
    + ファイルはBase64エンコードされ、サイズはエンコード後に2GiB [#whatisGiB]_ 未満である必要がある。
    + コマンドラインなどの文字列はBase64エンコード無しで送受信される。
    + MIntのAPIサーバへのhttps(TCP/50443)のアウトバウンドアクセスの許可が必要である。
    + サーバー側クライアント側で状態を保持しているため、通信障害が起きても再接続と計算続行が可能である。

.. [#whatisGiB] GiB はギビバイトといい、コンピュータの容量や記憶装置の大きさを表す情報単位の一つである。1GiB は 2の30乗バイトであり、1,073,741,824Bである。

.. raw:: latex

    \newpage

========
動作原理
========

SSH方式
=======

動作イメージ
------------

SSH 方式での外部資源利用のイメージを( :numref:`ssh_project_create_flow` )に示す。

.. _ssh_project_create_flow:

.. mermaid::
   :caption: SSH方式の外部資源利用のイメージ
   :align: center

   graph LR;

   subgraph NIMS所外
     input3[\秘匿データ/]
     module21[専用プログラム実行]
     module22[データ返却]
   end
   subgraph MInt
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

ワークフロー例
--------------

SSH方式の外部資源利用を含むワークフローを、MIntのワークフローデザイナで表示した例を示す。
赤枠の部分が遠隔実行の行われるモジュールである。
なお、本ワークフローは動作検証用サンプルとして、:numref:`how_to_use`\ の\ :ref:`how_to_use` で説明するインストール資材に含まれている。

.. figure:: images/workflow_with_sshmodule.png
  :scale: 80%
  :align: center

  動作検証用のワークフロー

.. raw:: latex

    \newpage

モジュール内の処理
------------------

外部資源利用を行うモジュール内で、外部計算機側の処理が実行されるまでの流れを下記に示す。

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
    + プログラム（Ａ）を実行する
* プログラム（Ａ）

    + モジュールによって実行されるプログラム
    + モジュール固有の前処理を行う。
    + モジュールごとに任意の名前で用意する。
    + :numref:`how_to_use`\ の\ :ref:`how_to_use` で説明する編集を行う。
    + （Ｂ）を実行する。
* プログラム（Ｂ） このプログラムが外部計算機と通信を行う。

    + 外部計算の準備を行う。
    + 名前は **execute_remote_command.sh** 固定である。(インストール資材に含まれるサンプルファイルはリネームが必要)
    + :numref:`how_to_use`\ の\ :ref:`how_to_use` で説明する編集を行う。
    + SSH経由で（Ｃ）を実行する。

        - 送信するファイルはパラメータとして記述する。
        - 外部計算機上の一時ディレクトリ [#calc_dir1]_ の内容を全部受信するため、MIntに送信しないデータは外部計算機側で（Ｃ）の実行終了前に削除する。
* プログラム（Ｃ）

    + 名前は **execute_remote-side_program_ssh.sh** 固定である。(インストール資材に含まれるサンプルファイルはリネームが必要)
    + 外部計算機上で実行するプログラムは、ここへシェルスクリプトとして記述する。
* プログラム（Ｄ）

    + 必要に応じて（Ｃ）から実行される外部計算用スクリプト群。
    + 外部計算機上のプログラムを（Ｃ）のみで完結させ、本スクリプト群は用意しない運用も可。

.. [#calc_dir1] 外部計算機では、処理は/tmpなどに作成した一時ディレクトリで実行される。
.. [#sample_name1] 本システムでは、MIntは **execute_remote_command.sample.sh** を実行し、外部計算機で実行するプログラムとして **execute_remote-side_program_ssh.sh** を呼び出す。外部計算機側ではインストール後にこのファイル（インストール直後は、execute_remote_program_ssh.sample.shと言う名前）を必要に応じて編集して使用することで、別なコマンドを記述することが可能になっている。

.. raw:: latex

    \newpage

WebAPI方式
==========

動作イメージ
------------

WebAPI方式での外部計算の実行イメージを( :numref:`WebAPI方式の流れ` )に示す。

.. _WebAPI方式の流れ:

.. mermaid::
   :caption: WebAPI方式の流れ
   :align: center

   sequenceDiagram;

   participant A as MInt<BR>
   participant B as MInt WebAPIサーバ<BR>
   participant C as WebAPI方式<BR>（外部計算機側）
   participant D as ユーザープログラム<BR>（外部計算機側）


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

ワークフロー例
--------------

WebAPI方式の外部資源利用を含むワークフローを、MIntのワークフローデザイナで表示した例を示す。
赤枠の部分が遠隔実行の行われるモジュールである。
なお、本ワークフローは動作検証用サンプルとして、:numref:`how_to_use`\ の\ :ref:`how_to_use` で説明するインストール資材に含まれている。

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
     participant C as WebAPI
     participant D as プログラム（Ｃ）
     participant E as プログラム（Ｄ）

     Note over A,C : MInt内
     Note over D,E : 外部計算機内

     A->>B:モジュールが実行
     B->>C:（Ａ）がhttps経由でAPI発行
     D->>C:（Ｃ）がhttps経由でAPI発行
     D->>E:（Ｃ）が実行

* モジュール

    + MIntのワークフローシステムによって実行されるモジュール
    + プログラム（Ａ）を実行する
* プログラム（Ａ）

    + モジュールによって実行されるプログラム。モジュールごとに任意の名前で用意する。
    + モジュール固有の前処理を行う。
    + **misrc_distributed_computing_assist_api/debug/mi-system-side/mi-system-wf.py** を実行しておく。
      - WebAPIへ計算の情報が登録される。
      - 以降このプログラムが外部計算機資源側（以下の（Ｃ）とAPIを介して計算を行う）
* WebAPI (このプログラムがMIntシステムと外部計算機との通信を中継する。)

    + 外部計算の準備を行う。
        - 送受信するファイルはパラメータとしてあらかじめ設定しておく。
    + WebAPI経由で（Ｃ）からのアクセスを受け付ける
    + （Ａ）から計算の情報登録が無い限り、（Ｃ）からアクセスがあっても計算は始まらない。
    + ワークフローを実行したユーザーのトークンと（Ｃ）からのトークンが合致しないと（Ｃ）は適正な通信相手とならない。
* プログラム（Ｃ）

    + ポーリングプログラムである。
    + **misrc_distributed_computing_assist_api/debug/remote-side/mi-system-remote.py** を実行しておく。
    + 外部計算機上で実行するプログラム名は、このプログラム経由でMIntシステムから受信され、このプログラムが実行する。
    + 認証情報はこのプログラム（Ｃ）が使用する。認証情報が無いとWebAPIにアクセスできない。詳細は\ :numref:`get_authorizaion_infomation`\ の\ :ref:`get_authorizaion_infomation` で説明する。
* プログラム（Ｄ）

    + （Ｃ）から実行される外部計算用スクリプト。
    + 名前は任意。（プログラム（Ｃ）経由で伝えられるため、あらかじめMIntシステム側に設定が必要）
    + **execute_remote_command_api.sh** を参考にして作成しておく。

.. _how_to_use:

========
使用方法
========

SSH方式、WebAPI方式それぞれのインストールおよびプログラムの実行までを外部計算機側で作業が必要な項目について説明する。
なお、外部計算機側はbashスクリプトとPythonスクリプトの動作するLinuxホストを想定しているが、MInt側との通信が正常に確立できるならば、これ以外の環境でも構わない。
その場合はパスワードなしログインの設定などは環境に合わせて適宜同様の処置を行うことになる。
また、外部計算機側で秘匿データを扱う際は、これに関する仕様をMInt側に開示する必要も無い。

.. _before_descide_items:

事前決定事項
============

事前に決定しておく項目は以下の通り。

1. 環境構築

    + 外部計算機側, MIntシステムのユーザアカウントの準備
    + SSH or WebAPIの方式選択
    + 認証関連情報の用意
2. ワークフロー・モジュールの仕様策定 (実装調査書の作成)
 
    + MIntと外部計算機の役割分担の決定
    + MIntと外部計算機の間を受け渡すパラメータ・ファイルの設計
    + MInt側の前処理・後処理の設計
    + 外部計算機側スクリプトの設計

SSH, WebAPI方式共通
==================

.. _get_resources:

資材の入手
----------

外部計算資源の利用に必要な資材は GitHub 上のリポジトリ [#whatisRepository]_ https://github.com/materialsintegration に用意されている。

- misrc_remote_workflow 

    - 主に外部計算機側で実行されるスクリプトのサンプルが同梱されている。
- misrc_distributed_computing_assist.api 

    - WebAPI方式用のプログラムおよびサンプルが同梱されている。
    - MInt側資材は **debug/mi-system-side** 、外部計算機側資材は **debug/remote-side** にある。 

- ワークフローオリエンテッドなリポジトリ

    - 上記リポジトリのサンプルスクリプト以外のワークフローを利用する場合に必要な特別なリポジトリ
    - 通常はgithubにアップされていないので、MInt運用チームに依頼して入手する。

.. note::
   特別なリポジトリを利用する場合の利用方法については別途MInt運用チームまでお問い合わせること。

.. [#whatisRepository] 本機能を実現する資材などを格納したサーバ。GitHubを利用しているが、アカウントが無くともダウンロードは可能である。MInt運用チームがアカウントを発行したユーザのみアップロードが可能である。

ユーザは外部計算機上にこれらを展開し、必要なカスタマイズを行う。
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

.. note::
   ワーキングディレクトリは展開した資材のうち、外部計算機資源側のプログラムが自動的に作成、使用するため、ユーザーは意識しなくて良い。

ユーザが外部計算機側でカスタマイズするファイルは、通常、SSH方式では **misrc_remote_workflow/scripts/execute_remote-side_program_ssh.sample.sh** 、WebAPI方式では事前に名称を決めAPIに登録しておく。カスタマイズの方法については後述する。
これ以外のファイルも改変可能であるが、その改変が原因で外部計算を利用するワークフローが動作しなかった場合、MInt運用チームは責を負わない。

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

ワークフローサンプル
------------------

**misrc_remote_workflow/sample_data** に、Abaqus実行環境が用意可能な場合に使用可能なワークフローおよび、そのサンプル入力ファイルが用意されている。
これを利用して、MInt側と外部計算機側のテストが可能である。
また、**misrc_remote_workflow/scripts** に、この時のモジュール実行プログラムがある。
これを参考に、他のモジュール実行プログラムを作成することが可能である。
利用する際にはMIntシステム側と調整が必要である。

* **kousoku_abaqus_ssh_version2.py** : SSH方式のモジュール実行スクリプト
* **kousoku_abaqus_api_version2.py** : WebAPI方式のモジュール実行スクリプト

もっと簡易な例題ワークフローは現在準備中である。

SSH方式
=======

.. _ready_public_keys:

公開鍵の用意
------------

パスフレーズ無しの公開鍵認証を原則とする。
MInt運用チームに依頼して、パスワードなしログイン用の公開鍵を入手し、以下の手順に沿ってファイルを作成しておく。

  .. code::

     $ cd .ssh
     $ cat <入手した公開鍵暗号ファイル> >> authorized_keys
     $ chmod 600 authorized_keys

.. note::
   ワークフロー実行前にMInt運用チームに連絡してパスワードなしログインが可能なことを確認すること

資材の展開
----------

1. **misrc_remote_workflow** リポジトリを展開する。

  .. code::
  
     $ git clone https://github.com/materialsintegration/misrc_remote_workflow.git
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


2. 外部計算機側で実行するスクリプトがあれば **remote-side_scripts** に配置する。
3. MIntが外部計算機へログインして最初に実行するプログラム名は前述のとおり **execute_remote-side_program_ssh.sh** に固定されている。このため **execute_remote-side_program_ssh.sample.sh** をこの名前でコピーするか、新規に作成して、必要な手順をスクリプト化する。

(参考)MInt側作業
----------------

1. 外部計算資源を利用するモジュールが実行可能なスクリプトを **misrc_remote_workflow/scripts/execute_remote_command.sample.sh** をコピーして専用スクリプトを作成する。
2. 予測モジュールのmodules/resouceRequest/pbsNodeGroupタグに ssh-node01 という値をセットする。
3. 予測モジュールのmodules/objectPathタグに1. で作成したスクリプトをセットする。
4. 1.で作成したスクリプトを各行のコメントに従い適宜修正する。
5. 1.を実行可能な予測モジュールを組み込んだワークフローを作成する。

.. note::
   :numref: `ready_public_keys` :ref: `ready_public_keys` で作成したキーを外部計算機資源側の想定されるユーザーに設定し、パスワードなしログインができることを確認しておく。

WebAPI方式
==========

.. _get_authorizaion_infomation:

認証関連情報の用意
------------------

MInt側担当者に問い合わせて下記の情報を用意する。

* ホスト情報

    + MInt側でAPIの発行者を識別するための文字列。ユーザ企業のドメインなどと一致させる必要は無い。
* APIトークン

    + MIntのAPI認証システムを使用するためのトークン。MIntシステムログイン後、ユーザープロファイル管理システムメニューで表示される、「APIトークン」を使用する。

        - ユーザーの環境でポーリングスクリプトを動作させるときに必要であるが、後述のログイン方式を利用する場合はトークン自体は必要ない。
* MIntのURL

    + MIntのURL(エンドポイントは不要)を、MInt運用チームに問い合わせておく。
* WebAPI方式を利用できるようにMInt運用チームに設定を依頼する。

資材の展開
----------

1. **misrc_distributed_computing_assist_api** リポジトリを展開する。

  .. code::
  
     $ git clone https://github.com/materialsintegration/misrc_distributed_computing_assist_api.git
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

2. **authentication_operator** リポジトリを展開、環境変数を設定する。（ログイン方式を選択する場合）

  .. code::

     $ git clone https://gitlab.mintsys.jp/midev/authentication_operator.git
     $ export AUTHENTICATION_OPERATOR=<path to authentication_operator

.. note::
   環境変数AUTHENTICATION_OPERATORはログインシェルの自動設定ファイルに設定しておく。

3. 計算に必要なスクリプトの準備

   + ファイル名はMInt運用チームに伝えて、APIに登録しておく。
   + 特別なリポジトリを利用する場合はこの作業が必要ないこともある。

実行
----

認証情報と共にポーリングプログラムを動作させておく。事前に設定した情報に従ってMIntシステム側と通信し、入力ファイルの受信、計算、出力ファイルの送信が自動的に行われる。認証情報が無い、間違っている、などの場合はポーリングは失敗し、計算は行われない。
また **ワークフローを実行したユーザーと同じユーザーのトークンまたはログイン方式での同じユーザー** で実行しないとこちらもポーリングは失敗し、計算は行われない。

1. **mi-system-remote.py** を実行する。
2. トークン指定方式

  .. code::
  
     $ python mi-system-remote.py <ホスト情報> https://nims.mintsys.jp <API token>
     site id = rme-u-tokyo
     base url = https://nims.mintsys.jp:50443

3. ログイン方式

  .. code::
     
     $ python mi-system-remote.py <ホスト情報> https://nims.mintsys.jp login
     site id = rme-u-tokyo
     base url = https://nims.mintsys.jp:50443
     nims.mintsys.jp へのログイン
     ログインID: <MIntシステムのログイン名>
     パスワード: <同、パスワード>
      token = <ログイン名のトークンの表示>
     ...
     
.. note::
   ホスト情報は **nims.mintsys.jp** を指定する。
.. note::
   API token は\ :numref:`get_authorizaion_infomation`\ の\ :ref:`get_authorizaion_infomation` で入手した認証情報を指定する。

(参考)MInt側作業
----------------

1. **misrc_distributed_computing_assist_api** リポジトリを展開する。
2. 構成ファイル **mi_distributed_computing_assist.ini** に必要な設定を行う。
3. **mi_dicomapi.py** を動作させて待ち受け状態にする。

  .. code::

     $ python mi_dicomapi.py

  または

  .. code::

     $ systemctl start distcomp_api

4. モジュールの実行プログラム内で、**misrc_distributed_computing_assist_api/debug/mi-system-side/mi-system-wf.py** を必要なパラメータとともに実行するように構成する。

.. note::
   ワークフロー側から計算登録時に構成ファイルは再読込されるので、APIプログラムが現在動作中であっても読み込ませるための特別な動作は必要ない。

.. _sample:

その他MInt側注意事項
---------------------

* pbsNodeGroup設定でssh-node01を設定する。他の計算機では外へアクセスすることができないため。
* pbsQueueなどCPU数などは指定できない。
* 外部計算機側で別途Torqueなどのバッチジョブシステムに依存する。

エラーが発生した場合
====================

ワークフローを本実行する前にMInt運用チームと連携して動作確認を行っておくが、まんいち異常終了した場合などは以下の方法で対策を検討することができる。

* SSH方式、API方式ともワークフローの出力ポートとは別に外部計算機で行われた処理のログがある。MInt運用チームに連絡して、それを入手する。
* 同様に、外部計算機資源側で :numref:`get_resources` :ref:`get_resources` で説明したワーキングディレクトリに計算結果およびログが残っているのでこれを利用する。

     - ワーキングディレクトリはUUIDで構成されたディレクトリ名のディレクトリの作成時間などで該当ディレクトリかどうか判断する。

通信異常
--------

インターネット経由であるので、通信異常は発生するものとして対処してある。APIではリトライ方式を採用している。デフォルトはリトライ間隔60秒のリトライ回数5回で通信失敗として終了する。これは以下の書式で指定することも可能である。

.. code::

     $ python mi-system-remote.py <ホスト情報> https://nims.mintsys.jp <API token> retry:<リトライ回数>,<リトライ間隔>

.. note::
   リトライ回数は整数で指定し、リトライ間隔は整数または実数で指定する。
.. note::
   ssh方式ではその性質上処理中に通信異常が起きると復帰できない。

ワークフローの廃止
==================

ユーザがMInt運用チームにワークフローの廃止届を提出する。当該ワークフローはMInt上で「無効」のステータスを付与され参照・実行不能となる。

|　
|　　 
  
  
以上

