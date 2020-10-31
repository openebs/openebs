# Beitrag zu OpenEBS

Toll!! Wir sind immer auf der Suche nach weiteren OpenEBS-Hackern. Sie können beginnen, indem Sie diese [Übersicht] lesen (./ Contribution / Design / README.md).

Erstens, wenn Sie sich nicht sicher sind oder Angst vor irgendetwas haben, fragen oder senden Sie das Problem oder ziehen Sie die Anfrage trotzdem. Sie werden nicht angeschrien, wenn Sie Ihr Bestes geben. Das Schlimmste, was passieren kann, ist, dass Sie höflich gebeten werden, etwas zu ändern. Wir freuen uns über jede Art von Beiträgen und möchten nicht, dass eine Regelwand dem im Wege steht.

Lesen Sie jedoch weiter, wenn Sie mehr Anleitungen wünschen, wie Sie am besten zum Projekt beitragen können. Dieses Dokument behandelt alle Punkte, nach denen wir in Ihren Beiträgen suchen, und erhöht Ihre Chancen, Ihre Beiträge schnell zusammenzuführen oder zu adressieren.

OpenEBS ist jedoch eine Innovation in Open Source. Sie können gerne auf jede erdenkliche Weise einen Beitrag leisten, und jede Hilfe wird sehr geschätzt.

- [Probleme aufwerfen, um neue Funktionen anzufordern, Dokumentation zu reparieren oder Fehler zu melden.] (# Probleme aufwerfen)
- [Änderungen zur Verbesserung der Dokumentation einreichen.] (# Änderung zur Verbesserung der Dokumentation einreichen)
- [Vorschläge für neue Funktionen / Verbesserungen einreichen.] (# Vorschläge für neue Funktionen einreichen)
- [Bestehende Probleme im Zusammenhang mit Dokumentation oder Code lösen.] (# Beitrag zum Quellcode und zu Fehlerkorrekturen)

Es gibt einige einfache Richtlinien, die Sie befolgen müssen, bevor Sie Ihre Hacks bereitstellen.

## Probleme aufwerfen

Wenn Sie Probleme ansprechen, geben Sie bitte Folgendes an:

- Die Setup-Details müssen wie in der Problemvorlage angegeben klar angegeben werden, damit der Prüfer sie überprüfen kann.
- Ein Szenario, in dem das Problem aufgetreten ist (mit Details zur Reproduktion).
- Fehler und Protokollmeldungen, die von der Software angezeigt werden.
- Alle anderen Details, die nützlich sein könnten.

## Änderung zur Verbesserung der Dokumentation einreichen

Die richtige Dokumentation zu finden ist schwierig! Weitere Informationen dazu, wie Sie die Entwicklerdokumentation verbessern können, indem Sie Pull-Anforderungen mit entsprechenden Tags senden, finden Sie auf dieser [Seite] (./ Contribution / CONTRIBUTING-TO-DEVELOPER-DOC.md). Hier ist eine [Liste von Tags] (./ Contribution / Labels-of-issues.md), die für dasselbe verwendet werden könnte. Helfen Sie uns, unsere Dokumentation sauber, leicht verständlich und zugänglich zu halten.

## Vorschläge für neue Funktionen einreichen

Es ist immer etwas mehr erforderlich, um die Anpassung an Ihre Anwendungsfälle zu vereinfachen. Nehmen Sie an der Diskussion über neue Funktionen teil oder erheben Sie eine PR mit Ihrer vorgeschlagenen Änderung.

- [OpenEBS-Community auf Kubernetes Slack beitreten] (https://kubernetes.slack.com) - Bereits angemeldet? Besuchen Sie unsere Diskussionen unter [#openebs] (https://kubernetes.slack.com/messages/openebs/).

## Beitrag zum Quellcode und zu Fehlerkorrekturen

Stellen Sie PRs geeignete Tags für Fehlerbehebungen oder Verbesserungen des Quellcodes zur Verfügung. Eine Liste der Tags, die verwendet werden könnten, finden Sie unter [this] (./ Contribution / Labels-of-issues.md).

- Informationen zum Beitrag zur K8-Demo finden Sie in diesem [Dokument] (./ Contribution / CONTRIBUTING-TO-K8S-DEMO.md).
  - Informationen zur Funktionsweise von OpenEBS mit K8 finden Sie in diesem [Dokument] (./ k8s / README.md).

* Informationen zum Beitrag zu Kubernetes OpenEBS Provisioner finden Sie in diesem [Dokument] (./ Contribution / CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).

In diesem [Dokument] (./ Contribution / Design / Code-structuring.md) finden Sie weitere Informationen zur Codestrukturierung und Richtlinien, die Sie befolgen müssen.

## Bestehende Probleme lösen

Gehen Sie zu [Probleme] (https://github.com/openebs/openebs/issues), um Probleme zu finden, bei denen Hilfe von Mitwirkenden benötigt wird. Weitere Informationen zu Problemen, die Sie schneller lösen können, finden Sie in unserem Handbuch [Liste der Etiketten] (./ Contribution / Labels-of-issues.md).

Eine Person, die einen Beitrag leisten möchte, kann ein Problem aufgreifen, indem sie es als Kommentar beansprucht / ihr ihre GitHub-ID zuweist. Falls eine Woche lang keine PR oder Aktualisierung zu diesem Thema durchgeführt wird, wird das Problem erneut geöffnet, damit jeder es erneut aufgreifen kann. Wir müssen Probleme / Regressionen mit hoher Priorität berücksichtigen, bei denen die Antwortzeit etwa einen Tag betragen muss.

--- ---.

### Unterschreibe deine Arbeit

Wir verwenden das Developer Certificate of Origin (DCO) als zusätzlichen Schutz für das OpenEBS-Projekt. Dies ist ein gut etablierter und weit verbreiteter Mechanismus, um sicherzustellen, dass die Mitwirkenden ihr Recht bestätigt haben, ihren Beitrag unter der Projektlizenz zu lizenzieren. Bitte lesen Sie [Entwickler-Ursprungszeugnis] (./ Contrib / Entwickler-Ursprungszeugnis).

Wenn Sie es zertifizieren können, fügen Sie einfach jeder Git-Commit-Nachricht eine Zeile hinzu:

`` `
  Abgemeldet von: Random J Developer <random@developer.example.org>
`` `

Oder verwenden Sie den Befehl "git commit -s -m" Commit-Nachricht kommt hierher ", um sich von Ihren Commits abzumelden.

Verwenden Sie Ihren richtigen Namen (leider keine Pseudonyme oder anonymen Beiträge). Wenn Sie Ihre Git-Konfigurationen "user.name" und "user.email" festlegen, können Sie Ihr Commit automatisch mit "git commit -s" signieren. Sie können auch git [Aliase] (https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) wie "git config --global alias.ci" commit -s "verwenden. Jetzt können Sie mit `git ci` festschreiben und das Festschreiben wird signiert.

---

## Tritt unserer Gemeinschaft bei

Informationen zur aktiven Entwicklung und zum Beitrag zur OpenEBS-Community finden Sie in diesem [Dokument] (./ community / README.md).
