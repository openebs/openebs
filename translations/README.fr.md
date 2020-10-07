# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**OpenEBS** est la solution de stockage open source la plus déployée et la plus simple à utiliser pour Kubernetes.

**OpenEBS** est le principal exemple open-source d'une catégorie de solutions de stockage parfois appelée [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). **OpenEBS** est répertorié comme un exemple open-source dans le [CNCF Storage Landscape White Paper](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) sous les solutions de stockage hyper-convergentes.

Quelques aspects clés qui différencient OpenEBS des autres solutions de stockage traditionnelles:
- Construit en utilisant l'architecture des micro-services tout comme les applications qu'il sert. OpenEBS est lui-même déployé en tant qu'ensemble de conteneurs sur les nodes Kubernetes. Utilise Kubernetes lui-même pour orchestrer et gérer les composants OpenEBS
- Construit entièrement dans l'userspace, ce qui le rend hautement portable pour fonctionner sur n'importe quel système d'exploitation/plate-forme
- Entièrement orienté intention (intent-driven), héritant des mêmes principes qui conduisent à la facilité d'utilisation avec Kubernetes
- OpenEBS prend en charge une gamme de moteurs de stockage afin que les développeurs puissent déployer la technologie de stockage appropriée à leurs objectifs de conception d'application. Les applications distribuées comme Cassandra peuvent utiliser le moteur LocalPV pour les écritures à latence la plus faible. Les applications monolithiques comme MySQL et PostgreSQL peuvent utiliser le moteur ZFS (cStor) pour la résilience. Les applications de streaming comme Kafka peuvent utiliser le moteur NVMe [Mayastor](https://github.com/openebs/Mayastor) pour de meilleures performances dans les environnements edge. Pour tous les types de moteurs, OpenEBS fournit un cadre cohérent pour la haute disponibilité, les snapshots, les clones et la gérabilité.

OpenEBS lui-même est déployé comme un simple autre conteneur sur votre hôte et active des services de stockage qui peuvent être désignés au niveau d'un pod, d'une application, d'un cluster ou d'un conteneur, notamment:
- Automatisez la gestion du stockage attaché aux nodes de travail Kubernetes et permettez au stockage d'être utilisé pour provisionner dynamiquement des PV OpenEBS ou des PV locaux.
- Persistance des données entre les nodes, réduisant considérablement le temps passé à reconstruire les anneaux Cassandra par exemple.
- Synchronisation des données entre les zones de disponibilité et les fournisseurs de cloud améliorant la disponibilité et diminuant les temps d'attachement/détachement par exemple.
- Une couche commune, que vous utilisiez AKS, votre bare metal, GKE ou AWS - votre expérience pour les services de stockage est aussi similaire que possible.
- Gestion de la hiérarchisation vers/depuis S3 et d'autres cibles.

Un avantage supplémentaire d'être une solution entièrement native de Kubernetes est que les administrateurs et les développeurs peuvent interagir et gérer OpenEBS en utilisant tous les merveilleux outils disponibles pour Kubernetes comme kubectl, Helm, Prometheus, Grafana, Weave Scope, etc.

**Notre vision** est simple: laissez le stockage et les services de stockage pour les workloads persistants être entièrement intégrés dans l'environnement afin que chaque équipe et charge de travail bénéficie de la granularité du contrôle et du comportement natif de Kubernetes.

#### *Lisez ceci dans [autres langues](/translations#readme).*

## Scalabilité

OpenEBS peut évoluer pour inclure un nombre arbitrairement grand de contrôleurs de stockage en conteneur. Kubernetes est utilisé pour fournir des éléments fondamentaux tels que l'utilisation d'etcd pour l'inventaire. OpenEBS évolue dans la mesure où votre Kubernetes évolue.

## Installation et mise en route

OpenEBS peut être configuré facilement en quelques étapes. Vous pouvez commencer sur le cluster kubernetes de votre choix en installant open-iscsi sur les nodes Kubernetes et en exécutant l'openebs-operator à l'aide de kubectl.

**Démarrez les services OpenEBS à l'aide de l'opérateur**

```bash
# appliquer ce yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Démarrez les services OpenEBS à l'aide de helm**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

Vous pouvez également suivre notre [Guide de démarrage rapide](https://docs.openebs.io/docs/overview.html).

OpenEBS peut être déployé sur n'importe quel cluster Kubernetes - soit dans le cloud, on-premise ou en local (minikube). Notez qu'aucune modification du noyau sous-jacent n'est requise car OpenEBS fonctionne dans l'userspace. Veuillez suivre notre documentation [OpenEBS Setup](https://docs.openebs.io/docs/overview.html). En outre, nous avons un environnement Vagrant disponible qui comprend un exemple de déploiement Kubernetes et une charge synthétique que vous pouvez utiliser pour simuler les performances d'OpenEBS. Vous pouvez également trouver intéressant le projet associé appelé Litmus (https://litmuschaos.io) qui aide à faire du chaos engineering pour les charges de travail avec état sur Kubernetes.

## Statut

OpenEBS est l'une des infrastructures de stockage Kubernetes les plus utilisées et les plus testées du secteur. Projet CNCF Sandbox depuis mai 2019, OpenEBS est le premier et le seul système de stockage à fournir un ensemble cohérent de capacités de stockage définies par logiciel sur plusieurs backends (local, nfs, zfs, nvme) à la fois sur les systèmes sur site et dans le cloud, et a été le premier à ouvrir en source son propre Chaos Engineering Framework for Stateful Workloads, le [Litmus Project](https://litmuschaos.io), sur lequel la communauté s'appuie pour évaluer automatiquement la cadence mensuelle des versions d'OpenEBS. Les entreprises clientes utilisent OpenEBS en production depuis 2018 et le projet prend en charge 2.5M+ de docker pulls par semaine.

L'état des différents moteurs de stockage qui alimentent les volumes persistants OpenEBS est indiqué ci-dessous. La principale différence entre les statuts est résumée ci-dessous:
- **alpha:** L'API peut changer de manière incompatible dans une version ultérieure du logiciel sans préavis, recommandé pour une utilisation uniquement dans des clusters de test de courte durée, en raison d'un risque accru de bogues et d'un manque de support à long terme.
- **beta:** La prise en charge de l'ensemble des fonctionnalités ne sera pas abandonnée, bien que les détails puissent changer. La prise en charge de la mise à niveau ou de la migration entre les versions sera fournie, soit par automatisation, soit par étapes manuelles.
- **stable:** Les fonctionnalités apparaîtront dans les logiciels publiés pour de nombreuses versions ultérieures et la prise en charge de la mise à niveau entre les versions sera fournie avec l'automatisation logicielle dans la grande majorité des scénarios.

| Moteur de stockage | Statut | Détails |
|---|---|---|
| Jiva | stable | Idéal pour exécuter le stockage de blocs répliqué sur des nodes qui utilisent le stockage éphémère sur les nodes Kubernetes |
| cStor | beta | Une option préférée pour s'exécuter sur des nodes dotés de périphériques de blocage. Option recommandée si Snapshot et Clones sont requis |
| Volumes locaux | beta | Idéal pour les applications distribuées nécessitant un stockage à faible latence - stockage en attachement direct à partir des nodes Kubernetes. |
| Mayastor | alpha | Un nouveau moteur de stockage qui fonctionne avec l'efficacité du stockage local mais offre également des services de stockage comme la réplication. Le développement est en cours pour prendre en charge les snapshots et les clones. |

Pour plus de détails, veuillez consulter la [Documentation OpenEBS](https://docs.openebs.io/docs/next/quickstart.html).

## Contribuer

OpenEBS accueille vos commentaires et contributions sous toutes les formes possibles.

- [Rejoignez la communauté OpenEBS sur le Slack Kubernetes](https://kubernetes.slack.com)
  - Déjà inscrit? Dirigez-vous vers nos discussions sur [#openebs](https://kubernetes.slack.com/messages/openebs/)
- Vous souhaitez signaler un problème ou obtenir de l'aide sur les correctifs et les fonctionnalités?
  - Voir [les problèmes en suspens](https://github.com/openebs/openebs/issues)
  - Voir [le guide de contribution](./CONTRIBUTING.fr.md)
  - Vous voulez rejoindre nos réunions de communauté de contributeurs, [vérifiez ceci](./community/README.md).
- Rejoignez nos listes de diffusion OpenEBS CNCF
  - Pour les mises à jour du projet OpenEBS, abonnez-vous à [OpenEBS Announcements](https://lists.cncf.io/g/cncf-openebs-announcements)
  - Pour interagir avec d'autres utilisateurs d'OpenEBS, abonnez-vous à [OpenEBS Users](https://lists.cncf.io/g/cncf-openebs-users)

## Montre-moi le code

Ceci est un méta-référentiel pour OpenEBS. Veuillez commencer avec les référentiels épinglés ou avec le document [OpenEBS Architecture](./contribut/design/README.md).

## Licence

OpenEBS est développé sous licence [Apache License 2.0](https://github.com/openebs/openebs/blob/master/LICENSE) au niveau du projet. Certains composants du projet sont dérivés d'autres projets open source et sont distribués sous leurs licences respectives.

OpenEBS fait partie des projets CNCF.

[![CNCF Sandbox Project](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)](https://landscape.cncf.io/selected=open-ebs)

## Offres commerciales

Il s'agit d'une liste d'entreprises tierces et d'individus qui fournissent des produits ou des services liés à OpenEBS. OpenEBS est un projet CNCF qui ne cautionne aucune entreprise. La liste est fournie par ordre alphabétique.
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [Services cloud Gridworkz](https://gridworkz.com/)
- [MayaData](https://mayadata.io/)
