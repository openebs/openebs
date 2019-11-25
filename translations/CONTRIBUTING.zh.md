# 参与 OpenEBS 贡献

太棒了! !我们一直在寻找更多的 OpenEBS 黑客。您可以从阅读这篇文章开始：[概述](./../contribute/design/README.md)

首先，如果您不确定或有任何顾虑，可直接询问或提交问题或 PR。只要您尽力而为，没有人会责备您。最多是您会被礼貌地要求做一些更改。我们感谢任何形式的贡献，不希望有一堵墙一样的规则从中阻碍。

然而，如果想要获得更多关于如何为项目做出贡献的指导，请继续阅读。本文档将涵盖我们在您的贡献中所须知的所有关键点，有助于您快速合并或处理您的贡献。

从某种意义上说，OpenEBS 是开源的一个创新。欢迎您以任何方式贡献您的力量，我们非常感谢您提供的所有帮助。

- [提出新的问题来请求新功能、修复文档或报告错误。](#提交问题)
- [提交变更来改善文档。](#提交变更来改善文档n) 
- [提交关于新特性或改善性的提议](#提交新特性提议)
- [解决有关于代码或者文档存在的问题。](#贡献代码和问题修复)

在提供这些技巧之前，您需要遵循一些简单的指导原则。

## 提交问题

当您提交新的问题(issue)时，请列明下列事项:
- 配置细节需要按照问题模板中明确指定的方式填写，以便审核人员检查。
- 发生问题的场景(包含如何复现问题的详细信息)。
- 软件显示的错误和日志消息。
- 任何其他可能有用的细节。

## 提交变更来改善文档

让文档始终保持准确无误是不现实的。请参考这个[页面](./../contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) 以了解更多关于如何通过提交带有适当标记的 PR 来改进开发文档的信息。这里有一个 [标签列表](./../contribute/labels-of-issues.md)，可以用于同样的问题。请保持文档的简洁、易于理解和访问。

## 提交新特性提议

为了适应不同的使用场景，新需求总是源源不断。您可以自由地加入关于新特性的讨论，或者提交您所提议特性的 PR。

- [加入我们的社区](https://openebs.org/community)
      - 已经注册? 前往我们的讨论组 [#openebs-users](https://openebs-community.slack.com/messages/openebs-users/)

## 贡献代码和问题修复

请在问题修复或代码改善的 PR 上添加合适的标签。可用的标签列表请参见[这里](./../contribute/labels-of-issues.md)。
    
* 关于贡献 K8s demo，请参考这个[文档](./../contribute/CONTRIBUTING-TO-K8S-DEMO.md)。
    - 要了解 OpenEBS 如何与 K8s 结合，请参考这个[文档](./../k8s/README.md)
- 关于参与贡献 Kubernetes OpenEBS Provisioner，请参考这个[文档](./../contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md)。

关于代码结构和指南的更多信息，请参考这个 [文档](./../contribute/design/code-structuring.md) 

## 解决已知问题

点击 [issues](https://github.com/openebs/openebs/issues)，找到那些等待贡献者帮助的问题。请参阅我们的 [标签列表指南](./../contribute/labels-of-issues.md)，以帮助您可以更快找到能够解决的问题。

想要参与贡献的人可以通过将其声明为评论/指派他们的 GitHub ID 来处理问题。如果在一周内没有任何关于该问题的进展更新，那么该问题将重新开放，让任何人重新开始。我们优先考虑高优先级的问题/回归，其中响应时间必须是一天左右。

---

### 为您的劳动成果签名

我们使用原始开发者认证 (DCO) 作为 OpenEBS 项目的额外保护。这是一个优质且广泛应用的机制，用于确保贡献者已经确认了他们在项目许可下对其贡献进行许可的权利。请阅读 [developer-certificate-of-origin](./../contribute/developer-certificate-of-origin)。

如果您可以验证它，那么只需在每条 git 提交信息中添加一行代码:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
````

或者使用这条命令来为您的提交签名: `git commit -s -m "commit message comes here"`

请使用您的真实姓名，(抱歉我们不支持任何化名或匿名贡献)。如果您在 git config 中设置了您的 `user.name` 和 `user.email` ，您可以通过 `git commit -s` 来为您的提交自动签名。您还可以使用 git [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) , 例如 `git config --global alias.ci 'commit -s'` ，然后您就可以使用 `git ci` 来提交并且提交会被签名。

---

## 加入我们的社区

想积极开发并为 OpenEBS 社区做出贡献，请参考这个[文档](./../community/README.md)。