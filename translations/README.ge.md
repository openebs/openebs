# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**OpenEBS** ist die am weitesten verbreitete und benutzerfreundlichste Open-Source-Speicherlösung für Kubernetes.

**OpenEBS** ist das führende Open-Source-Beispiel für eine Kategorie von Speicherlösungen, die manchmal als [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/) bezeichnet werden. **OpenEBS** wird als Open-Source-Beispiel im [CNCF Storage Landscape White Paper](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) unter den hyperkonvergenten Speicherlösungen aufgeführt.
Einige wichtige Aspekte, die OpenEBS von anderen herkömmlichen Speicherlösungen unterscheiden:
- Erstellt unter Verwendung der Mikrodienstarchitektur wie der Anwendungen, die sie bedient. OpenEBS wird selbst als eine Reihe von Containern auf Kubernetes-Worker-Knoten bereitgestellt. Verwendet Kubernetes selbst, um OpenEBS-Komponenten zu orchestrieren und zu verwalten
- Vollständig im Benutzerbereich integriert, sodass es sehr portabel ist und auf jedem Betriebssystem / jeder Plattform ausgeführt werden kann
- Vollständig absichtsorientiert und erbt dieselben Prinzipien, die die Benutzerfreundlichkeit von Kubernetes fördern
- OpenEBS unterstützt eine Reihe von Speicher-Engines, sodass Entwickler die Speichertechnologie bereitstellen können, die ihren Anwendungsdesignzielen entspricht. 
Verteilte Anwendungen wie Cassandra können die LocalPV-Engine für Schreibvorgänge mit der geringsten Latenz verwenden. Monolithische Anwendungen wie MySQL und 
PostgreSQL können die ZFS-Engine (cStor) für die Ausfallsicherheit verwenden. Streaming-Anwendungen wie Kafka können die NVMe-Engine [Mayastor] (https://github.com/openebs/Mayastor) 
verwenden, um die beste Leistung in Edge-Umgebungen zu erzielen. OpenEBS bietet über alle Motortypen hinweg ein konsistentes Framework für Hochverfügbarkeit, Snapshots, Klone und Verwaltbarkeit.

**OpenEBS** selbst wird als nur ein weiterer Container auf Ihrem Host bereitgestellt und ermöglicht Speicherdienste, die auf Pod-, Anwendungs-, Cluster- oder Containerebene festgelegt werden können, einschließlich:
- Automatisieren Sie die Verwaltung des an die Kubernetes-Worker-Knoten angeschlossenen Speichers und ermöglichen Sie die Verwendung des Speichers für die dynamische Bereitstellung von OpenEBS-PVs oder lokalen PVs.
- Datenpersistenz über Knoten hinweg, wodurch beispielsweise der Zeitaufwand für die Wiederherstellung von Cassandra-Ringen drastisch reduziert wird.
- Synchronisierung von Daten über Verfügbarkeitszonen und Cloud-Anbieter hinweg, um beispielsweise die Verfügbarkeit zu verbessern und die An- und Ablösezeiten zu verkürzen.
- Eine gemeinsame Schicht. Egal, ob Sie mit AKS, Bare Metal, GKE oder AWS arbeiten - Ihre Verkabelungs- und Entwicklererfahrung für Speicherdienste ist so ähnlich wie möglich.
- Verwaltung der Einstufung von und zu S3 und anderen Zielen.

Ein zusätzlicher Vorteil einer vollständig nativen Lösung von Kubernetes besteht darin, dass Administratoren und Entwickler OpenEBS mit all den wunderbaren Tools interagieren 
und verwalten können, die für Kubernetes wie Kubectl, Helm, Prometheus, Grafana, Weave Scope usw. verfügbar sind.

**Our vision** ist einfach: Lassen Sie Speicher und Speicherdienste für persistente Workloads vollständig in die Umgebung integrieren, sodass jedes Team und jede Workload von der Granularität der Steuerung und dem nativen Verhalten von Kubernetes profitiert.

## Scalability

OpenEBS kann so skaliert werden, dass es eine beliebig große Anzahl von containerisierten Speichercontrollern enthält. Kubernetes wird verwendet, um grundlegende Elemente wie die Verwendung von etcd für die Inventarisierung bereitzustellen. OpenEBS skaliert in dem Maße, wie Ihre Kubernetes skaliert.

## Installation and Getting Started

OpenEBS kann in wenigen einfachen Schritten eingerichtet werden. Sie können mit der Auswahl des Kubernetes-Clusters beginnen, indem Sie open-iscsi auf den Kubernetes-Knoten installieren und den openebs-Operator mit kubectl ausführen.

**Start the OpenEBS Services using operator**
```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```
**Start the OpenEBS Services using helm**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```
Sie können auch unserer [Kurzanleitung](https://docs.openebs.io/docs/overview.html).

OpenEBS kann auf jedem Kubernetes-Cluster bereitgestellt werden - entweder in der Cloud, vor Ort oder auf einem Entwickler-Laptop (Minikube). Beachten Sie, 
dass keine Änderungen am zugrunde liegenden Kernel erforderlich sind, da OpenEBS im Benutzerbereich ausgeführt wird. Bitte folgen Sie unserer Dokumentation zu 
[OpenEBS Setup] (https://docs.openebs.io/docs/overview.html). Außerdem steht eine Vagrant-Umgebung zur Verfügung, die eine Beispielbereitstellung für Kubernetes
und eine synthetische Last enthält, mit der Sie die Leistung von OpenEBS simulieren können. Vielleicht finden Sie auch das verwandte Projekt Litmus (https://litmuschaos.io)
interessant, das beim Chaos Engineering für Stateful Workloads auf Kubernetes hilft.

## Status

OpenEBS ist eine der am weitesten verbreiteten und getesteten Kubernetes-Speicherinfrastrukturen in der Branche. OpenEBS ist seit Mai 2019 ein CNCF-Sandbox-Projekt und das erste und einzige Speichersystem, das konsistente softwaredefinierte Speicherfunktionen auf mehreren Backends (lokal, nfs, zfs, nvme) sowohl vor Ort als auch in Cloud-Systemen bereitstellt Das erste, das sein eigenes Chaos Engineering Framework für Stateful Workloads als Open Source anbietet, das [Litmus Project] (https://litmuschaos.io), auf das sich die Community stützt, um die monatliche Trittfrequenz von OpenEBS-Versionen automatisch zu bewerten. Unternehmenskunden verwenden OpenEBS seit 2018 in der Produktion und das Projekt unterstützt Docker Pulls ab 2,5 Millionen pro Woche.

Der Status verschiedener Speicher-Engines, die die OpenEBS Persistent Volumes betreiben, wird unten angegeben. Der Hauptunterschied zwischen den Status ist nachstehend zusammengefasst:
- **alpha:** Die API kann in einer späteren Softwareversion ohne vorherige Ankündigung auf inkompatible Weise geändert werden. Aufgrund des erhöhten Fehlerrisikos und des Mangels an langfristiger Unterstützung wird die Verwendung nur in kurzlebigen Testclustern empfohlen.
- **beta:** Die Unterstützung für die allgemeinen Funktionen wird nicht eingestellt, Details können sich jedoch ändern. Unterstützung für das Upgrade oder die Migration zwischen Versionen wird entweder durch Automatisierung oder durch manuelle Schritte bereitgestellt.
- **stable:** Funktionen werden in der freigegebenen Software für viele nachfolgende Versionen angezeigt, und die Unterstützung für das Upgrade zwischen Versionen wird in den allermeisten Szenarien durch Software-Automatisierung bereitgestellt.

| Storage Engine | Status | Details |
|---|---|---|
| Jiva | stable | Am besten geeignet, um Replicated Block Storage auf Knoten auszuführen, die kurzlebigen Speicher auf den Kubernetes-Worker-Knoten verwenden |
| cStor | beta | Eine bevorzugte Option für die Ausführung auf Knoten mit Blockgeräten. Empfohlene Option, wenn Snapshot und Klone erforderlich sind |
| Local Volumes | beta | Am besten geeignet für verteilte Anwendungen, die Speicher mit geringer Latenz benötigen - direkt angeschlossener Speicher von den Kubernetes-Knoten. |
| Mayastor | alpha | Eine neue Speicher-Engine, die mit der Effizienz von Local Storage arbeitet, aber auch Speicherdienste wie Replikation bietet. Die Entwicklung zur Unterstützung von Snapshots und Klonen ist im Gange. |

Weitere Informationen finden Sie in der [OpenEBS-Dokumentation] (https://docs.openebs.io/docs/next/quickstart.html).

## Contributing

OpenEBS welcomes your feedback and contributions in any form possible.

- [OpenEBS-Community auf Kubernetes Slack beitreten] (https://kubernetes.slack.com)
  - Schon angemeldet? Besuchen Sie unsere Diskussionen unter [#openebs] (https://kubernetes.slack.com/messages/openebs/).
- Möchten Sie ein Problem ansprechen oder bei Korrekturen und Funktionen helfen?
  - Siehe [offene Ausgaben] (https://github.com/openebs/openebs/issues)
  - Siehe [beitragender Leitfaden] (./ CONTRIBUTING.md)
  - Möchten Sie an unseren Community-Meetings für Mitwirkende teilnehmen, [check this out] (./ community / README.md).
  - Treten Sie unseren OpenEBS CNCF Mailinglisten bei
  - Abonnieren Sie für OpenEBS-Projektaktualisierungen [OpenEBS-Ankündigungen] (https://lists.cncf.io/g/cncf-openebs-announcements).
  - Abonnieren Sie für die Interaktion mit anderen OpenEBS-Benutzern [OpenEBS-Benutzer] (https://lists.cncf.io/g/cncf-openebs-users).
  
## Show me the Code

Dies ist ein Meta-Repository für OpenEBS. Beginnen Sie mit den angehefteten Repositorys oder mit dem Dokument [OpenEBS Architecture] (./ Contribution / Design / README.md).

## License
OpenEBS wird unter der Lizenz [Apache License 2.0] (https://github.com/openebs/openebs/blob/master/LICENSE) auf Projektebene entwickelt. Einige Komponenten des Projekts stammen aus anderen Open Source-Projekten und werden unter ihren jeweiligen Lizenzen vertrieben.

OpenEBS ist Teil der CNCF-Projekte.

[! [CNCF Sandbox Project] (https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)] (https: // Landschaft.cncf.io/selected=open-ebs)


## Commercial Offerings

This is a list of third-party companies and individuals who provide products or services related to OpenEBS. OpenEBS is a CNCF project which does not endorse any company. The list is provided in alphabetical order.
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [Gridworkz Cloud Services](https://gridworkz.com/)
- [MayaData](https://mayadata.io/)
