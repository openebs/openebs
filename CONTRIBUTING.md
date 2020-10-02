# Contributing to OpenEBS
Toll!! Wir sind immer auf der Suche nach weiteren OpenEBS-Hackern. Sie können beginnen, indem Sie dies lesen [Überblick](./contribute/design/README.md)

Erstens, wenn Sie sich nicht sicher sind oder Angst vor irgendetwas haben, fragen oder senden Sie das Problem oder ziehen Sie die Anfrage trotzdem. Sie werden nicht angeschrien, wenn Sie Ihr Bestes geben. Das Schlimmste, was passieren kann, ist, dass Sie höflich gebeten werden, etwas zu ändern. Wir freuen uns über jede Art von Beiträgen und möchten nicht, dass eine Regelwand dem im Wege steht.

Lesen Sie jedoch weiter, wenn Sie mehr Anleitungen wünschen, wie Sie am besten zum Projekt beitragen können. Dieses Dokument behandelt alle Punkte, nach denen wir in Ihren Beiträgen suchen, und erhöht Ihre Chancen, Ihre Beiträge schnell zusammenzuführen oder zu adressieren.

OpenEBS ist jedoch eine Innovation in Open Source. Sie können gerne auf jede erdenkliche Weise einen Beitrag leisten, und jede Hilfe wird sehr geschätzt.

- [Probleme aufwerfen, um neue Funktionen anzufordern, Dokumentation zu reparieren oder Fehler zu melden.](#raising-issues)
- [Senden Sie Änderungen, um die Dokumentation zu verbessern.](#submit-change-to-improve-documentation) 
- [Reichen Sie Vorschläge für neue Funktionen / Verbesserungen ein.](#submit-proposals-for-new-features)
- [Lösen Sie vorhandene Probleme im Zusammenhang mit Dokumentation oder Code.](#contributing-to-source-code-and-bug-fixes)

Es gibt einige einfache Richtlinien, die Sie befolgen müssen, bevor Sie Ihre Hacks bereitstellen.

## Probleme aufwerfen

Wenn Sie Probleme ansprechen, geben Sie bitte Folgendes an:
- Die Setup-Details müssen wie in der Problemvorlage angegeben klar angegeben werden, damit der Prüfer sie überprüfen kann.
- Ein Szenario, in dem das Problem aufgetreten ist (mit Details zur Reproduktion).
- Fehler und Protokollmeldungen, die von der Software angezeigt werden.
- Alle anderen Details, die nützlich sein könnten.

## Senden Sie die Änderung, um die Dokumentation zu verbessern

Die richtige Dokumentation zu finden ist schwierig! Siehe diese [Seite](./contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) Weitere Informationen dazu, wie Sie die Entwicklerdokumentation verbessern können, indem Sie Pull-Anforderungen mit entsprechenden Tags senden. Hier ist eine [Liste der Tags](./contribute/labels-of-issues.md) das könnte für das gleiche verwendet werden. Helfen Sie uns, unsere Dokumentation sauber, leicht verständlich und zugänglich zu halten.
## Submit Proposals for New Features

Es ist immer etwas mehr erforderlich, um die Anpassung an Ihre Anwendungsfälle zu vereinfachen. Nehmen Sie an der Diskussion über neue Funktionen teil oder erheben Sie eine PR mit Ihrer vorgeschlagenen Änderung. 

- [Treten Sie der OpenEBS-Community auf Kubernetes Slack bei](https://kubernetes.slack.com)
	- Schon angemeldet? Besuchen Sie unsere Diskussionen unter [#openebs](https://kubernetes.slack.com/messages/openebs/)

## Beitrag zum Quellcode und zu Fehlerkorrekturen

Stellen Sie PRs geeignete Tags für Fehlerbehebungen oder Verbesserungen des Quellcodes zur Verfügung. Eine Liste der Tags, die verwendet werden könnten, finden Sie unter[dies](./contribute/labels-of-issues.md).

* Informationen zum Beitrag zur K8-Demo finden Sie hier [document](./contribute/CONTRIBUTING-TO-K8S-DEMO.md).
    - Informationen dazu, wie OpenEBS mit K8s funktioniert, finden Sie hier [dokument](./k8s/README.md) 
- Informationen zum Beitrag zu Kubernetes OpenEBS Provisioner finden Sie hier [dokument](./contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).
    
Beziehen Sie sich darauf [dokument](./contribute/design/code-structuring.md) weitere Informationen zur Codestrukturierung und Richtlinien finden Sie hier.

## Bestehende Probleme lösen
Gehe rüber zu [Probleme](https://github.com/openebs/openebs/issues) um Probleme zu finden, bei denen Hilfe von Mitwirkenden benötigt wird. Siehe unsere [Liste der Etiketten](./contribute/labels-of-issues.md) um Ihnen zu helfen, Probleme zu finden, die Sie schneller lösen können.

Eine Person, die einen Beitrag leisten möchte, kann ein Problem aufgreifen, indem sie es als Kommentar beansprucht / ihr ihre GitHub-ID zuweist. Falls eine Woche lang keine PR oder Aktualisierung zu diesem Thema durchgeführt wird, wird das Problem erneut geöffnet, damit jeder es erneut aufgreifen kann. Wir müssen Probleme / Regressionen mit hoher Priorität berücksichtigen, bei denen die Antwortzeit etwa einen Tag betragen muss.

---
### Unterschreiben Sie Ihre Arbeit

Wir verwenden das Developer Certificate of Origin (DCO) als zusätzlichen Schutz für das OpenEBS-Projekt. Dies ist ein gut etablierter und weit verbreiteter Mechanismus, um sicherzustellen, dass die Mitwirkenden ihr Recht bestätigt haben, ihren Beitrag unter der Projektlizenz zu lizenzieren. Bitte lesen Sie [developer-certificate-of-origin](./contribute/developer-certificate-of-origin).

Wenn Sie es zertifizieren können, fügen Sie einfach jeder Git-Commit-Nachricht eine Zeile hinzu:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
````
oder verwenden Sie den Befehl `git commit -s -m "commit message comes here"` um Ihre Commits abzumelden.

Verwenden Sie Ihren richtigen Namen (leider keine Pseudonyme oder anonymen Beiträge). Wenn Sie Ihre einstellen `user.name` und `user.email` git configs können Sie Ihr Commit automatisch mit signieren `git commit -s`. Sie können auch git verwenden [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) mögen `git config --global alias.ci 'commit -s'`. Jetzt können Sie mit festlegen `git ci` und das Commit wird unterschrieben.
---

## Tritt unserer Gemeinschaft bei

Wenn Sie sich aktiv entwickeln und zur OpenEBS-Community beitragen möchten, lesen Sie dies [dokument](./community/README.md).
