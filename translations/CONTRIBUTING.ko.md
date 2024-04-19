# OpenEBS에 기여하기

반갑습니다!! 우리는 항상 더 많은 OpenEBS 해커를 찾고 있습니다. 이 [개요](./contribute/design/README.md)를 읽고 시작할 수 있습니다.

첫째, 확신이 없거나 두려운 점이 있다면, 일단 이슈나 Pull request를 제출하세요. 당신의 노력은 비난받지 않을것이며, 최악의 상황은 그저 정중하게 뭔가를 바꿔달라는 요청을 받는 것입니다. 우리는 어떤 종류의 기여에도 감사하며 규칙의 장벽이 이를 방해하는것을 원치 않습니다.

그러나 프로젝트에 기여할 수 있는 최선의 방법에 대해 좀 더 자세한 안내를 원하는 독자는 계속 읽어보세요. 이 문서는 귀하의 기여에서 우리가 찾고 있는 모든 사항을 다루므로 귀하의 기여를 신속하게 병합하거나 해결할 가능성이 높아집니다.

OpenEBS는 오픈 소스의 혁신입니다. 어떤 방식으로든 기여하실 수 있으며 제공된 모든 도움에 진심으로 감사드립니다.

- [새로운 기능을 요청하거나, 문서를 수정하거나, 버그를 보고하기 위해 문제를 제기하세요.](#raising-issues)
- [문서를 개선하려면 변경 사항을 제출하세요.](#submit-change-to-improve-documentation)
- [새로운 기능/개선 사항에 대한 제안을 제출하세요.](#submit-proposals-for-new-features)
- [문서 또는 코드와 관련된 기존 문제를 해결합니다.](#contributing-to-source-code-and-bug-fixes)

해킹을 제공하기 전에 따라야 할 몇 가지 간단한 지침이 있습니다.

## 이슈 제기

문제를 제기할 때는 다음 사항을 명시해 주세요:

- 설정 세부사항은 이슈 템플릿에 명시된 대로 검토자가 확인할 수 있도록 명확하게 작성되어야 합니다.
- 문제가 발생한 시나리오(재현 방법에 대한 세부정보 포함)
- 소프트웨어에 의해 표시되는 오류 및 로그 메시지.
- 유용할 수 있는 기타 세부정보.

## 문서 개선을 위해 변경 사항 제출

문서를 올바르게 작성하는 것은 어렵습니다! 적절한 태그가 포함된 풀 요청을 제출하여 개발자 문서를 개선할 수 있는 방법에 대한 자세한 내용은 이 [페이지](./contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md)를 참조하세요. 여기에 사용할 수 있는 [태그 목록](./contribute/labels-of-issues.md)이 있습니다. 문서를 깔끔하고, 이해하기 쉽고, 접근하기 쉽게 유지할 수 있도록 도와주세요.

## 새로운 기능에 대한 제안서 제출

사용 사례에 더 쉽게 적용하려면 항상 더 필요한 것이 있습니다. 새로운 기능에 대한 토론에 자유롭게 참여하거나 제안된 변경 사항에 대해 PR을 올려보세요.

- [Kubernetes Slack에서 OpenEBS 커뮤니티 참여하기](https://kubernetes.slack.com) - Already signed up? Head to our discussions at [#openebs](https://kubernetes.slack.com/messages/openebs/)

## 소스 코드 및 버그 수정에 기여

버그 수정이나 소스 코드 개선을 위한 적절한 태그를 PR에 제공하세요. 사용할 수 있는 태그 목록은 [이](./contribute/labels-of-issues.md)를 참조하세요.

- K8s 데모에 기여하려면 이 [문서](./contribute/CONTRIBUTING-TO-K8S-DEMO.md)를 참조하세요.
  - K8s에서 OpenEBS가 어떻게 작동하는지 확인하려면 이 [문서](https://openebs.io/docs)를 참조하세요.

* Kubernetes OpenEBS Provisioner에 기여하려면 이 [문서](./contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md)를 참조하세요.

코드 구조화 및 그에 따른 지침에 대한 자세한 내용은 이 [문서](./contribute/design/code-structuring.md)를 참조하세요.

## 기존 문제 해결

기여자의 도움이 필요한 문제를 찾으려면 [문제](https://github.com/openebs/openebs/issues)로 이동하세요. 더 빠르게 해결할 수 있는 문제를 찾는 데 도움이 되는 [라벨 목록 가이드](./contribute/labels-of-issues.md)를 참조하세요.

기여하려는 사람은 문제를 댓글로 요청하거나 GitHub ID를 할당하여 문제를 다룰 수 있습니다. 해당 문제에 대해 일주일 동안 진행 중인 PR이나 업데이트가 없는 경우 누구나 다시 다룰 수 있도록 문제가 다시 열립니다. 응답 시간이 하루 정도 되어야 하는 우선순위가 높은 문제/회귀를 고려해야 합니다.

---

### 작업에 서명하기

우리는 OpenEBS 프로젝트에 대한 추가 보호 장치로 DCO(개발자 원산지 인증서)를 사용합니다. 이는 기여자가 프로젝트 라이선스에 따라 자신의 기여에 대한 라이선스를 부여할 권리가 있음을 확인하기 위해 잘 확립되고 널리 사용되는 메커니즘입니다. [개발자-원산지 인증서](./contribute/developer-certificate-of-origin)를 읽어보세요.

모든 git 커밋 메시지에 한 줄을 추가하여 인증하세요. DCO 사인오프가 없는 커밋이 포함된 PR은 허용되지 않습니다:

```
  Signed-off-by: Random J Developer <random@developer.example.org>
```

or 또는 `git commit -s -m "커밋 메시지 입력"` 명령어를 사용하여 커밋에 서명을 포함하세요.

실명을 사용하세요(죄송합니다. 가명이나 익명 기여는 허용되지 않습니다). `user.name` 및 `user.email` git 구성을 설정하면 `git commit -s`를 사용하여 커밋에 자동으로 서명할 수 있습니다. `git config --global alias.ci 'commit -s'`와 같은 git [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases)을 사용할 수도 있습니다. 이제 `git ci`로 커밋할 수 있으며 커밋이 서명됩니다.

---

## 커뮤니티에 가입하기

OpenEBS 커뮤니티를 적극적으로 개발하고 기여하고 싶다면 이 [문서](./community/README.md)를 참조하세요.
