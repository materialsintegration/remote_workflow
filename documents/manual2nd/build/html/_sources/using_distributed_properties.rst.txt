====
概要
====

MIntには、ワークフローを構成する各モジュール中の任意の部分をMIntの計算ノード以外に処理させることができる「外部計算資源利用」機能がある。ユーザはこの機能を利用してローカルで処理を行わせることにより、下記のような利点が得られる。

* ローカルの部外秘プログラムを使用できる
* ローカルの部外秘データにアクセスできる
* ローカルの特殊 (MIntの計算ノードでは対応できない) 構成の計算機を使用できる
* ローカルの商用ソフトを使用できる (MIntの計算ノードにも商用ソフトがインストールされているが、ライセンス規定により、ほとんどの場合NIMS所外からは利用できない)

外部計算資源の利用に際しては、MIntシステム、外部システムの双方が必要なセキュリティ水準 (後述) を満たしている必要がある。また、両者間のネットワークは常時SSLで暗号化されている。

外部計算資源には、SSHとWebAPIというふたつの方式がある。前者はMIntから外部計算機へSSHでアクセスし、必要なデータとコマンドをプッシュする方式である。単純明快であり、外部処理を遅延なく開始できるという利点があるが、外部システム側でMIntに対しSSHアクセスを認める (ポート開放する) 必要がある点は、特に企業ではハードルが高いと想定される。一方、後者は数分程度の間隔で外部システム側からMIntにWebAPIでポーリングし、処理すべき案件が存在した場合は、必要なデータとコマンドがAPIへの応答としてプルされてくる方式である。この方式では外部システム側にポート開放の必要が無いが、外部処理の開始までに最大でポーリング間隔分の遅延が生じる。

MIntでシステムが収集する情報はワークフローの各ラン (run) におけるモジュールの入口と出口の情報のみであり、モジュールの内部で一部処理を「外注」する本機能は情報収集の対象外である。SSHやWebAPIの通信内容が収集されることはない。また、SSHでもっとも広く利用されているOpenSSHには、標準で (.authorized_keys の設定で) ユーザがMIntに実行させるコマンドを固定する機能がある。さらに、ユーザはローカルから送出されるデータを自らの裁量で十分限定することができる。

これらの仕組みによって、ユーザは安全に外部計算資源利用機能を活用することができる。下記の各章で、必要なセキュリティ条件、ならびに具体的な実装方法について記す。

======
初めに
======

外部計算機資源利用機能を活用するには、

1. 共同研究利用規程、MIntシステム利用規程にしたがうこと。
2. 外部計算機及び接続ネットワークが十分なセキュリティ対策を実施いていること。
3. SSHによる外部計算機資源を利用する場合には、外部計算機資源の受け入れとして、接続元IPのみ接続可能とする設定を行い、脆弱性対策を講じていることとする。

特徴
====

* NIMS DMZに配置したMIntシステムの機能の一部である
        + SSH等で外部の計算機を外部計算機資源として活用可能。
        + 専用APIシステムを利用し、SSH接続が不可能な外部計算機資源を活用可能。
* 外部計算機資源においての秘匿データを扱うことが可能である
        + 秘匿データの指定は外部計算機資源側で設定され隠蔽可能。
        + MIntシステム側からはその存在は感知できない。
* 独自アプリケーションの利用を想定
        + 外部からアクセスした場合にMIntシステムにアクセスした場合に利用できないアプリケーションの利用を想定。
        + アプリケーションの実行設定も外部計算機資源側で行われる。
        + MIntシステムは計算結果だけを送付されるのでアプリケーションの存在は感知できない。

.. figure:: images/image_for_use.eps
  :scale: 70%
  :align: center

  外部計算機資源利用機能を活用した計算のデータの流れ

.. raw:: html

   <A HREF="_images/remote_execution_image.png"><img src="_images/remote_execution_image.png" /></A>

  外部計算機資源利用機能を活用した計算のデータの流れ

本ドキュメントは外部計算機資源の有効活用について、動作原理などを説明し、次いで簡単にインストール、実行する方法を説明する。
インストール、実行はMIntシステム側と外部計算機資源側に分かれている。

NIMSの取り組みについてはこちら [activities_of_NIMS]_ を参照。

.. raw:: latex

    \newpage

扱う方式
========

本書で扱う外部計算機資源の有効活用の方法は以下の２つの形式である。

* SSH方式
    + SSH機能を利用してMIntシステムの任意のモジュールから直接遠隔計算を実行する。すべての通信はSSH機能を利用したリモートコマンド実行により行われる。
* ポーリング方式
    + MIntシステム、外部計算機資源の中間に位置するAPIサーバーを構築。これを利用してMIntシステムの任意のモジュールの計算を外部計算機資源側からポーリングすることで遠隔計算を実行する。全ての通信はこのAPIサーバーを経由して行われる。

使用するリポジトリ
==================

外部計算機資源の有効利用のために、以下２つのリポジトリ [#whatisRepository]_ を用意してある。外部計算機資源側はこれらを外部資源計算用計算機に配置し、必要なコマンドを埋め込むだけでよい。

- misrc_remote_workflow 
    - 主に外部計算機資源側で実行されるスクリプトのサンプルが登録されている。 
- misrc_distributed_computing_assist.api 
    - API方式のためのシステム構築用のプログラム、サンプルが登録されている。 
    - ワークフローで使用するプログラムは「debug/mi-system-side」にある。
    - 外部計算機側で使用するプログラムは「debug/remote-side」にある。 

.. [#whatisRepository] 本機能を実現する資材などを格納したサーバーのこと。GitHubを利用する。格納場所はMIntシステムが用意する。アカウント制御されており、限られたアカウントのみダウンロード可能。アップロードはMIntシステムが許可したアカウントのみ可能である。クラウドサーバーの様な使い方が可能であり、ネット経由で必要なファイル（ソースコードや各種ドキュメント）をダウンロード可能なのでUSBメモリやCD-ROMなどの物理メディアに頼る必要が無い。

諸条件
======

各方式の最低限の条件を以下に挙げる。各方式の使用開始前に必要な設定事項は後述( :ref:`how_to_use` を参照)する。

SSH方式でのアクセスのために
----------------------------

ワークフローからSSHコマンドを利用して、外部計算機にアクセスするために外部計算機を設置する企業または機関にはSSH接続が可能な処置が必要である。

* SSHプロトコルの使用許可および使用ポートの開放。

ポーリング方式でのアクセスのために
-----------------------------------

SSHでの利用が不可能な場合、本方式を使用する。本方式はワークフロー側は直接外部計算機資源にアクセスせず、外部計算機資源側で定期的に問い合わせ（ポーリング）する必要がある。ポーリングには通常のhttps通信を用いる。このための処置が必要である。

* httpsプロトコルの使用許可および使用ポートの開放。

実行されるコマンド
===================

SSHの場合、リポジトリにあるコマンドしか外部計算機上では実行しない。その場所も事前に取り決めた場所となる。APIも同様である。


============================================================
外部計算機資源をMIntシステムから有効に活用するための手法とは
============================================================

最初に各手法の動作原理を説明する。

SSHを利用した遠隔実行
=====================

最初にSSHを利用して、MIntシステムの任意のモジュールから外部計算機資源を利用する方法を説明する。

概要
-----

SSHを利用した遠隔実行とは、SSHプロトコルを利用してネット上でアクセス可能な場所にある計算機をあたかもMIntシステムの計算機の一部として使用すること言う。
この場合SSHパケットが到達可能な場所であればどこでも対象となり得る。
SSHアクセスではパスワードなしでの運用も可能であり、本システムも基本的にパスワードなし接続での運用が前提であるが、必ずしも必須ではない。
スクリプト内で実現可能であればパスフレーズ付きなど多彩なアクセス方法を採用可能である。

.. mermaid::
   :caption: SSH実行のイメージ
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

実行のイメージ
-------------------------------

この方式では、以下のようなシステムで動作サンプルが用意されている。

.. figure:: images/remote_execution_image.eps
  :scale: 70%
  :align: center

  遠隔実行のイメージ

.. raw:: html

   <A HREF="_images/remote_execution_image.png"><img src="_images/remote_execution_image.png" /></A>

  遠隔実行のイメージ

このようにして、特定のモジュール（Abaqus2017）と特定の計算ノード（計算ノード２）を用意し、計算ノード２がMIntシステム外にある計算機を遠隔実行できるように設定して、使用することでMIntシステム外の計算機または計算機群をMIntシステム内にあるかのごとく計算（ワークフロー）を実行することが可能になる。またAbaqus2017と謳ってはいるが実行するプログラムはこれに限らず、様々なコマンド、プログラム、アプリケーションを実行することが可能なように作られている。

.. raw:: latex

    \newpage

システム要件
-----------------

* MIntシステム側
    + 遠隔実行専用の計算ノードを設置してある。
    + 遠隔実行用予測モジュールを作成。
    + このモジュールは専用計算ノードを指定して計算を行うよう設計。
    + モジュールおよび専用計算ノードにSSH操作の設定。
* 外部計算機資源側
    + 外部から到達可能な場所。
    + Linux計算機を想定する。（Macでも可能。WindowsはSSH到達に問題があるため非推奨）。
    + 必要な資材を取得、展開。
    + 必要な情報を設定。（主に実行プログラムパス、パラメータ、秘匿データの配置）

MIntシステム側詳細
-------------

専用計算ノードでは以下のような動作が行われるように、専用モジュールが定義するプログラムを実行する。

必要な資材はGitHubに登録してある。

* パラメータ類の遠隔計算機へ送信（遠隔計算機側にあるパラメータまたはファイルを指定することも可）。
* 遠隔計算機でソルバー（プログラム）の実行。
* 実行が終了したら結果ファイルの取得。

外部計算機資源の詳細
---------------------

外部計算機資源側計算機では、必要なファイルの配置が主な手順である。

必要な資材はGitHubに登録してある。

* 資材の展開
* ソルバーパスの調整
* 秘匿データ（ある場合）に指定のディレクトリへの配置

.. raw:: latex

   \newpage

用意されているサンプルワークフロー
----------------------------------

この方式ではサンプルとして下記のようなイメージの動作検証環境用ワークフローを用意した。

.. figure:: images/workflow_with_sshmodule.png
  :scale: 80%
  :align: center

  動作検証用のワークフロー

※赤枠の部分が遠隔実行の行われるモジュールである。

.. raw:: latex

   \newpage

外部計算機でのディレクトリ
--------------------------

外部計算機のディレクトリ構造は以下のようになっている。インストール方法については後述する。

* ユーザーディレクトリ

.. code-block:: none
  
  ~/ユーザーディレクトリ
    + remote_workflow
      + scripts
        + input_data

* ワーキングディレクトリ

.. code-block:: none

  /tmp/<uuid>

コマンドの流れ
--------------

ワークフローの該当モジュールから外部計算機のコマンドが実行されるまでの流れを下記に示す。

.. mermaid::
   :caption: SSH接続経由によるコマンド実行の流れ
   :align: center

   sequenceDiagram;

     participant A as モジュール
     participant B as プログラム（Ａ）
     participant C as プログラム（Ｂ）
     participant D as プログラム（Ｃ）
     participant E as プログラム（Ｄ）

     Note over A,C : NIMS機構内
     Note over D,E : 外部計算機資源内

     A->>B:モジュールが実行
     B->>C:（Ａ）が実行
     C->>D:（Ｂ）がSSH経由で外部計算機の（Ｃ）を実行
     D->>E:（Ｃ）が実行

* ワークフロー : 予測モジュール
    + MIntシステムが実行する予測モジュール
    + （Ａ）を実行する
* プログラム（Ａ）: kousoku_abaqus_ssh_version2.sh（サンプル用）
    + MIntシステムの予測モジュールが実行する。
    + 予測モジュールごとに用意する。名前は任意。:ref:`how_to_use` で説明する編集を行う。
    + 予測モジュール定形の処理などを行い、（Ｂ）を実行する。
        - （Ｂ）の名前は固定である。
* プログラム（Ｂ）: execute_remote_command.sample.sh
    + （Ａ）から実行された後、外部計算機実行のための準備を行い、SSH経由で（Ｃ）を実行する。
    + 名前は固定である。このプログラムが外部計算機資源との通信を行う。
    + :ref:`how_to_use` で説明する編集を行う。
        - 送信するファイルはパラメータとして記述。
        - （Ｃ）の名前は固定である。
    + 受信するファイルは外部計算機資源上の計算用ディレクトリ [#calc_dir1]_ のファイル全部。
* プログラム（Ｃ）: execute_remote-side_program_ssh.sh
    + （Ｂ）からSSHで実行される。
    + 外部計算機で実行されるプログラムはここへシェルスクリプトとして記述する。
    + インストール時はexecute_remote-side_program_ssh.sample.sh [#sample_name1]_ となっている。
* プログラム（Ｄ）: remote-side_scripts
    + （Ｄ）から実行されるようになっており、いくつかのスクリプトを実行するよう構成されている。
    + サンプル専用であり、必ず使うものではない。（Ｃ）に依存する。


.. [#calc_dir1] 外部計算機では計算は/tmpなどに一時的なディレクトリを作成し計算が実行される。
.. [#sample_name1] 本システムでは、MIntシステムは「execute_remote_command.sample.sh」を実行し、外部計算機で実行を行うプログラムとして「execute_remote-side_program_ssh.sh」を呼び出す。外部計算機側ではインストール後にこのファイル（インストール直後は、execute_remote_program_ssh.sample.shと言う名前）を必要に応じて編集して使用することで、別なコマンドを記述することが可能になっている。

MIntシステムと送受信されるデータ
--------------------------------

MIntシステムへ送受信されるデータは、「execute_remote_command.sample.sh」で決まっており、以下の通り。

* 送信されるデータ
    + 「execute_remote_command.sample.sh」にパラメータとして記述したファイル。（モジュール内）
* 返信されるデータ
    + 計算結果としての出力ファイル。
        - 計算専用ディレクトリを作成して計算され、そのディレクトリ以下のファイルは全て
        - このディレクトリでの計算は、「execute_remote-side_program_ssh.sh」で行われるので、返信不要のファイルはあらかじめこのスクリプト終了前に削除しておくようにスクリプトを構成しておく。

※ 秘匿データを配置してあるディレクトリまたはインストール後のセットアップで実行に必要なファイル、データとして指定されたものはMIntシステムで感知できないこと、およびシステム的に記録（GPDBなど）するための設定がなされていないため送り返されることは無い。

.. raw:: latex

    \newpage

APIを利用したポーリング方式
============================

続いてはAPI(MIntシステムのAPIではない)を利用したポーリング方式による方式の説明である。SSHなどで直接通信が行えない組織間でもhttpまたはhttpsでの通信は可能なことが多く、これを利用することで外部計算機資源の有効活用できることを狙った。ただし現実的にはhttpsまたはTLS1.2以上での通信しか許可されないことが多いので、本方式はhttpsでの通信のみに絞って使用することとし、そのための説明もhttpsの使用を想定した上で行う。

概要
----

APIを利用したポーリングシステムとは外部計算機資源をSSHなどで直接操作するのではなく、中間に計算を仲介するAPIを立て、MIntシステム側、外部計算機資源側がそのAPIを利用してhttps通信で計算の依頼、実行などを行うシステムである。
この場合、外部計算機資源側、MIntシステム側（予測モジュール）は計算工程の随所で定期的に通信する必要がある（ポーリング）ので、ポーリングシステムと言う。
SSHの場合と比べて外部計算機資源の利用および実行のための手続きが多くなり、用意するプログラムも複雑になる。

.. raw:: latex

    \newpage

実行のイメージ
---------------

この方式では以下のようなシステムを想定している。 

.. figure:: images/remote_execution_image_api.eps
  :scale: 70%
  :align: center

  APIを利用した外部計算機資源の利用イメージ

.. raw:: html

   <A HREF="_images/remote_execution_image_api.png"><img src="_images/remote_execution_image_api.png" /></A>

  APIを利用した外部計算機資源の利用イメージ

.. raw:: latex

    \newpage

ポーリングシステムの流れ
----------------------------

この方式でのポーリングシステムのフロー概要。

.. mermaid::
   :caption: ポーリングシステムの流れ
   :align: center

   sequenceDiagram;

   participant A as MIntシステム<BR>（NIMS内）
   participant B as WebAPI<BR>(NIMS内)
   participant C as ポーリングシステム<BR>（ユーザー側）
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

システム要件
---------------

この方式における必要な条件を記す。おもに外部計算機資源側の条件となる。

* 双方で設定必要な事項
   + 実行可能な計算またはプログラム
   + 送受信するファイル
   + この情報をAPIがワークフローから遠隔計算機へ、遠隔計算機からワークフローへと受け渡す。遠隔計算機へはコマンドとパラメータ。ワークフローへは計算結果などのファイルである。
* MIntシステム側
   + 外部計算機資源有効利用用の計算ノードを設置してある。(以下専用計算機または専用ノードとする）
   + 外部計算機資源有効利用モジュールを作成
   + このモジュールは専用計算機を指定して計算を行うよう実装する。
   + ポーリング用APIを実行する。MIntシステムへ到達可能ならどこでもよい。
   + このAPIプログラムはモジュールごとに専用の設定を必要とする。
   + このモジュールはこのAPIとだけ通信する。
* 外部計算機資源側
   + NIMS所外にあって、httpsで本APIへ到達可能なネットワーク設定の場所にあること。
   + 本APIと計算を行うためのポーリングプログラムのサンプルをpythonで用意した。ほとんどの場合このサンプルプログラムで事足りる。
   + 用意する計算機はLinuxが望ましいが、サンプルを利用する場合pythonが実行可能なPCなら何でもよい。
   + 必要な資材を取得、展開。
   + 資材をローカライズ（プログラム等を環境に合わせて編集）

.. raw:: latex

    \newpage

用意されているサンプルワークフロー
----------------------------------

下記イメージの動作検証用サンプルワークフローを用意してある。

.. figure:: images/workflow_with_apimodule.png
   :scale: 100%
   :align: center

   検証用ワークフロー

※赤枠の部分が外部計算機資源を利用するモジュールである。

.. raw:: latex

    \newpage

MIntシステムでのディレクトリ
-----------------------------

MIntシステム側のディレクトリ構造は以下のようになっている。

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

外部計算機資源でのディレクトリ
----------------------------

外部計算機資源のディレクトリ構造は以下のようになっている。インストール方法については後述する。

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

.. raw:: latex

    \newpage

外部計算機でMIntシステムから実行されるプログラム
------------------------------------------------

ワークフローの該当モジュールからAPI経由で外部計算機のコマンドが実行されるまでの流れを下記に示す。

.. mermaid::
   :caption: ポーリング方式でのコマンドの流れ
   :align: center

   sequenceDiagram;

     participant A as モジュール
     participant B as プログラム（Ａ）
     participant C as API
     participant D as プログラム（Ｃ）
     participant E as プログラム（Ｄ）

     Note over A,C : NIMS機構内
     Note over D,E : 外部計算機資源内

     A->>B:モジュールが実行
     B->>C:（Ａ）がhttps経由でAPI発行
     D->>C:（Ｃ）がhttps経由でAPI発行
     D->>E:（Ｃ）が実行

本システムでは、MIntシステムのAPIに設定したプログラムを外部計算機での実行に使用する。
サンプルワークフローでは、「execute_remote-side_program_api.sh」となっている。
外部計算機側ではインストール後にこのファイル（インストール直後は、execute_remote_program_api.sample.shと言う名前）を必要に応じて編集して使用する。

MIntシステムで送受信されるデータ
--------------------------------

MIntシステムで送受信されるデータは、MIntシステム側のAPIと通信するモジュールの実行ファイルであらかじめ決め置く。APIにはその情報によって外部計算機資源とデータのやりとりをする。
この情報に必要なファイルのみ設定することで、それ以外のファイルの存在をMIntシステム側で感知できず、したがって不要なファイルのやりとりは発生せず、秘匿データなどの保護が可能となる。

.. _how_to_use:

========
使用方法
========

インストールおよびプログラムの準備など説明する。SSH方式、API方式のそれぞれの準備から実行までを記述する。

本システムの利用者はMIntシステムのアカウントは既に発行済であるものとし、その手順は記載しない。またgitコマンドなどの利用方法はシステム管理者などに問い合わせることとし、ここではそれらのインストール、詳細な使用方法は言及しない。

手順は以下のようになっている。

* 事前に決めておくこと
* 事前準備
* MIntシステム側の準備
* 外部計算機側の準備
* ワークフローの準備

事前決定事項
============

事前に決定しておく項目は以下の通り。

* misrc_remote_workflowリポジトリの展開場所
    + クライアント側のプログラム実行場所として使用する。
    + 実行プログラム用のテンプレートなどが入っているのでこれを利用する。
* misrc_distributed_computing_assist_apiリポジトリの展開
    + API方式の場合に必要
    + debug/remote-side/mi-system-reote.pyがポーリングプログラムで、これを実行しておく。
* 実行するプログラム
    + 外部計算機資源側で実行するプログラム及び必要なパラメータの調査。
    + MIntシステムから最初に呼び出されるスクリプトを決める
* SSHの場合
    + MInt側からクライアント計算機へのSSHログインのための情報
    + 鍵暗号化方式によるパスワードなし、パスフレーズなし接続が望ましい。
* APIの場合
    + API方式の場合は不特定多数の利用者とAPIプログラムを共有するので、設定事項をMIntシステム側に事前設定しておく。

API方式の場合の設定事項
------------------------
API方式では、SSHとはまた違う認証情報が必要なため、それらを記述する。以下の情報は外部計算機側でポーリングプログラムを実行する際に必要である。

* APIトークン
    + 本方式ではMIntシステムのAPI認証システムを使用しているので、そのトークンが必要となる。NIMS側に問い合わせて取得しておく。
* ホスト情報
    + MIntシステム側でAPI問い合わせに対する個別の識別を行うためにサイト情報（文字列として区別できれば何でもよい）が必要である。
* MIntシステムのURL
    + MIntシステムのURL（エンドポイントは不要）が必要である。NIMS側に問い合わせておく。

.. raw:: latex

    \newpage

SSH方式
=======
SSH方式での準備を決定事項にしたがって実施する。

外部計算機資源側
--------

1. misrc_remote_workflowリポジトリを以下の手順で作成しておく。

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


2. 外部計算機資源側で実行するスクリプトがあれば、「remote-side_scripts」に配置する。
3. MIntシステム側から外部計算機資源側へSSHログインして最初に実行されるプログラム名は「execute_remote-side_program_ssh.sh」である。
このため「execute_remote-side_program_ssh.sample.sh」を「execute_remote-side_program_ssh.sh」にコピーするか、「「execute_remote-side_program_ssh.sh」」を独自に作成し、2.などの実行および必要な手順をスクリプト化しておく。

MIntシステム側
------------------

1. ワークフローを作成する場合に「misrc_remote_workflow/scripts/execute_remote_command.sample.sh」を必要な名称に変更し、内容を参考にしてSSH 経由実行が可能なように編集し、ワークフローから実行させる。
2. 1.を実行可能な通常どおりのワークフローを作成する。作成方法に差は無い。

API方式
=======

外部計算機資源側
-----------------

1. misrc_distributed_computing_assist_apiリポジトリを以下の手順で作成しておく。

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

2. my-system-remote.pyを実行しておく。

  .. code::
  
     $ python mi-system-remote.py rme-u-tokyo https://nims.mintsys.jp <API token>


MIntシステム側
--------------

1. misrc_distributed_computing_assist_apiリポジトリを展開。
2. mi_dicomapi.pyが本体であるが、まだ動作させてなければ、mi_distributed_computing_assist.iniに外部計算機資源側の設定を実施する。動作させていたら、設定の再読み込みを実施する。

  .. code::

     $ python
     >>> import requests
     >>> session = requests.Session()
     >>> ret = session.post("https://nims.mintsys.jp/reload-ini")
     >>>

3. まだ動作していなかったら、動作させて待ち受け状態にしておく。

  .. code::

     $ python mi_dicomapi.py


ワークフローについて
====================

外部計算機資源利用を行うワークフローの作成の仕方を記述する。

共通事項
--------

SSH方式とAPI方式の両方に共通する事項である。

* 予測モジュール
    - pbsNodeGroup設定で、ssh-node01を設定する。他の計算機では外へアクセスすることができないため。
    - pbsQueueなどCPU数などは指定できない。
    - 外部計算機資源側で別途Torqueなどのバッチジョブシステムに依存する。

SSH方式
-------

予測モジュールの実行プログラムから misrc_remote_workflow/scripts/execute_remote_command.sample.sh またはこのファイルを専用に別名コピー編集したものを必要なパラメータとともに実行するように構成する。

API方式
-------

予測モジュールの実行プログラム内で、misrc_distributed_computing_assist_api/debug/mi-system-side/mi-system-wf.py を必要なパラメータとともに実行するように構成する。

.. _sample:

サンプル
--------

misrc_remote_workflowリポジトリにある、sample_dataディレクトリにテストで使用したワークフロー実行用のサンプルファイルが用意されている。これを利用してワークフローおよび外部計算機側の動作の実行テストが可能である。

また、misrc_remote_workflow/scriptsにこの時の予測モジュール実行プログラムがある。これを参考に別な予測モジュール実行プログラムを作成することが可能である。

* kousoku_abaqus_api_version2.py : API方式の予測モジュール実行スクリプト
* kousoku_abaqus_ssh_version2.py : SSH方式の予測モジュール実行スクリプト

以上



















.. [activities_of_NIMS] NIMSの取り組みについて.pdf
