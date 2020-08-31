# 外部計算機資源の有効活用（SSH版）

# 概要
このリポジトリにはモジュールを遠隔実行するために必要な資材、情報が格納されている。ただし初期段階では特定の計算機、特定のソルバーが対称なので、初期の資材にはそれらの情報がじかに埋め込んであると思われる。本リポジトリは実証後の本格的な展開を行うための参考資料となる意味合いが強い。
実証テストでは高速疲労ワークフローの応力分布計算モジュールにこの遠隔実行の設定を行った。
このため当リポジトリには応力分布計算モジュールを作成するための資材のみが入っている。

当リポジトリは外部計算機資源の有効活用に置ける、SSH実行のための資材とインストール方法などが格納されている。
API実行に必要な資材の詳細は、リポジトリ名「https://gitlab.mintsys.jp/midev/misrc_distributed_computing_assist_api」を参照のこと。

なお、インストーラ、設計書などの根本的な情報はすべて当リポジトリにて管理する方向である。「https://gitlab.mintsys.jp/midev/misrc_distributed_computing_assist_api」には構築資材以外の情報は格納しない予定。

## リポジトリ名
misrc_remote_workflow

# 必要環境
この遠隔実行モジュールを含むワークフローは高速疲労予測計算ワークフロー（misrc_fast_fatigue_predicition）をベースとしているので、必要環境もこれに準じている。

# フォルダ構成
## original
ソースコードのオリジナルが格納されている

## script
モジュールの実行スクリプトが保存されている。

## reference
ワークフローおよびプログラムに関するドキュメントがある。

## inventories
descriptor, prediction_model, software_toolの辞書単位の出力JSONファイル。inventory-operatorプログラムを使って配布することができる。元は開発環境のもの。

## sample_input
動作確認に使える入力ファイルがある。

## modulesxml
予測モジュール定義ファイルがある。ソースは開発環境のもの。

# 当予測モジュールの使い方概要。
当予測モジュールを使用した遠隔実行を行うためには、以下の手順にそって準備する。
1. ベースとなるのは高速予測疲労計算である。既に高速疲労予測計算ワークフローが実装されている場合はこれを複製して使用する。無い場合はmisrc_fast_fatigue_predicitionを参考にして高速疲労予測計算ワークフローを実装しておく。
2. 当リポジトリの資材を使うことで高速疲労予測計算のモジュールのうち、応力分布計算モジュールを遠隔実行専用モジュールとして置き換えることができる予測モデル、予測モジュールがMIシステムに実装される。
3. 複製された高速疲労予測計算ワークフローの応力分布計算のモジュールを実装された遠隔実行用応力分布計算モジュールに置き換える。

# 実装、準備手順
接続手順により、設定項目がある。それぞれについて記述する。またssh接続は秘密鍵＋秘密鍵のパスフレーズ併用方式とし、チャレンジレスポンス方式は考慮しないこととする。
※ 秘密鍵の名前はid_rsa-組織名などとすることを推奨する。

## ssh接続
## socksプロキシ経由ssh接続
NIMSに正式な設定資料はなく、ネット上の検索結果による一般的なsocksプロトコルを使ったssh接続方法とNIMSでの過去存在した資料の伝聞による設定との組み合わせを実施する。
[参考ページ](https://blog.ymyzk.com/2013/10/ssh-over-socks-https/)
* socksプロキシの設定  
  socksプロキシは以下のconfigファイルに設定するので必要ない。
* ssh用configファイル  
  CentOS7用とCentOS6用でProxyCommandのパラメータが違うので注意  
  + ホームディレクトリ以下に、.ssh/configファイルを作成し、以下のように記述する。
    ```
    Host remote-site
    Hostname xxx.xxx.xxx.xxx
    Port 50022
    User remote-site-user-name 
    ProxyCommand nc --proxy socks.nims.go.jp:1080 --proxy-type socks4 %h %p
    IdentityFile ~/.ssh/id_rsa-xxx
    ```
  + ssh用configファイル(CentOS6用)
    ```
    Host u-tokyo
    Hostname 133.11.86.170
    Port 50022
    User misystem
    ProxyCommand nc -x socks.nims.go.jp:1080 -X 4 %h %p
    IdentityFile ~/.ssh/node05_u-tokyo/id_rsa
    ```
* 接続は
  ```
  $ ssh remote-site
  Enter passphrase for key '/home/yourdirectory/.ssh/id_rsa-xxx':
  ```
  パスフレーズを入力してログインする。 
  ※ 作成した.sshを含むディレクトリは、パーミッションを700としておくこと。

## プログラム展開
### 概要
必要なプログラムに関して概要を記述する。

* scripts/abaqus
  + 予測モジュールの実行ファイルから実行される。
  + 外部計算機側のソルバーを実行するプログラム。 
    - 外部計算機資源へのMIntシステム側の窓口となる計算機へ作成する。
    - /opt/Abaqus/Command/abaqus　などとファイルを作成しておく。（実行権を忘れず付与する）
* script/kousoku_abaqus_ssh.sh
  + 予測モジュールの実行ファイル。
  + 予測モジュールの<objectPath>に指定する。
  + 予測モジュールの<resourceRequest><pbsNodeGroup>にssh-node01などのように、MIntシステムのこのスクリプト専用計算ノードのホスト名を指定する。

* script/create_inputdata.py（二期対応外部計算機資源の有効利用）
  + 外部計算機資源に配置する。
  + パラメータとして、外部計算機資源側のデータを必要とする。
    - このデータを扱うことで秘匿データが扱えることの検証となる。
    - 外部計算機資源として外部実行の対象となる計算機のどこかへ配置する。
    - 配置場所は、scrpits/abaqusにパスとして設定する。

### 詳細

scripts/abaqusは、偽のAbaqus実行プログラムとして作成します。この中で実際に外部計算機資源へssh接続でパラメータを送信し、そのパラメータとAbaqus実行コマンドを使って、Abaqusの実行を行います。
Abaqus実行終了後は出力される結果のファイルをssh 接続で受信します。

scripts/kousoku_abaqus_ssh.sh は、予測モジュールが実行するプログラムである。これ自体は通常のAbaqus実行プログラムと何ら変わるところはない。違うのは予測モジュールのresourceRequestとpbsNodeGroupタグへの設定である。これらを設定することでpbsNodeGroupに設定した計算機

この２つのスクリプトを所定の場所に配置し、必要な設定を行うことで、ワークフローの実行時、該当モジュールが外部計算機資源を利用して計算を行い、あたかもMIntシステム内で計算がおこなわれたかのごとく振る舞うことが可能になる。
ソルバープログラムは外部計算機に行わせるのみで、記述子のデータはsshを利用して送受信される。
このため入力ポート、出力ポートのデータはGPDBに登録される。

