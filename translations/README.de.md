# OpenEBS

[![Build Status](https://img.shields.io/travis/openebs/openebs/master.svg?style=flat-square)](https://travis-ci.org/openebs/jiva)
[![Docker Pulls](https://img.shields.io/docker/pulls/openebs/jiva.svg?style=flat-square)](https://hub.docker.com/r/openebs/jiva/)
[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack](https://img.shields.io/badge/chat!!!-slack-ff1493.svg?style=flat-square)]( https://openebsslacksignup.herokuapp.com/)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/openebs/openebs/blob/master/LICENSE)

https://www.openebs.io/

**OpenEBS** ermöglicht die Verwendung von Containern für geschäftskritische, persistente Workloads und für andere Stateful-Workloads, z. B. Protokollierung oder Prometheus. OpenEBS sind Container- und verwandte Speicherdienste.
 
**OpenEBS** ermöglicht es Ihnen, persistente Workload-Container wie DBs auf Containern wie andere Container zu behandeln. OpenEBS selbst wird nur als weiterer Container auf Ihrem Host bereitgestellt und ermöglicht Speicherdienste, die auf Pod-, Anwendungs-, Cluster- oder Containerebene festgelegt werden können. Dazu gehören:
- Datenpersistenz über Knoten hinweg, wodurch beispielsweise der Zeitaufwand für den Neuaufbau von Cassandra-Ringen drastisch reduziert wird.
- Synchronisierung von Daten zwischen Verfügbarkeitszonen und Cloud-Anbietern, um beispielsweise die Verfügbarkeit zu verbessern und die Verbindungszeiten zu verkürzen.
- Eine gemeinsame Ebene, also unabhängig davon, ob Sie AKS, Bare Metal oder GKE oder AWS verwenden - Ihre Verdrahtungs- und Entwicklererfahrung für Speicherdienste ist so ähnlich wie möglich.
- Integration mit Kubernetes, so dass Entwickler- und Anwendungsabsichten automatisch in OpenEBS-Konfigurationen einfließen.
- Management des Tiering zu und von S3 und anderen Zielen.

**Unsere Vision** ist einfach: Lassen Sie die Speicher- und Speicherdienste für persistente Workloads vollständig in die Umgebung integrieren, sodass jedes Team und jeder Workload von der Granularität der Steuerung und dem nativen Verhalten von Kubernetes profitiert.
x
#### *Lies dies in [anderen Sprachen](translations/TRANSLATIONS.md).*

[🇩🇪](README.de.md)
[:uk:](../README.MD)
[🇷🇺](README.ru.md)
[🇹🇷](README.tr.md)

## Skalierbarkeit
 
OpenEBS kann skaliert werden, um eine beliebig große Anzahl von Container-Speichercontrollern aufzunehmen. Kubernetes wird verwendet, um grundlegende Elemente wie die Verwendung von etcd für das Inventar bereitzustellen. OpenEBS skaliert in dem Umfang, in dem sich Ihre Kubernetes-Skalen befinden.

## Installation und Erste Schritte
 
OpenEBS kann in wenigen einfachen Schritten eingerichtet werden. Sie können Ihre Wahl des Kubernetes-Clusters wählen, indem Sie open-iscsi auf den Kubernetes-Knoten installieren und den Openebs-Operator mit kubectl ausführen.

**Starten Sie die OpenEBS Services mit dem Operator**
```bash
# dieses yaml anwenden
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Anwenden von OpenEBS StorageClasses**
```bash
# dieses yaml anwenden
kubectl gelten -f https://openebs.github.io/charts/openebs-storageclasses.yaml
```

Sie können auch unserem [QuickStart Guide](https://docs.openebs.io/docs/overview.html) folgen.

OpenEBS kann auf jedem Kubernetes-Cluster bereitgestellt werden - entweder in der Cloud, vor Ort oder auf dem Entwickler-Laptop (Minikube). Beachten Sie, dass der zugrunde liegende Kernel nicht geändert wird, da OpenEBS im Benutzerbereich ausgeführt wird. Bitte befolgen Sie unsere Dokumentation [OpenEBS-Setup](https://docs.openebs.io/docs/overview.html). Außerdem steht eine Vagrant-Umgebung zur Verfügung, die ein Beispiel für die Bereitstellung von Kubernetes und eine synthetische Last enthält, mit der Sie die Leistung von OpenEBS simulieren können. Interessant ist möglicherweise auch das verwandte Projekt namens [Litmus](https://www.openebs.io/litmus), das beim Chaos-Engineering für Stateful Workloads auf Kubernetes hilft.

## Status
Wir nähern uns der Beta-Phase mit aktiver Entwicklung. Weitere Informationen finden Sie in unserem [Project Tracker](https://github.com/openebs/openebs/wiki/Project-Tracker). Viele Anwender betreiben OpenEBS in der Produktion. Im September 2018 wurden kommerzielle Lösungen für den frühen Zugriff von unserem Hauptsponsor [MayaData](https://www.mayadata.io) zur Verfügung gestellt.
 
## Mitmachen
 
OpenEBS freut sich über Ihr Feedback und Ihre Beiträge in jeder möglichen Form.
 
- Besuchen Sie uns unter [Slack](https://openebsslacksignup.herokuapp.com/)
  - Bereits angemeldet? Besuchen Sie unsere Diskussionen unter [#openebs-users](https://openebs-community.slack.com/messages/openebs-users/).
- Möchten Sie ein Problem ansprechen?
  - Wenn es sich um ein generisches Produkt (oder "nicht wirklich sicher") handelt, können Sie es dennoch unter [issues](https://github.com/openebs/openebs/issues) anheben.
  - Projekt (Repository) spezifische Probleme können auch unter [issues](https://github.com/openebs/openebs/issues) angesprochen und mit den einzelnen Repository-Labels wie *repo/maya* versehen werden.
- Möchten Sie mit Fixes und Features helfen?
  - Siehe [offene Ausgaben](https://github.com/openebs/openebs/labels)
- Siehe [Beitragender Leitfaden](./CONTRIBUTING.md)
  - Möchten Sie unserer Community beitreten, [check this out](./community/README.md).

## Zeig mir den Code

Dies ist ein Meta-Repository für OpenEBS. Der Quellcode ist an folgenden Orten verfügbar:
- Der Quellcode für die erste Speicher-Engine befindet sich unter [openebs/jiva](https://github.com/openebs/jiva).
- Der Quellcode der Storage Orchestration befindet sich unter [openebs/maya](https://github.com/openebs/maya).
- Während *jiva* und *maya* bedeutende Teile des Quellcodes enthalten, wird ein Teil des Orchestrierungs- und Automatisierungscodes auch in anderen Repositorys der OpenEBS-Organisation verteilt.

Beginnen Sie mit den angehefteten Repositorys oder mit dem Dokument [OpenEBS Architecture](./contrib/design/README.md).

## Lizenz

OpenEBS wird auf Projektebene unter Apache 2.0-Lizenz entwickelt.
Einige Komponenten des Projekts stammen aus anderen Open Source-Projekten und werden unter ihren jeweiligen Lizenzen vertrieben.
