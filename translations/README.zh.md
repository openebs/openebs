# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack](https://img.shields.io/badge/chat!!!-slack-ff1493.svg?style=flat-square)]( https://openebs-community.slack.com)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.zh.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.org/
 
**OpenEBS** 是 Kubernetes 部署使用最广泛且易用的开源存储解决方案。

作为业界领先的开源存储解决方案，**OpenEBS** 通常又以其名 [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/) （基于容器的块存储）而被广泛熟知。同时 **OpenEBS** 作为一个开源范例列入 [CNCF 存储全景白皮书](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) 的超融合存储解决方案中。

OpenEBS 与其他传统存储解决方案的一些关键区别如下:
- 遵循与其所服务的应用程序类似的微服务架构。OpenEBS 本身作为一组容器部署在 Kubernetes 工作节点上。使用 Kubernetes 自身的能力来编排管理 OpenEBS 组件。
- 完全构建于用户空间，以其高度可移植性可运行在任何操作系统/平台下。
- 完全的意图驱动模型，继承了与 Kubernetes 相同的驱动易用性原则。
- OpenEBS 支持一系列存储引擎，以便开发人员能够部署适合其应用程序设计目标的存储技术。像 Cassandra 这样的分布式应用程序可以使用 LocalPV 引擎实现最低延迟的写操作。像 MySQL 和 PostgreSQL 这样的独立应用程序可以使用 ZFS 引擎 (cStor) 进行恢复。像 Kafka 这样的流媒体应用程序可以使用 NVMe 引擎 [MayaStor](https://github.com/openebs/MayaStor) 在边缘环境中获得最佳性能。在各种引擎类型中，OpenEBS 为高可用性、快照、克隆和易管理性提供了一致的框架。

OpenEBS 本身被部署为主机上的另一个容器，支持在每个pod、应用程序、集群或容器级别上指定存储服务，包括:
- 将附加到 Kubernetes 工作节点的存储管理自动化，并能够将存储用于动态提供 OpenEBS pv 或本地 pv。
- 跨节点的数据持久化，极大地减少了用于重新构建 Cassandra rings 的时间。
- 跨可用区和云厂商的数据同步可以提高可用性并减少 attach/detach 时间。
- 作为一个通用层，无论是运行在 AKS，还是裸金属、GKE、AWS 等等， 您的部署和开发人员的存储服务体验是尽可能相似的。
- 管理与 S3 和其他目标之间的分层。

作为一个 Kubernetes 纯原生解决方案的一个额外优势是，管理员和开发人员可以使用 Kubernetes 提供的所有工具 (如 kubectl、Helm、Prometheus、Grafana、Weave Scope 等) 来交互和管理 OpenEBS。

**我们的愿景**很简单: 让持久化工作负载的存储和存储服务完全集成到环境中，这样每个团队和工作负载都可以从控制的粒度和 Kubernetes 原生行为中获益。

#### *阅读关于这个文档的 [其他语言版本](translations/TRANSLATIONS.md)。*

[🇩🇪](translations/README.de.md)
[🇷🇺](translations/README.ru.md)
[🇹🇷](translations/README.tr.md)
[🇺🇦](translations/README.ua.md)

## 可扩展性
 
OpenEBS 可以扩展到包含任意数量的容器化存储控制器。Kubernetes 用于提供基本的组件，例如使用 etcd 作为 inventory。OpenEBS 遵照你的 Kubernetes 的级别进行扩展。

## 安装以及使用

配置 OpenEBS 只需几个简单的步骤。首先在 Kubernetes 节点上安装 open-iscsi 并使用 kubectl 运行 openebs-operator。

**通过 operator 启动 OpenEBS 服务**
```bash
# 应用这个 yaml 文件
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**通过 helm 启动 OpenEBS 服务**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

同样可以参考我们的 [快速上手指南](https://docs.openebs.io/docs/overview.html)。

OpenEBS 可以部署在任何 Kubernetes 集群上，可以部署在公有云、私有云或开发人员的笔记本电脑 (minikube) 上。请注意，由于OpenEBS 是在用户空间中操作的，所以不需要对底层内核进行任何更改。请遵循我们的 [OpenEBS设置](https://docs.openebs.io/docs/overview.html) 文档。另外，我们有一个 Vagrant 环境，其中包括一个 Kubernetes 部署示例和一个模拟 OpenEBS 性能的综合负载。或许您还会发现一个有趣的相关项目，称为 [Litmus](https://www.openebs.io/litmus)，协助 Kubernetes 上有状态工作负载的混沌工程。

## 项目状态

OpenEBS 是业界最广泛使用和测试的 Kubernetes 存储基础设施之一。OpenEBS 作为一个 CNCF Sanbox 项目自 2019 年 5 月以来,  是第一个也是唯一一个能够同时在公有云和私有云的多种后端 (local, nfs, zfs, nvme) 上提供一套一致性的软件定义存储功能的存储系统，并且首次开源了其自身用于有状态工作负载的混沌工程框架--[Litmus Project](https://www.openebs.io/litmus)，一个社区赖以自动就绪评估月度版本节奏的项目。企业客户从 2018 年开始在生产中使用 OpenEBS，该项目支撑每周 250万+ docker 拉取。

下面列出了支持 OpenEBS 持久卷的各种存储引擎的开发状态。

| 存储引擎 | 状态 | 详情 |
|---|---|---|
| Jiva | stable | 最适合在使用临时存储的 Kubernetes 工作节点上运行 Replicated Block Storage |
| cStor | beta | 在具有块设备的节点上的首选。如果需要快照和克隆，建议使用此选项 |
| Local Volumes | beta | Best suited for Distributed Application that need low latency storage - direct-attached storage from the Kubernetes nodes. Kubernetes 节点上的本地存储-最适合需要低延迟存储的分布式应用程序。|
| MayaStor | alpha | 一种全新的存储引擎，比肩本地存储的工作效率，同时也提供复制等存储服务。快照和克隆的功能支持正在开发中。|

更多详情请参阅 [OpenEBS 文档](https://docs.openebs.io/docs/next/quickstart.html).
 
## 参与贡献
 
OpenEBS 欢迎任何形式的反馈和贡献。
 
- [加入我们的社区](https://openebs.org/community)
  - 已经注册? 前往我们的讨论组 [#openebs-users](https://openebs-community.slack.com/messages/openebs-users/)
- 希望反馈问题或参与修复或者贡献特性?
  - 查看 [开放中的问题](https://github.com/openebs/openebs/issues)
  - 查看 [参与贡献说明](./CONTRIBUTING.zh.md)
  - 想加入我们的社区开发者会议, [点击这里](./community/README.md). 
- 加入我们的 OpenEBS CNCF 邮件列表
  - 关注 OpenEBS 项目更新动态，订阅 [OpenEBS 公告](https://lists.cncf.io/g/cncf-openebs-announcements)
  - 与其他 OpenEBS 用户交流, 订阅 [OpenEBS 用户](https://lists.cncf.io/g/cncf-openebs-users)

## 秀出你的代码

这个是 OpenEBS 的元仓库。 请首先从已置顶的仓库开始。或者查看 [OpenEBS 架构](./contribute/design/README.md) 文档。 

## 协议

OpenEBS 项目遵循 [Apache License 2.0](https://github.com/openebs/openebs/blob/master/LICENSE) 协议。项目的一些组件来自其他开源项目，并在各自的许可下发布。

OpenEBS 是 CNCF 项目的一部分。

[![CNCF Sandbox Project](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)](https://landscape.cncf.io/selected=open-ebs)

## 商业服务

这是列出了与 OpenEBS 相关的产品或服务的第三方公司和个人的列表。OpenEBS 本身是一个独立于任何商业公司的 CNCF 项目。名单按字母顺序排列。
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [Gridworkz Cloud Services](https://gridworkz.com/)
- [MayaData](https://mayadata.io/)