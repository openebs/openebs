# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**OpenEBS** é a solução de armazenamento open-source mais utilizada e de fácil utilização para Kubernetes.

**OpenEBS** é o principal exemplo open-source de uma categoria de soluções de armazenamento, as vezes chamado de [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). **OpenEBS** é listado como um exemplo de open-source no [] [CNCF Storage Landscape White Paper](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) nas soluções de armazenamento hiperconvergido.

Alguns dos aspectos chave que fazem OpenEBS diferente comparado à outras soluções de armazenamento tradicionais:
- Construído usando arquitetura de micro-serviços como a aplicação que lhe serve. O deploy de OpenEBS é realizado como um conjunto de containers nos nodes de Kubernetes. Usa Kubernetes para orquestrar e gerenciar os componentes OpenEBS
- Construído completamente no userspace, tornando-se muito portátil para rodar através de qualquer SO/plataforma
- Completamente conduzido pela intenção (intent-driven), herdando os mesmos princípios que conduzem a facilidade de uso com Kubernetes
- OpenEBS suporta uma variedade de engines (motores) de armazenamento para que pessoas desenvolvedoras possam realizar o deploy da tecnologia de armazenamento apropriada para os objetivos de design de suas aplicações. Aplicações distribuidas, como Cassandra, podem utilizar a engine (motor) LocalPV para a menor latência de escrita. Aplicações monolíticas como MySQL e PostgreSQL podem utilizar a engine (motor) ZFS (cStor) para resiliência. Aplicações de streaming como Kafka podem usar a engine (motor) NVMe [Mayastor](https://github.com/openebs/Mayastor) para a melhor performance em ambientes edge. Através de tipos de engines (motores), OpenEBS provê um framework consistente para alta disponibilidade, snapshots, clones e gerenciamento.

O deploy de OpenEBS é realizado como qualquer outro container na sua hospedagem e habilita serviços de armazenamento que podem ser designados à nível de pod, aplicação, cluster ou container, incluindo:
- Automatize o gerenciamento de armazenamento anexado aos nodes Kubernetes e permita o armazenamento para ser utilizado no provisionamento dinâmico dos PVs OpenEBS ou PVs Locais.
- Persistência de dados através de nodes, reduzindo dramaticamente o tempo gasto re-criando rings Cassandra, por exemplo.
- Sincronização de dados através de zonas de disponibilidade e provedores cloud, melhorando a disponibilidade e diminuindo o tempo de anexo/separação, por exemplo.
- Uma camada comum então esteja você todando em AKS, ou no seu "bare metal", ou GKE, ou AWS - sua experiência de serviço de armazenamento é a mais similar possível.
- Gerenciamento de escalonamento para e de S3 e outros targets.

Uma vantagem de ser uma solução nativa ao Kubernetes é que administradores e desenvolvedores podem interagir e gerenciar OpenEBS usando todas as maravilhosas ferramentas que estão disponíveis para Kubernetes, como kubectl, Helm, Prometheus, Grafana, Weave Scope, etc.

**Nossa visão** é simples: permitir armazenamento e serviços de armazenamento para trabalhos persistêntes serem totalmente integrados ao ambiente para que cada time e trabalho possa se beneficiar da granularidade de controle e o comportamento nativo de Kubernetes.

#### *Leia em [outros idiomas](translations/TRANSLATIONS.md).*

[🇩🇪](README.de.md)
[:uk:](/README.md)
[🇷🇺](README.ru.md)
[🇹🇷](README.tr.md)
[🇺🇦](README.ua.md)
[🇨🇳](README.zh.md)
[🇫🇷](README.fr.md)

## Escalabilidade

OpenEBS pode escalar para incluir arbitrariamente um alto número de controladores de armazenamento containerizado. Kubernetes é usado para prover peças fundamentais como usar etcd para inventário. OpenEBS escala para a extenão que seu Kubernetes escala.

## Instalação e Inicio

OpenEBS pode ser configurado em alguns passos simples. Você pode iniciar com sua escolha entre um cluster Kubernetes tendo open-iscsi instalado nos nodes Kubernetes e rodando openebs-operator usando kubectl.

**Inicie os Serviços OpenEBS usando operador**
```bash
# aplique este yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Inicie os Serviços OpenEBS utilizando helm**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

Você também pode seguir nosso [Guia de Início Rápido](https://docs.openebs.io/docs/overview.html).

O deploy de OpenEBS pode ser realizado em qualquer cluster Kubernetes - seja na cloud, on-premise ou no laptop da pessoa desenvolvedora (minikube). Note que não há diferenças no kernel que sejam requeridas já que OpenEBS opera no userspace. Por favor siga nossa documentação de [Setup OpenEBS](https://docs.openebs.io/docs/overview.html). Nós também temos um ambiente Vagrant disponível que inclui um modelo de deploy Kubernetes e carga sintética que você pode utilizar para simular a performance de OpenEBS. Você também pode achar interessante o projeto relacionado chamado Litmus (https://litmuschaos.io) que ajuda com chaos engineering para trabalhos com estado no Kubernetes.

## Status

OpenEBS é uma das infraestruturas de armazenamento Kubernetes mais amplamente utilizada e testada na indústria. Um projeto CNCF Sandbox desde Maio de 2019, OpenEBS é o primeiro e único sistema de armazenamento que provê um consistente grupo de capacidades de armazenamento definidas por software em múltiplos backends (local, nfs, zfs, nvme) através de sistemas on-premise e cloud, e foi o primeiro a tornar open-source seu próprio Chaos Engineering Framework para Stateful Workloads, o [Litmus Project](https://litmuschaos.io), que a comunidade conta para a prontidão automática para acessar a cadência mensal de versões OpenEBS. Clientes empresariais estão utilizando OpenEBS em produção desde 2018 e o projeto suporta 2.5M+ pulls no docker por semana.

O status de várias engines (motores) de armazenamento que capacitam os volumes persistentes de OpenEBS estão listados abaixo. A diferença principal entre os status estão sumarizadas abaixo:
- **alpha:** A API pode ter mudanças incompatíveis numa próxima release de software sem notícia, recomentada apenas para uso em clusters de teste "short-lived", devido ao aumento de risco de bugs e falta de suporte de longo prazo.
- **beta:** Suporte para features em geral não vai ser perdido, porém detalhes podem ser mudados. Suporte para upgrades ou migrações entre versões serão providas através de automação ou passos manuais.
- **estável:** Features vão aparecer em releases de software para várias versões subsequentes e suporte para aprimoramentos entre versões serão providos com automação de software na maioria dos cenários.

| Motor de Armazenamento | Estado | Detalhes |
|---|---|---|
| Jiva | estável | Mais adequado para rodar blocos de armazenamento replicado em nodes que usam armazenamento efêmero nos nodes Kubernetes |
| cStor | beta | Uma solução preferida para rodar em nodes que tem dispositivos de bloco. Opção recomendada se Snapshots e Clones forem requeridos |
| Local Volumes | beta | Mais adequado para aplicações distribuídas que requerem armazenamento com baixa latência - armazenamento de anexo direto de nodes Kubernetes |
| Mayastor | alpha | Um novo motor de armazenamento que opera com a mesma eficiência do armazenamento local porém também oferece serviços de armazenamento como Réplicas. Desenvolvimento está em andamento para suportar Snapshots e Clones. |

Para mais detalhes, por favor acesse a [Documentação OpenEBS](https://docs.openebs.io/docs/next/quickstart.html).

## Contribuindo

OpenEBS agradece seu feedback e suas contribuições em qualquer forma possível.

- [Entre na comunidade OpenEBS no Slack Kubernetes](https://kubernetes.slack.com)
  - Já está cadastrado? Entre nas nossas discussões em [#openebs](https://kubernetes.slack.com/messages/openebs/)
- Quer levantar um problema ou ajudar com features e correções?
  - Veja [problemas abertos](https://github.com/openebs/openebs/issues)
  - Veja o [guia de contribuições](/CONTRIBUTING.md)
  - Quer entrar nas nossas reuniões de contribuidor, [veja isto](/community/README.md).
- Entre na lista de e-mail de OpenEBS CNCF
  - Para atualizações de projetos OpenEBS, inscreva-se em [Anúncios OpenEBS](https://lists.cncf.io/g/cncf-openebs-announcements)
  - Para interagir com outros usuários OpenEBS, inscreva-se em [Usuários OpenEBS](https://lists.cncf.io/g/cncf-openebs-users)

## Me mostre o Código

Este é um meta-repositório para OpenEBS. Por favor inicie com os repositórios fixados ou com o documento de [Arquitetura OpenEBS](/contribute/design/README.md).

## Licença

OpenEBS é desenvolvido sob a licença [Apache License 2.0](https://github.com/openebs/openebs/blob/master/LICENSE) à nível de projeto. Alguns componentes do projeto são derivados de outros projetos open-source e estão distribuídos sob suas respectivas licenças.

OpenEBS é parte dos Projetos CNCF.

[![CNCF Sandbox Project](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)](https://landscape.cncf.io/selected=open-ebs)

## Ofertas Comerciais

Esta é uma lista com empresas terceiras e indivíduos que provêem produtos ou serviços relacionados à OpenEBS. OpenEBS é um projeto CNCF que não endossa qualquer empresa. Esta lista é apresentada em ordem alfabética.
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [Gridworkz Cloud Services](https://gridworkz.com/)
- [MayaData](https://mayadata.io/)
