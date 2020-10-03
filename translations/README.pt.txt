






[! [Práticas recomendadas CII] (https://bestpractices.coreinfrastructure.org/projects/1754/badge)] (https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

** OpenEBS ** é a solução de armazenamento de código aberto mais amplamente implantada e fácil de usar para Kubernetes.

** OpenEBS ** é o exemplo de código aberto líder de uma categoria de soluções de armazenamento, às vezes chamada [Container Attached Storage] (https://www.cncf.io/blog/2018/04/19/container-attached-storage- um iniciador/). ** OpenEBS ** está listado como um exemplo de código aberto no [CNCF Storage Landscape White Paper] (https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-% 20White% 20Paper.pdf) nas soluções de armazenamento hiperconvergente.

Alguns aspectos importantes que tornam o OpenEBS diferente em comparação com outras soluções de armazenamento tradicionais:

- Construído usando a arquitetura de micro-serviços como os aplicativos que atende. O OpenEBS é implantado como um conjunto de contêineres nos nós de trabalho do Kubernetes. Usa o próprio Kubernetes para orquestrar e gerenciar componentes OpenEBS
- Construído completamente no espaço do usuário, tornando-o altamente portátil para ser executado em qualquer sistema operacional / plataforma
- Totalmente orientado pela intenção, herdando os mesmos princípios que orientam a facilidade de uso com o Kubernetes
- OpenEBS oferece suporte a uma variedade de mecanismos de armazenamento para que os desenvolvedores possam implantar a tecnologia de armazenamento apropriada para seus objetivos de design de aplicativo. Aplicativos distribuídos como Cassandra podem usar o mecanismo LocalPV para gravações de menor latência. Aplicativos monolíticos como MySQL e PostgreSQL podem usar o mecanismo ZFS (cStor) para resiliência. Aplicativos de streaming como o Kafka podem usar o mecanismo NVMe [Mayastor] (https://github.com/openebs/Mayastor) para melhor desempenho em ambientes de ponta. Em todos os tipos de mecanismo, o OpenEBS fornece uma estrutura consistente para alta disponibilidade, instantâneos, clones e capacidade de gerenciamento.

O próprio OpenEBS é implantado como apenas mais um contêiner em seu host e permite serviços de armazenamento que podem ser designados por pod, aplicativo, cluster ou nível de contêiner, incluindo:

- Automatize o gerenciamento de armazenamento anexado aos nós de trabalho do Kubernetes e permita que o armazenamento seja usado para provisionar PVs OpenEBS ou PVs locais dinamicamente.
- Persistência de dados entre nós, reduzindo drasticamente o tempo gasto na reconstrução de anéis Cassandra, por exemplo.
- Sincronização de dados entre zonas de disponibilidade e provedores de nuvem melhorando a disponibilidade e diminuindo os tempos de conexão / desconexão, por exemplo.
- Uma camada comum, então se você está executando em AKS, ou bare metal, ou GKE ou AWS - sua fiação e experiência de desenvolvedor para serviços de armazenamento é o mais semelhante possível.
- Gerenciamento de camadas de e para S3 e outros alvos.

Uma vantagem adicional de ser uma solução totalmente nativa do Kubernetes é que os administradores e desenvolvedores podem interagir e gerenciar o OpenEBS usando todas as ferramentas maravilhosas que estão disponíveis para o Kubernetes, como kubectl, Helm, Prometheus, Grafana, Weave Scope, etc.

** Nossa visão ** é simples: permitir que os serviços de armazenamento e armazenamento para cargas de trabalho persistentes sejam totalmente integrados ao ambiente para que cada equipe e carga de trabalho se beneficiem da granularidade de controle e do comportamento nativo do Kubernetes.

#### _Leia em [outras línguas] (traduções / TRADUÇÕES.md) ._

[🇩🇪] (traduções / README.de.md)
[🇮🇳] (traduções / README.hi.md)
[🇷🇺] (traduções / README.ru.md)
[🇹🇷] (traduções / README.tr.md)
[🇺🇦] (traduções / README.ua.md)
[🇨🇳] (traduções / README.zh.md)

## Escalabilidade

O OpenEBS pode ser dimensionado para incluir um número arbitrariamente grande de controladores de armazenamento em contêineres. O Kubernetes é usado para fornecer peças fundamentais, como o uso de etcd para inventário. O OpenEBS é dimensionado na medida em que seu Kubernetes é dimensionado

## Instalação e primeiros passos
 
O OpenEBS pode ser configurado em algumas etapas fáceis. Você pode começar sua escolha de cluster Kubernetes instalando open-iscsi nos nós do Kubernetes e executando o operador openebs usando kubectl.

** Inicie os Serviços OpenEBS usando o operador **

`` `bash
# aplique este yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
`` `

** Inicie os serviços OpenEBS usando o helm **

`` `bash
atualização de repositório de leme
helm install --namespace openebs --name openebs stable / openebs
`` `

Você também pode seguir nosso [Guia de início rápido] (https://docs.openebs.io/docs/overview.html).

O OpenEBS pode ser implantado em qualquer cluster Kubernetes - na nuvem, no local ou no laptop do desenvolvedor (minikube). Observe que não há mudanças no kernel subjacente que são necessárias, pois o OpenEBS opera no espaço do usuário. Siga nossa documentação [OpenEBS Setup] (https://docs.openebs.io/docs/overview.html). Além disso, temos um ambiente Vagrant disponível que inclui uma implantação de amostra do Kubernetes e carga sintética que você pode usar para simular o desempenho do OpenEBS. Você também pode achar interessante o projeto relacionado chamado Litmus (https://litmuschaos.io), que ajuda na engenharia do caos para cargas de trabalho com estado no Kubernetes.

## Status

OpenEBS é uma das infraestruturas de armazenamento Kubernetes mais amplamente usadas e testadas do setor. Um projeto CNCF Sandbox desde maio de 2019, OpenEBS é o primeiro e único sistema de armazenamento a fornecer um conjunto consistente de recursos de armazenamento definidos por software em vários back-ends (local, nfs, zfs, nvme) em sistemas locais e em nuvem, e foi o primeiro a abrir o código-fonte de seu próprio Chaos Engineering Framework para Stateful Workloads, o [Litmus Project] (https://litmuschaos.io), do qual a comunidade conta para avaliar automaticamente a cadência mensal das versões do OpenEBS. Os clientes corporativos têm usado o OpenEBS em produção desde 2018 e o projeto suporta mais de 2,5 milhões de dockers por semana.

O status de vários mecanismos de armazenamento que alimentam os Volumes Persistentes OpenEBS são fornecidos abaixo. As principais diferenças entre os status são resumidas abaixo:

- ** alpha: ** A API pode mudar de maneiras incompatíveis em uma versão posterior do software sem aviso prévio, recomendado para uso apenas em clusters de teste de curta duração, devido ao aumento do risco de bugs e falta de suporte de longo prazo.
- ** beta **: o suporte para os recursos gerais não será eliminado, embora os detalhes possam mudar. O suporte para atualização ou migração entre versões será fornecido, seja por meio de automação ou etapas manuais.
- ** estável **: os recursos aparecerão no software lançado para muitas versões subsequentes e o suporte para atualização entre as versões será fornecido com automação de software na grande maioria dos cenários.

| Motor de armazenamento | Status | Detalhes |
| -------------- | ------ | -------------------------------------------------- -------------------------------------------------- -------------------------------------------------- --------------------------- |
| Jiva | estável | Mais adequado para executar o armazenamento em bloco replicado em nós que usam armazenamento efêmero nos nós de trabalho do Kubernetes |
| cStor | beta | Uma opção preferencial para execução em nós que possuem dispositivos de bloco. Opção recomendada se Snapshot e Clones forem necessários |
| Volumes locais | beta | Mais adequado para aplicativos distribuídos que precisam de armazenamento de baixa latência - armazenamento com conexão direta dos nós do Kubernetes. |
| Mayastor | alfa | Um novo mecanismo de armazenamento que opera com a eficiência do armazenamento local, mas também oferece serviços de armazenamento como a replicação. O desenvolvimento está em andamento para oferecer suporte a Snapshots e Clones. |

Para obter mais detalhes, consulte a [Documentação do OpenEBS] (https://docs.openebs.io/docs/next/quickstart.html).

## Contribuindo
 
O OpenEBS agradece seus comentários e contribuições em qualquer forma possível.
 
- [Junte-se à comunidade OpenEBS no Kubernetes Slack] (https://kubernetes.slack.com)
  - Já se inscreveu? Acesse nossas discussões em [#openebs] (https://kubernetes.slack.com/messages/openebs/)
- Deseja levantar um problema ou ajudar com correções e recursos?
  - Veja [questões abertas] (https://github.com/openebs/openebs/issues)
  - Consulte [guia de contribuição] (./ CONTRIBUINDO.md)
  - Deseja participar das reuniões da comunidade de colaboradores, [verifique] (./ community / README.md).
- Junte-se às nossas listas de discussão OpenEBS CNCF
  - Para atualizações do projeto OpenEBS, inscreva-se em [Anúncios OpenEBS] (https://lists.cncf.io/g/cncf-openebs-announcements)
  - Para interagir com outros usuários do OpenEBS, inscreva-se em [Usuários do OpenEBS] (https://lists.cncf.io/g/cncf-openebs-users)

## Mostre-me o código

Este é um meta-repositório para OpenEBS. Comece com os repositórios fixados ou com o documento [Arquitetura OpenEBS] (./ contrib / design / README.md).

## Licença

O OpenEBS é desenvolvido sob a licença [Apache License 2.0] (https://github.com/openebs/openebs/blob/master/LICENSE) no nível do projeto. Alguns componentes do projeto são derivados de outros projetos de código aberto e são distribuídos sob suas respectivas licenças.

OpenEBS faz parte dos Projetos CNCF.

@@ -110,6 +115,7 @@ OpenEBS faz parte dos Projetos CNCF.
## Ofertas Comerciais

Esta é uma lista de empresas terceirizadas e indivíduos que fornecem produtos ou serviços relacionados ao OpenEBS. OpenEBS é um projeto CNCF que não endossa nenhuma empresa. A lista é fornecida em ordem alfabética.

- [Clouds Sky GmbH] (https://cloudssky.com/en/)
- [CodeWave] (https://codewave.eu/)
- [Gridworkz Cloud Services] (https://gridworkz.com/)