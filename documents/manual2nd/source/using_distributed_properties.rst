====
はじめに
====

MIntには、ワークフローを構成する各モジュール内の任意の部分を、MIntの計算ノード以外の「外部計算機」に処理させる機能がある。ユーザは本機能を利用して (ローカルなど) MIntシステム外で処理を行わせることにより、下記のような利点が得られる。

* 部外秘プログラムの使用
* 部外秘データの使用
* 特殊構成 (MIntの計算ノードでは対応できない) の計算機を使用できる
* 商用ソフトの使用 (MIntの計算ノードにも商用ソフトがインストールされているが、ライセンス規定により、ほとんどの場合NIMS所外からは利用できない)

外部計算資源の利用に際しては、MIntシステム、外部システムの双方が必要なセキュリティ水準 (後述) を満たしている必要がある。また、両者間のネットワークは常時SSLで暗号化されている。

外部計算資源利用には、SSHとWebAPIというふたつの方式がある。前者はMIntから外部計算機へSSHでアクセスし、必要なデータとコマンドをプッシュする方式である。単純明快であり、外部処理を遅延なく開始できるという利点があるが、外部システム側でMIntに対しSSHアクセスを認める (ポート開放する) 必要がある点は、特に企業ではハードルが高いと想定される。一方、後者は数分程度の間隔で外部システム側からMIntにWebAPIでポーリングし、処理すべき案件が存在した場合は、必要なデータとコマンドがAPIへの応答としてプルされてくる方式である。この方式では外部システム側にポート開放の必要が無いが、外部処理の開始までに最大でポーリング間隔分の遅延が生じる。

MIntでシステムが収集する情報は、ワークフローの各ラン (run) におけるモジュールの入力と出力のみであり、モジュールの内部で一部処理を「外注」する本機能では、SSHやWebAPIの通信内容が収集されることはない。また、SSHでもっとも広く利用されているOpenSSHには、標準で (.authorized_keys の設定で) ユーザがMIntに実行させるコマンドを固定する機能がある。さらに、ユーザはローカルから送出されるデータを自らの裁量で十分限定することができる。

これらの仕組みによって、ユーザは安全に外部計算資源利用機能を活用することができる。下記の各章で、必要なセキュリティ条件、ならびに具体的な実装方法について記す。

======
概要
======

前提条件
====

外部計算資源を利用するにあたっては、下記の点が前提となる。

1. 産学共同研究契約、MIntシステム利用規定、その他のMIntシステム利用に関わる契約・規定の各条項を遵守すること。
2. MInt提供側は、下記のセキュリティ対策を実施すること。

    * MIntシステムに対し、第三者によるセキュリティ分析・セキュリティリスク診断を実施すること。
    * MIntシステムを構成する各サーバのOS,ミドルウェア,ライブラリ等に対し、定期的に JVN 脆弱性情報を確認すること。
    * 前二項で明らかになったリスクに対し、適切な対策を実施すること。
    * アクセス監視やネットワーク負荷監視を実施すること。
3. 外部計算資源の提供側は、外部計算資源として利用されるコンピュータに対し、十分なセキュリティ対策を実施すること。継続的に利用する場合には、定期的に対策状況を確認し、セキュリティレベルを維持すること。
4. 不明な点は、協議のうえで決定すること。

.. raw:: latex

    \newpage

利用イメージ
====

MInt システムのユーザが外部計算資源を利用するイメージを下図に示す。

* MIntシステムはNIMS構内のDMZ(物理的にはNIMS敷地内のサーバ室に存在するが、ネットワーク的にはNIMS LANとインターネットの双方からファイアウォールで切り離された領域) に存在する。
* ユーザはMIntシステム上に、外部計算を利用するモジュールを含んだワークフローを持つ。当該モジュールやワークフローの参照・実行権限は自機関内などに限定できる。
* ユーザは当該ワークフローを呼び出し、必要な入力を与えて実行する。(この手順は外部計算を含まないワークフローと全く同様である)
* MIntシステムはモジュールを順次実行し、外部計算を利用するモジュールでは、外部計算機に必要なデータを送信する。
* 外部計算機は入力データを処理し、MIntシステムに結果を送信する。この際、MIntシステムに直接置くことのできないデータやプログラムにアクセスできる。秘匿データへのアクセスは外部計算機内で完結させることで、秘匿データの安全な利用が可能となる。
* MIntシステムは外部計算機からのデータを受け取り、ワークフローの残りの部分を実行し、ユーザに結果を出力する。
.. raw:: html

   <A HREF="_images/remote_execution_image.png"><img src="_images/remote_execution_image.png" /></A>

  外部計算機資源利用機能を活用した計算のデータの流れ

.. figure:: images/image_for_use.eps
  :scale: 70%
  :align: center

  外部計算機資源利用機能を活用した計算のデータの流れ

* MIntシステムと外部計算機との間のデータ送受信には、SSHもしくはWebAPIが利用される。詳細は後述する。
* MIntシステムではモジュール間を受け渡される情報のみを管理しており、モジュール内の処理に関する情報は収集していない。したがって、外部計算機との間で送受信される情報も収集しない。

.. raw:: latex

    \newpage

アクセス方式
==========

MIntシステムと外部計算機資源の間のアクセスは、下記がサポートされている。

* SSH方式
    + MIntシステム側からSSHで直接外部計算機にアクセスし、必要なファイルのアップロード、コマンドの実行、結果のダウンロードを行う。
* WebAPI方式
    + MIntシステム内に構築されたAPIサーバに対し、外部計算機側からポーリングを行い、処理案件の有無を数分間隔で確認する。案件があれば、外部計算機側からAPIで必要な入力データを受信し、自らでコマンドを実行し、またAPIで結果データを送信する。

使用するリポジトリ
==================

外部計算機資源の有効利用のために、以下２つのリポジトリ [#whatisRepository]_ を用意してある。外部計算機資源側はこれらを外部資源計算用計算機に配置し、プログラム実行に必要なコマンド、ファイル送受信の手続きを設定、埋め込むだけでよい。

- misrc_remote_workflow 

    - 主に外部計算機資源側で実行されるスクリプトのサンプルが登録されている。 
- misrc_distributed_computing_assist.api 

    - WebAPI方式のためのシステム構築用のプログラム、サンプルが登録されている。 
    - ワークフローで使用するプログラムは「debug/mi-system-side」にある。
    - 外部計算機側で使用するプログラムは「debug/remote-side」にある。 

展開したファイルの扱い
----------------------

前項のリポジトリからダウンロードしたファイル類には、以下の制約を課すものとする。

1. 外部計算機資源としての実行に関わる一部のファイル [#whatisOtherthanfiles]_ を除いてライセンスは「★★★」が適用される。
2. 1. の一部ファイルを除くソースコードの著作権はMIntシステムが保持する。
3. 外部計算機資源側での独自の改変は自由とするが、それによって外部計算機資源の有効利用のワークフローが動作しなくなってもMIntシステム側は責任を追わないこととする。
4. リポジトリのアクセスはダウンロードのみとし、外部計算機資源側での独自の改変はリポジトリには反映できない。
5. 外部計算機資源側独自の改変を1. 以外のスクリプトに適用したい場合は、MIntシステムと個別に協議する。

.. [#whatisRepository] 本機能を実現する資材などを格納したサーバーのこと。GitHubを利用する。格納場所はMIntシステムが用意する。アカウント制御されており、限られたアカウントのみダウンロード可能。アップロードはMIntシステムが許可したアカウントのみ可能である。クラウドサーバーの様な使い方が可能であり、ネット経由で必要なファイル（ソースコードや各種ドキュメント）をダウンロード可能なのでUSBメモリやCD-ROMなどの物理メディアに頼る必要が無い。
.. [#whatisOtherthanfiles] misrc_remote_workflow/scripts以下にある、SSH方式を選択した場合のexecute_remote-side_program_ssh.sample.shを複製したファイルとWebAPI方式を選択した場合のexecute_remote-side_program_api.sample.sh及びこれらを複製したスクリプトファイルを指す。

アクセス許可
===========

各方式の利用に際して必要なアクセス許可を以下に挙げる。具体的なな設定内容は後述( :ref:`how_to_use` を参照)する。

SSH方式
-------

MIntシステムのサーバからSSHでアクセスできる必要がある。

* 外部計算機側SSHサーバのポート(TCP/22以外でも可)開放。

WebAPI方式
----------

SSH方式の利用を許可できない場合、本方式を使用する。APIサーバへのポーリングにはhttpsが用いられる。

* MIntが用意するAPIサーバへのhttps通信の許可。

実行されるコマンド
===================

SSH方式の場合、リポジトリにあるコマンドしか外部計算機上では実行しない。その場所も事前に取り決めた場所となる。WebAPI方式も同様である。

送受信内容
==========

* SSH方式

     * SSL暗号化
     * ファイル

          + 非圧縮(rsync -av を内部で利用)
          + サイズ無制限
     * コマンドなどの文字列

          + 平文(非圧縮, Base64エンコード無し)
* WebAPI方式

     * SSL暗号化
     * ファイル

          + 非圧縮
          + Base64エンコード
          + 2 GiB 未満
     * コマンド列などの文字列

          + 平文(非圧縮, Base64エンコード無し)

特殊な実行を行う場合
------------------------------

外部計算機を利用するモジュールでは、外部計算の前後にMIntシステム上でも処理を行うことが可能である。この時送り込まれる該当予測モジュールに関係ないいかなるデータ、ファイルもMIntシステムは感知しないし、GPDBなどへの登録もしないが、ストレージには残る。必要であれば関連スクリプト中で最後に削除の手続きを実施することを推奨する。

データの帰属に関して
--------------------


実行ユーザについて
====================

外部計算機資源側、MIntシステム側双方でアカウントが必要となる。外部計算機資源側はそれぞれの組織内で決定し、MIntシステム側はこの機能を利用する組織がMIntシステム側へアカウント作成の依頼を行う。双方またはどちらかにすでにアカウントがある場合はそれを利用することになる。

ワークフローの廃止
================

本機能を利用したワークフローを廃止する際は、廃止届を提出する。廃止されたワークフローはMIntシステムで「無効」のステータスとなり実行できなくなる。



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
スクリプト内で実現可能であればパスフレーズ付きなど多彩なアクセス方法を採用可能となっている。

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

システム要件概要
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

MIntシステム側
-------------------

専用計算ノードでは以下のような動作が行われるように、専用モジュールが定義するプログラムを実行する。

必要な資材はGitHubに登録してある。

* パラメータ類の遠隔計算機へ送信（遠隔計算機側にあるパラメータまたはファイルを指定することも可）。
* 遠隔計算機でソルバー（プログラム）の実行。
* 実行が終了したら結果ファイルの取得。

外部計算機資源側
---------------------

外部計算機資源側計算機では、必要なファイルの配置が主な手順である。

必要な資材はGitHubに登録してある。

* 資材の展開
* 実行プログラムパスの調整
* 秘匿データ（ある場合）の指定ディレクトリへの配置

.. raw:: latex

   \newpage

用意されているサンプルワークフロー
----------------------------------

サンプルとして下記のようなイメージの動作検証用ワークフローを用意してある。

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

MIntシステムへ送受信されるデータは、「execute_remote_command.sample.sh」に記述しておく。

* 送信されるデータ

    + 「execute_remote_command.sample.sh」にパラメータとして記述したファイル。（モジュール内）
* 返信されるデータ

    + 計算結果としての出力ファイル。
        - 計算専用ディレクトリを作成して計算され、そのディレクトリ以下のファイルは全て
        - このディレクトリでの計算は、「execute_remote-side_program_ssh.sh」で行われるので、返信不要のファイルはあらかじめこのスクリプト終了前に削除しておくようにスクリプトを構成しておく。

※ 秘匿データを配置してあるディレクトリまたはインストール後のセットアップで実行に必要なファイル、データとして指定されたものはMIntシステムで感知できないこと、およびシステム的に記録（GPDBなど）するための設定がなされていないため送り返されることは無い。

.. raw:: latex

    \newpage

WebAPI方式
============================

続いてWebAPI方式の説明を行う。SSHなどで直接通信が行えない組織間でもhttpsプロトコルを利用した通信は可能なことが多く、これを利用することで外部計算機資源の有効活用できることを狙った。ただし現実的にはhttpsまたはTLS1.2以上での通信しか許可されないことが多いので、本方式はhttpsでの通信のみに絞って使用することとし、そのための説明もhttpsの使用を想定した上で行う。

概要
----

WebAPI方式とは外部計算機資源をSSHなどで直接操作するのではなく、中間にプログラムの実行、ファイルの送受信を仲介するAPIを立て、MIntシステム側、外部計算機資源側がそのAPIを利用してhttps通信で計算の依頼、実行などを行うシステムである。
この場合、外部計算機資源側、MIntシステム側（予測モジュール）は計算工程の随所で定期的に通信する必要がある（ポーリング）ので、ポーリング方式とも言う。
SSHの場合と比べて外部計算機資源の利用および実行のための手続きが多くなり、用意するプログラムも複雑になる。

.. raw:: latex

    \newpage

実行のイメージ
---------------

この方式では以下のようなシステムを想定している。 

.. figure:: images/remote_execution_image_api.eps
  :scale: 70%
  :align: center

  WebAPI方式を利用した外部計算機資源の利用イメージ

.. raw:: html

   <A HREF="_images/remote_execution_image_api.png"><img src="_images/remote_execution_image_api.png" /></A>

  WebAPI方式を利用した外部計算機資源の利用イメージ

.. raw:: latex

    \newpage

WebAPI方式の流れ
----------------------------

この方式でのWebAPI方式のフロー概要。

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
   + WebAPI用プログラムを実行する。MIntシステムへ到達可能ならどこでもよい。
   + このAPIプログラムはモジュールごとに専用の設定を必要とする。
   + このモジュールはこのAPIとだけ通信する。
* 外部計算機資源側

   + NIMS所外にあって、httpsで本APIへ到達可能なネットワーク設定の場所にあること。
   + 本APIと計算を行うためのWebAPI方式用プログラムのサンプルをpythonで用意した。ほとんどの場合このサンプルプログラムで事足りる。
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
   :caption: WebAPI方式でのコマンドの流れ
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

インストールおよびプログラムの準備など説明する。SSH方式、WebAPI方式のそれぞれの準備から実行までを記述する。

本システムの利用者はMIntシステムのアカウントは既に発行済であるものとし、その手順は記載しない。またgitコマンドなどの利用方法はシステム管理者などに問い合わせることとし、ここではそれらのインストール、詳細な使用方法は言及しない。

手順は以下のようになっている。

1. 事前に決定しておく事項の列挙
2. 外部計算機側の準備
3. Intシステム側の準備
4. 専用予測モジュールの準備
5. ワークフローの準備
6. WebAPI方式の場合の準備

.. _before_descide_items:

使用開始前に
============

事前決定事項の列挙
------------------

事前に決定しておく項目は以下の通り。

1. 方式の決定

    + 害撫計算機資源側実行ユーザーの決定または無い場合は作成。
    + MIntシステム側ユーザーの決定または無い場合は作成。

         - API方式の場合設定されているAPIトークンの取得。
    + 方式毎の認証情報の取り決め
2. 解析、計算の決定
 
    + MIntシステム側で使用可能で、必要なモジュールの選定。
    + 外部計算機資源側で1.を考慮にいれ、用意する必要のある手順の検討。
3. 実行するプログラム

    + 2. の見当の結果、外部計算機資源側で実行するプログラム及び必要なパラメータの調査。
    + MIntシステムから最初に呼び出されるスクリプトの決定。
4. misrc_remote_workflowリポジトリの展開場所

    + クライアント側のプログラム実行場所として使用する。
    + 実行プログラム用のテンプレートなどが入っているのでこれを利用する。
5. misrc_distributed_computing_assist_apiリポジトリの展開場所

    + WebAPI方式の場合に必要。
    + debug/remote-side/mi-system-reote.pyがWebAPI方式プログラムで、これを実行しておく。

SSH方式の認証情報
-------------------

SSH方式では基本的にパスワードなし接続とするため、RSA/TSAどちらかの公開鍵暗号ファイルをMIntシステム側に設定する必要がある。

1. RSA方式の公開鍵暗号ファイルの作成方法にしたがい公開鍵暗号ファイルを外部計算機資源側の実行ユーザーで作成する。

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

* すべてエンターのみとする。
* 既に存在している場合はそれを使う。

2. 作成された「~/.ssh/id_rsa.pub」ファイルをMIntシステム担当者まで送付する。

WebAPI方式の認証情報
--------------------
WebAPI方式では公開鍵ではなく、事前に取り決める「サイト名（半角英数字。文字数制限なし）」と「APIアクセストークン(MIntシステムで作成するユーザーアカウントに設定される)」を用意しておく。

* サイト名：他の外部系さ機資源の有効利用で使用していない名称であること。
* APIアクセストークン：MIntシステムに登録されている外部計算機資源側に属する人のアカウントおよびそこに設定されているAPIトークン。

外部計算機資源側の準備
----------------------

1. :ref:`before_descide_items` の 4. と 5. で決定した場所へリポジトリを展開する
2. :ref:`before_descide_items` の 3. で決定したスクリプトを作成する。

MIntシステム側の準備
--------------------

1. 実装調査書の作成

    + :ref:`before_descide_items` 2.の情報（スクリプトと送受信するパラメータ）を盛り込む。

専用予測モジュールの準備
--------------------------

1. 専用予測モジュールの作成

    + どちらの方式を採用するか。
    + 1.の情報を盛り込んだ予測モジュールを作成する。
2. ワークフローの準備

    + 2. で作成した予測モジュールを使用するワークフローを作成する。
3. SSHの場合

    + MInt側からクライアント計算機へのSSHログインのための情報
    + 鍵暗号化方式によるパスワードなし、パスフレーズなし接続が望ましい。
4. WebAPI方式の場合

    + WebAPI方式の場合は不特定多数の利用者とAPIプログラムを共有するので、認証などの設定事項をMIntシステム側に事前設定しておく。

WebAPI方式の場合の設定事項
------------------------------
WebAPI方式では、SSHとはまた違う認証情報が必要なため、それらを記述する。以下の情報は外部計算機側でWebAPIプログラムを実行する際に必要である。

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
-----------------

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

WebAPI方式
==============

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

SSH方式とWebAPI方式の両方に共通する事項である。

* 予測モジュール

    - pbsNodeGroup設定で、ssh-node01を設定する。他の計算機では外へアクセスすることができないため。
    - pbsQueueなどCPU数などは指定できない。
    - 外部計算機資源側で別途Torqueなどのバッチジョブシステムに依存する。

SSH方式
-------

予測モジュールの実行プログラムから misrc_remote_workflow/scripts/execute_remote_command.sample.sh またはこのファイルを専用に別名コピー編集したものを必要なパラメータとともに実行するように構成する。

WebAPI方式
----------

予測モジュールの実行プログラム内で、misrc_distributed_computing_assist_api/debug/mi-system-side/mi-system-wf.py を必要なパラメータとともに実行するように構成する。

.. _sample:

サンプル
--------

misrc_remote_workflowリポジトリにある、sample_dataディレクトリにテストで使用したワークフロー実行用のサンプルファイルが用意されている。これを利用してワークフローおよび外部計算機側の動作の実行テストが可能である。

また、misrc_remote_workflow/scriptsにこの時の予測モジュール実行プログラムがある。これを参考に別な予測モジュール実行プログラムを作成することが可能である。

* kousoku_abaqus_api_version2.py : WebAPI方式の予測モジュール実行スクリプト
* kousoku_abaqus_ssh_version2.py : SSH方式の予測モジュール実行スクリプト

以上



















.. [activities_of_NIMS] NIMSの取り組みについて.pdf
