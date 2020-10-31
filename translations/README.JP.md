# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**Read this in**
[🇩🇪](translations/README.de.md)	
[🇷🇺](translations/README.ru.md)	
[🇹🇷](translations/README.tr.md)	
[🇺🇦](translations/README.ua.md)	
[🇨🇳](translations/README.zh.md)	
[🇫🇷](translations/README.fr.md)
[🇧🇷](translations/README.pt-BR.md)
**[other languages](translations/#readme).**

**OpenEBS** は、Kubernetes向けに最も広く展開されている使いやすいオープンソースストレージソリューションです。

**OpenEBS** は、[コンテナ接続ストレージ](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/)と呼ばれることもあるストレージソリューションのカテゴリの主要なオープンソースの例です。. **OpenEBS** [CNCFストレージランドスケープホワイトペーパー](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) にオープンソースの例として記載されています ハイパーコンバージドストレージソリューションの下で.

OpenEBSを他の従来のストレージソリューションと比較して異なるものにするいくつかの重要な側面：
-サービスを提供するアプリケーションのようなマイクロサービスアーキテクチャを使用して構築されています。 OpenEBS自体は、Kubernetesワーカーノードにコンテナーのセットとしてデプロイされます。 Kubernetes自体を使用してOpenEBSコンポーネントをオーケストレーションおよび管理します
-完全にユーザースペースに組み込まれているため、あらゆるOS /プラットフォームで実行できる移植性が高い
-完全にインテントドリブンで、Kubernetesの使いやすさを推進するのと同じ原則を継承します
-OpenEBSは、開発者がアプリケーション設計の目的に適したストレージテクノロジーを展開できるように、さまざまなストレージエンジンをサポートしています。 Cassandraのような分散アプリケーションは、LocalPVエンジンを使用して書き込みの待ち時間を最小限に抑えることができます。 MySQLやPostgreSQLなどのモノリシックアプリケーションは、復元力のためにZFSエンジン（cStor）を使用できます。 KafkaのようなストリーミングアプリケーションはNVMeエンジンを使用できます[Mayastor](https://github.com/openebs/Mayastor) エッジ環境で最高のパフォーマンスを実現します。 OpenEBSは、エンジンタイプ全体で、高可用性、スナップショット、クローン、および管理性のための一貫したフレームワークを提供します。

OpenEBS自体は、ホスト上の単なる別のコンテナーとしてデプロイされ、ポッド、アプリケーション、クラスター、またはコンテナーごとに指定できるストレージサービスを有効にします。これには次のものが含まれます。
-Kubernetesワーカーノードに接続されたストレージの管理を自動化し、そのストレージをOpenEBSPVまたはローカルPVの動的プロビジョニングに使用できるようにします。
-ノード間でのデータの永続性。たとえば、Cassandraリングの再構築にかかる時間を大幅に短縮します。
-可用性ゾーンとクラウドプロバイダー間でのデータの同期により、可用性が向上し、接続/切り離し時間が短縮されます。
-共通レイヤーなので、AKS、ベアメタル、GKE、AWSのいずれで実行していても、ストレージサービスの配線と開発者のエクスペリエンスは可能な限り似ています。
-S3およびその他のターゲットとの間の階層化の管理。

完全にKubernetesのネイティブソリューションであるという追加の利点は、管理者と開発者がkubectl、Helm、Prometheus、Grafana、WeaveScopeなどのKubernetesで利用できるすべてのすばらしいツールを使用してOpenEBSを操作および管理できることです。

**私たちのビジョン**はシンプルです。永続的なワークロードのストレージとストレージサービスを環境に完全に統合して、各チームとワークロードが制御の粒度とKubernetesのネイティブ動作の恩恵を受けるようにします。

##スケーラビリティ

OpenEBSは、任意の数のコンテナー化されたストレージコントローラーを含めるように拡張できます。 Kubernetesは、在庫にetcdを使用するなどの基本的な要素を提供するために使用されます。 OpenEBSは、Kubernetesがスケーリングする範囲でスケーリングします。

##インストールとはじめに

OpenEBSは、いくつかの簡単な手順でセットアップできます。 Kubernetesノードにopen-iscsiをインストールし、kubectlを使用してopenebs-operatorを実行することで、Kubernetesクラスターを選択できます。

**オペレーターを使用してOpenEBSサービスを開始します**
```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**ヘルムを使用してOpenEBSサービスを開始します**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

[クイックスタートガイド](https://docs.openebs.io/docs/overview.html)に従うこともできます

OpenEBSは、クラウド、オンプレミス、または開発者向けラップトップ（minikube）のいずれかで、任意のKubernetesクラスターにデプロイできます。 OpenEBSはユーザースペースで動作するため、基盤となるカーネルに必要な変更はないことに注意してください。私たちに従ってください[OpenEBS Setup](https://docs.openebs.io/docs/overview.html) ドキュメンテーション。また、OpenEBSのパフォーマンスをシミュレートするために使用できるサンプルのKubernetesデプロイメントと合成ロードを含むVagrant環境を利用できます。また、関連プロジェクトと呼ばれる興味深いものを見つけるかもしれません Litmus (https://litmuschaos.io) これは、Kubernetesのステートフルワークロードのカオスエンジニアリングに役立ちます。

＃＃ 状態

OpenEBSは、業界で最も広く使用され、テストされているKubernetesストレージインフラストラクチャの1つです。 2019年5月以来のCNCFサンドボックスプロジェクトであるOpenEBSは、オンプレミスシステムとクラウドシステムの両方で複数のバックエンド（ローカル、nfs、zfs、nvme）でソフトウェア定義のストレージ機能の一貫したセットを提供する最初で唯一のストレージシステムであり、ステートフルワークロード用の独自のカオスエンジニアリングフレームワークをオープンソース化した最初の[Litmus Project](https://litmuschaos.io), コミュニティは、OpenEBSバージョンの毎月のリズムを自動的に評価する準備ができていることに依存しています。企業のお客様は2018年から本番環境でOpenEBSを使用しており、プロジェクトは1週間に250万以上のDockerプルをサポートしています。

OpenEBS永続ボリュームに電力を供給するさまざまなストレージエンジンのステータスを以下に示します。ステータス間の主な違いは以下のとおりです。
-** alpha：** APIは、バグのリスクが高まり、長期的なサポートがないため、後のソフトウェアリリースで互換性のない方法で予告なしに変更される可能性があります。短期間のテストクラスターでのみ使用することをお勧めします。
-**ベータ**：詳細は変更される可能性がありますが、全体的な機能のサポートは削除されません。自動化または手動の手順で、バージョン間のアップグレードまたは移行のサポートが提供されます。
-**安定**：機能は後続の多くのバージョンのリリースされたソフトウェアに表示され、バージョン間のアップグレードのサポートは、ほとんどのシナリオでソフトウェアの自動化によって提供されます。

|ストレージエンジン|ステータス|詳細|
| --- | --- | --- |
| Jiva |安定| Kubernetesワーカーノードでエフェメラルストレージを利用するノードでレプリケートブロックストレージを実行するのに最適|
| cStor |ベータ版|ブロックデバイスがあるノードで実行するための推奨オプション。スナップショットとクローンが必要な場合の推奨オプション|
|ローカルボリューム|ベータ版|低レイテンシのストレージ（Kubernetesノードからの直接接続ストレージ）を必要とする分散アプリケーションに最適です。 |
|マヤスター|アルファ|ローカルストレージの効率で動作するだけでなく、レプリケーションなどのストレージサービスも提供する新しいストレージエンジン。スナップショットとクローンをサポートするための開発が進行中です。 |

詳細については、[OpenEBSドキュメント](https://docs.openebs.io/docs/next/quickstart.html)を参照してください。.

## |ストレージエンジン|ステータス|詳細|
| --- | --- | --- |
| Jiva |安定| Kubernetesワーカーノードでエフェメラルストレージを利用するノードでレプリケートブロックストレージを実行するのに最適|
| cStor |ベータ版|ブロックデバイスがあるノードで実行するための推奨オプション。スナップショットとクローンが必要な場合の推奨オプション|
|ローカルボリューム|ベータ版|低遅延ストレージ（Kubernetesノードからの直接接続ストレージ）を必要とする分散アプリケーションに最適です。 |
|マヤスター|アルファ|ローカルストレージの効率で動作するだけでなく、レプリケーションなどのストレージサービスも提供する新しいストレージエンジン。スナップショットとクローンをサポートするための開発が進行中です。 |

貢献

OpenEBSは、可能な限りあらゆる形式でフィードバックと貢献を歓迎します。

-[Kubernetes SlackのOpenEBSコミュニティに参加]（https://kubernetes.slack.com）
  -すでにサインアップしていますか？ [#openebs]（https://kubernetes.slack.com/messages/openebs/）でディスカッションに進んでください
-問題を提起したり、修正や機能を支援したいですか？
  -[未解決の問題]（https://github.com/openebs/openebs/issues）を参照してください
  -[寄稿ガイド]（./ CONTRIBUTING.md）を参照してください
  -寄稿者コミュニティミーティングに参加したい、[これをチェックしてください]（./ community / README.md）。
-OpenEBSCNCFメーリングリストに参加する
  -OpenEBSプロジェクトの更新については、[OpenEBS Announcements]（https://lists.cncf.io/g/cncf-openebs-announcements）を購読してください。
  -他のOpenEBSユーザーと対話するには、[OpenEBSユーザー]（https://lists.cncf.io/g/cncf-openebs-users）にサブスクライブします。

##コードを見せて

これはOpenEBSのメタリポジトリです。固定されたリポジトリまたは[OpenEBSアーキテクチャ]（./ contribute / design / README.md）ドキュメントから始めてください。

##ライセンス

OpenEBSは、プロジェクトレベルで[Apache License 2.0]（https://github.com/openebs/openebs/blob/master/LICENSE）ライセンスの下で開発されています。プロジェクトの一部のコンポーネントは、他のオープンソースプロジェクトから派生し、それぞれのライセンスの下で配布されます。

OpenEBSはCNCFプロジェクトの一部です。

[！[CNCFサンドボックスプロジェクト]（https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizo​​ntal/color/cncf-sandbox-horizo​​ntal-color.png）]（https：// landscape.cncf.io/selected=open-ebs）

##商用製品

これは、OpenEBSに関連する製品またはサービスを提供するサードパーティ企業および個人のリストです。 OpenEBSは、どの企業も推奨しないCNCFプロジェクトです。リストはアルファベット順に提供されています。
-[Clouds Sky GmbH]（https://cloudssky.com/en/）
-[CodeWave]（https://codewave.eu/）
-[Gridworkzクラウドサービス]（https://gridworkz.com/）
-[MayaData]（https://mayadata.io/）
