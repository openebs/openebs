# OpenEBS

[![Rilasci](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**Leggi questo documento in**
[🇩🇪](translations/README.de.md)	
[🇷🇺](translations/README.ru.md)	
[🇹🇷](translations/README.tr.md)	
[🇺🇦](translations/README.ua.md)	
[🇨🇳](translations/README.zh.md)	
[🇫🇷](translations/README.fr.md)
[🇧🇷](translations/README.pt-BR.md)
[🇪🇸](translations/README.es.md)
[🇮🇹](translations/README.it.md)
[🇵🇱](translations/README.pl.md)
**[altre lingue](translations/#readme).**

**OpenEBS** è la soluzione di storage open source più diffusa e facile da usare per Kubernetes.

**OpenEBS** è il principale esempio open source di una categoria di soluzioni di archiviazione cloud native talvolta chiamate [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). **OpenEBS** è elencato come esempio open source nel [White Paper CNCF Storage Landscape](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) nelle soluzioni di storage iperconvergente.

Alcuni aspetti chiave che rendono OpenEBS diverso rispetto ad altre soluzioni di storage tradizionali:
- Costruito utilizzando l'architettura dei microservizi come le applicazioni che serve. OpenEBS stesso viene distribuito come un set di contenitori sui nodi di lavoro Kubernetes. Utilizza Kubernetes stesso per orchestrare e gestire i componenti OpenEBS.
- Costruito completamente nello spazio utente che lo rende altamente portabile per l'esecuzione su qualsiasi sistema operativo/piattaforma.
- Completamente orientato all'intento, ereditando gli stessi principi che guidano la facilità d'uso con Kubernetes.
- OpenEBS supporta una gamma di motori di archiviazione in modo che gli sviluppatori possano implementare la tecnologia di archiviazione appropriata ai loro obiettivi di progettazione delle applicazioni. Le applicazioni distribuite come Cassandra possono utilizzare il motore LocalPV per scritture a latenza più bassa. Le applicazioni monolitiche come MySQL e PostgreSQL possono utilizzare il motore ZFS (cStor) per la resilienza. Le applicazioni di streaming come Kafka possono utilizzare il motore NVMe [Mayastor](https://github.com/openebs/Mayastor) per le migliori prestazioni in ambienti edge. Per tutti i tipi di motore, OpenEBS fornisce un framework coerente per alta disponibilità, snapshot, cloni e gestibilità.

Lo stesso OpenEBS viene distribuito come un altro container sul tuo host e abilita servizi di storage che possono essere designati a livello di pod, applicazione, cluster o container, tra cui:
- Automatizza la gestione dello storage collegato ai nodi di lavoro Kubernetes e consenti l'utilizzo dello storage per il provisioning dinamico di PV OpenEBS o PV locali.
- Persistenza dei dati tra i nodi, ad esempio riducendo drasticamente il tempo impiegato per ricostruire gli anelli Cassandra.
- Sincronizzazione dei dati tra zone di disponibilità e fornitori di servizi cloud che migliorano la disponibilità e riducono i tempi di collegamento/scollegamento, ad esempio.
- Un livello comune in modo che, indipendentemente dal fatto che tu stia utilizzando AKS, bare metal, GKE o AWS, il cablaggio e l'esperienza degli sviluppatori per i servizi di storage sono il più simili possibile.
- Gestione del tiering da e verso S3 e altri target.
Un ulteriore vantaggio di essere una soluzione completamente nativa di Kubernetes è che gli amministratori e gli sviluppatori possono interagire e gestire OpenEBS utilizzando tutti i meravigliosi strumenti disponibili per Kubernetes come kubectl, Helm, Prometheus, Grafana, Weave Scope, ecc.

**La nostra visione** è semplice: lasciare che i servizi di storage e storage per i carichi di lavoro persistenti siano completamente integrati nell'ambiente in modo che ogni team e carico di lavoro tragga vantaggio dalla granularità del controllo e dal comportamento nativo di Kubernetes.

## Scalabilità

OpenEBS può scalare per includere un numero arbitrariamente elevato di controller di storage containerizzati. Kubernetes viene utilizzato per fornire elementi fondamentali come l'utilizzo di etcd per l'inventario. OpenEBS scala nella misura in cui è scalabile il tuo Kubernetes.

## Installazione e introduzione

OpenEBS può essere configurato in pochi semplici passaggi. Puoi iniziare a scegliere il cluster Kubernetes installando open-iscsi sui nodi Kubernetes ed eseguendo openebs-operator utilizzando kubectl.

**Avvia i servizi OpenEBS utilizzando operator**
```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Avvia i servizi OpenEBS utilizzando helm**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

Puoi anche seguire la nostra [Guida rapida](https://docs.openebs.io/docs/overview.html).

OpenEBS può essere distribuito su qualsiasi cluster Kubernetes, nel cloud, in sede o in un laptop per sviluppatori (minikube). Notare che non ci sono modifiche al kernel sottostante necessarie poiché OpenEBS opera nello spazio utente. Si prega di seguire la nostra documentazione [Installazione OpenEBS](https://docs.openebs.io/docs/overview.html). Inoltre, è disponibile un ambiente Vagrant che include un esempio di distribuzione Kubernetes e un carico sintetico che puoi utilizzare per simulare le prestazioni di OpenEBS. Potresti anche trovare interessante il progetto correlato chiamato [Litmus](https://litmuschaos.io) che aiuta con l'ingegneria del caos per i carichi di lavoro stateful su Kubernetes.

## Stato

OpenEBS è una delle infrastrutture di storage Kubernetes più utilizzate e testate nel settore. Un progetto CNCF Sandbox da maggio 2019, OpenEBS è il primo e unico sistema di archiviazione a fornire un insieme coerente di funzionalità di archiviazione definite dal software su più backend (locali, nfs, zfs, nvme) su sistemi sia on-premise che cloud, ed è stato il primo a rendere open source il proprio Chaos Engineering Framework for Stateful Workloads, il [Litmus Project](https://litmuschaos.io), su cui si basa la community per valutare automaticamente la prontezza della cadenza mensile delle versioni di OpenEBS. I clienti aziendali utilizzano OpenEBS in produzione dal 2018 e il progetto supporta oltre 2,5 milioni di docker pull a settimana.

Di seguito viene fornito lo stato dei vari motori di archiviazione che alimentano i volumi persistenti di OpenEBS. La differenza fondamentale tra gli stati è riassunta di seguito:
- **alpha:** L'API può cambiare in modi incompatibili in una versione successiva del software senza preavviso, consigliata per l'uso solo in cluster di test di breve durata, a causa dell'aumento del rischio di bug e della mancanza di supporto a lungo termine.
- **beta**: il supporto per le funzionalità generali non verrà eliminato, anche se i dettagli potrebbero cambiare. Verrà fornito supporto per l'aggiornamento o la migrazione tra le versioni, tramite automazione o passaggi manuali.
- **stabile**: le funzionalità appariranno nel software rilasciato per molte versioni successive e il supporto per l'aggiornamento tra le versioni verrà fornito con l'automazione del software nella stragrande maggioranza degli scenari.


| Motore di archiviazione | Stato | Dettagli |
|---|---|---|
| Jiva | stabile | Ideale per l'esecuzione di Replicated Block Storage su nodi che utilizzano storage temporaneo sui nodi di lavoro Kubernetes |
| cStor | beta | Un'opzione preferita per l'esecuzione su nodi che dispongono di dispositivi a blocchi. Opzione consigliata se sono richiesti snapshot e cloni |
| Local Volumes | beta | Ideale per applicazioni distribuite che richiedono storage a bassa latenza: storage direct-attached dai nodi Kubernetes. |
| Mayastor | beta | Un nuovo motore di archiviazione che opera con l'efficienza dell'archiviazione locale ma offre anche servizi di archiviazione come la replica. È in corso lo sviluppo per supportare snapshot e cloni. |

Per maggiori dettagli, fare riferimento alla [Documentazione OpenEBS](https://docs.openebs.io/docs/next/overview.html). 

## Contribuire

OpenEBS accoglie i tuoi commenti e contributi in ogni forma possibile.

- [Unisciti alla community OpenEBS su Kubernetes Slack](https://kubernetes.slack.com)
   - Già registrato? Vai alle nostre discussioni su [#openebs](https://kubernetes.slack.com/messages/openebs/)
- Vuoi sollevare un problema o hai bisogno di aiuto con correzioni e funzionalità?
   - Vedi [problemi aperti](https://github.com/openebs/openebs/issues)
   - Vedi [guida ai contributi](./CONTRIBUTING.md)
   - Vuoi unirti alle riunioni della nostra community di contributori, [dai un'occhiata](./community/README.md).
- Unisciti alle nostre mailing list OpenEBS CNCF
   - Per gli aggiornamenti del progetto OpenEBS, iscriviti a [OpenEBS Announcements](https://lists.cncf.io/g/cncf-openebs-announcements)
   - Per interagire con altri utenti OpenEBS, iscriviti a [Utenti OpenEBS](https://lists.cncf.io/g/cncf-openebs-users)

## Mostrami il codice

Questo è un meta-repository per OpenEBS. Inizia con i repository bloccati o con il documento [OpenEBS Architecture](./contribute/design/README.md).

## Licenza

OpenEBS è sviluppato sotto licenza [Apache License 2.0](https://github.com/openebs/openebs/blob/master/LICENSE) a livello di progetto. Alcuni componenti del progetto derivano da altri progetti open source e sono distribuiti con le rispettive licenze.

OpenEBS fa parte dei Progetti CNCF.

[![Progetto Sandbox CNCF](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)](https://landscape.cncf.io/selected=open-ebs)

## Offerte commerciali

Questo è un elenco di società e individui di terze parti che forniscono prodotti o servizi relativi a OpenEBS. OpenEBS è un progetto CNCF che non sostiene nessuna azienda. L'elenco è fornito in ordine alfabetico.
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [Servizi cloud Gridworkz](https://www.gridworkz.com/)
- [MayaData](https://mayadata.io/)
