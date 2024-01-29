# OpenEBS에 오신것을 환영합니다
<BR>
우리는 초현대적인 스토리지 대상 플랫폼, 하이퍼 컨버지드 스토리지 소프트웨어 시스템 및 Kubernetes 플랫폼에 기본적으로 긴밀하게 통합된 최신 스토리지 데이터 패브릭(Storage Data Fabric)입니다. <BR>
<BR>
OpenEBS는 다음 기능을 제공합니다... <BR>
<BR>

- Kubernetes를 위한 Stateful persistent storage voluems
- 100% 클라우드 네이티브 스토리지 솔루션
- 컨테이너가 전체 Kubernetes 클러스터의 스토리지에 액세스할 수 있도록 하는 Kubernetes 클러스터 전체 스토리지 패브릭을 제공
- **스냅샷, 클론 및 복제된 볼륨**과 같은 엔터프라이즈급 데이터 관리 기능 <BR>
<BR>

OpenEBS는 완전 무료이며 오픈 소스 소프트웨어입니다. 엔터프라이즈 지원 및 관리 기능을 원하는 조직을 위한 상용 옵션도 있습니다. 이는 타사 공급업체에서 제공합니다. 자세한 내용은 https://openebs.io를 참조하세요. <BR>
<BR>
2022년 OpenEBS는 초고성능 SPDK NVMe 스택, IO URIING 기술 및 Linux NVMe 드라이버를 기반으로 하는 MayaStor 스토리지 데이터 엔진을 출시했습니다. 이는 모든 Kubernetes 스토리지 제품에서 이전에 가능했던 것보다 더 높은 성능을 제공합니다.<BR>
<BR>
OpeneBS 프로젝트는 2개의 에디션으로 그룹화된 여러 데이터 엔진 프로젝트로 구성됩니다.
- 이전 스토리지 엔진을 **LEGACY Edition**이라고 분류
- 초현대적인 Mayastor 데이터 엔진은 **STANDARD Edition**으로 분류되며 다음이 포함됩니다.
    - LVM LocalPV
    - ZFS LocalPV
    - Device LocalPV
    - RawFile LocalPV
    - LocalPV-HostPath
    - LocalPV-Device

<BR>
이 프로젝트는 2024년 6월까지 모든 LEGACY 데이터 엔진을 마이그레이션, 종료 및 보관할 계획입니다. <BR>
<BR>


모든 **LEGACY** 데이터 엔진은 사용 중단됨으로 태그가 지정되며 2024년 6월까지 ARCHIVE 상태로 이동됩니다. 이러한 데이터 엔진은 다음과 같습니다:
  - Jiva - 사용자는 MayaStor Data-Engine으로 마이그레이션해야 합니다.
  - cStor - 사용자는 MayaStor Data-Engine으로 마이그레이션해야 합니다.
  - NFS 프로비저너 - 더 이상 사용되지 않습니다. RWX 서비스 또는 기능은 지원되지 않습니다.
 
**LEGACY** 사용자가 **STANDARD**로 마이그레이션할 수 있는 강력한 경로를 제공하는 **STANDARD**에 대한 새로운 로드맵 기능이 계획되어 있습니다. <BR>
<BR>
OpenEBS가 유용하길 바랍니다. 우리는 프로젝트에 대한 모든 기여를 환영합니다. 연락하고 싶으시면 cncf-openebs-maintainers@lists.cncf.io로 이메일을 보내주세요.

# 현재 상황

[![릴리즈](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![슬랙(Slack) 채널 #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![트위터(Twitter_](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PR은 언제나 환영합니다](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA 상태](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII 모범 사례](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**기타 언어**
[🇩🇪](translations/README.de.md)	
[🇷🇺](translations/README.ru.md)	
[🇹🇷](translations/README.tr.md)	
[🇺🇦](translations/README.ua.md)	
[🇨🇳](translations/README.zh.md)	
[🇫🇷](translations/README.fr.md)
[🇧🇷](translations/README.pt-BR.md)
[🇪🇸](translations/README.es.md)
[🇵🇱](translations/README.pl.md)
**[other languages](translations/#readme).**

**OpenEBS**는 [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/)라고도 불리는 클라우드 네이티브 스토리지 솔루션 범주의 대표적인 오픈 소스 예입니다. **OpenEBS**는 하이퍼컨버지드 스토리지 솔루션 아래 [CNCF Storage White Paper](https://github.com/cncf/tag-storage/blob/master/CNCF%20Storage%20Whitepaper%20V2.pdf)에 오픈 소스 예시로 나열되어 있습니다.

OpenEBS를 다른 기존 스토리지 솔루션과 다르게 만드는 몇 가지 주요 측면은 다음과 같습니다.
- 제공되는 애플리케이션과 같은 마이크로서비스 아키텍처를 사용하여 구축되었습니다. OpenEBS 자체는 Kubernetes 작업자 노드에 컨테이너 세트로 배포됩니다. Kubernetes 자체를 사용하여 OpenEBS 구성 요소를 조정하고 관리합니다.
- 완전히 사용자 공간에 구축되어 모든 OS/플랫폼에서 실행할 수 있도록 이식성이 뛰어납니다.
- Kubernetes와 함께 사용 편의성을 높이는 동일한 원칙을 계승하는 완전한 의도 중심(Completely intent-driven)의 제품입니다.
- OpenEBS는 개발자들이 자신의 애플리케이션 설계 목표에 적합한 스토리지 기술을 구현할 수 있도록 다양한 스토리지 엔진을 지원합니다. 카산드라(Cassandra)와 같은 분산형 애플리케이션은 LocalPV 엔진을 사용하여 가장 낮은 대기 시간 쓰기를 수행할 수 있습니다. MySQL 및 PostgreSQL과 같은 단일 애플리케이션은 복원력을 위해 ZFS 엔진(cStor)을 사용할 수 있습니다. 카프카와 같은 스트리밍 애플리케이션은 에지 환경에서 최고의 성능을 발휘하기 위해 NVMe 엔진 [Mayaster](https://github.com/openebs/Mayastor) 을 사용할 수 있습니다. OpenEBS는 엔진 유형 전반에 걸쳐 고가용성, 스냅샷, 클론 및 관리성을 위한 일관된 프레임워크를 제공합니다.

# 배포
OpenEBS 자체는 호스트의 또 다른 컨테이너로 구현되며 다음과 같은 포드, 애플리케이션, 클러스터 또는 컨테이너 레벨별로 지정할 수 있는 스토리지 서비스를 지원합니다:
- Kubernetes 워커 노드에 연결된 스토리지 관리를 자동화하고 OpenEBS Replication 또는 Local PV를 동적으로 프로비저닝하는 데 스토리지를 사용할 수 있도록 합니다.
- 예를 들어 노드 간의 데이터 지속성을 통해 카산드라 링을 재구축하는 데 소요되는 시간을 획기적으로 단축할 수 있습니다.
- 가용성 영역 전반에 걸쳐 볼륨 데이터를 동기식으로 복제하여 가용성을 향상시키고 연결/분리 시간을 단축합니다.
- AKS, 베어메탈, GKE 또는 AWS에서 실행하는 공통 계층 - 스토리지 서비스에 대한 배선 및 개발자 경험은 최대한 유사합니다.
- S3 및 기타 대상과의 볼륨 데이터 백업 및 복원.

완전한 Kubernetes 네이티브 솔루션의 또 다른 이점은 관리자와 개발자가 kubectl, Helm, Prometheus, Grafana, Weave Scope 등과 같은 Kubernetes에 사용할 수 있는 모든 훌륭한 도구를 사용하여 OpenEBS와 상호 작용하고 관리할 수 있다는 것입니다.

**우리의 비전**은 간단합니다. 지속적인 워크로드를 위한 스토리지 및 스토리지 서비스를 환경에 완전히 통합하여 각 팀과 워크로드가 세밀한 제어 및 Kubernetes 기본 동작의 이점을 누릴 수 있도록 하는 것입니다.

## 로드맵 (2024년 1월 현재)
OpenEBS는 100% 오픈 소스 소프트웨어입니다.
프로젝트 소스 코드는 여러 저장소에 분산되어 있습니다:
<BR>
<BR>
로드맵은 최신 데이터 엔진 **Mayastor**에만 중점을 두고 있습니다. OpenEBS LEGACY 프로젝트 또는 DEPRERCATED 또는 ARCHIVED로 태그가 지정되고 정의된 프로젝트에 대한 완전히 새로운 기능을 정의하지 않습니다. 현재 해당 프로젝트는 다음과 같이 정의됩니다(프로젝트 사용 중단 및 ARCHIVAL 전략에 대한 자세한 내용은 위 참조 참조)...
- Jiva
- cStor
- NFS-Provisioner
<BR>

**MayaStor 로드맵 : 2024 2단계**
- 앞으로 예정된 출시 날짜, 릴리스 버전 번호 및 기능 우선 순위는 프로젝트 유지 관리자/리더십/커뮤니티가 K8 산업 동향, 추세 및 커뮤니티 영향력에 대응하기 위해 **릴리스 기능 번들링 전략**을 지속적으로 업데이트하고 조정함에 따라 변경될 수 있습니다.

|  ID  | 기능 이름                   | 설명 및 사용자 스토리                                            | 릴리스, 링크, 추적 문제, GitHub 저장소                                                   |
| :--- | :----------------------------- | :--------------------------------------------------------------------- | :------------------------------------------------------------------------------------------ |
| 1    | 다중 복제본 볼륨 스냅샷 및 CSI 복제 | 볼륨의 사용 가능한 모든 복제본에서 일관된 스냅샷을 찍을 수 있습니다.                                     | Pri 1 /  Rel: (Q1 2024)    |
| 2    | 볼륨 크기 조정                                | I/O 연속성을 통해 볼륨 크기와 오버레이 파일 시스템 크기를 늘릴 수 있습니다.                                | Pri 1 /  Rel: (Q1 2024)    |
| 3    | 디스크풀 크기 조정                               | I/O 연속성을 갖춘 기본 디스크 풀 장치를 확장하여 풀 용량을 늘릴 수 있습니다.               | Pri 1 /  Rel: (Q1 2024)    |
| 4    | DiskPool 미디어 집계 관리               | 여러 물리 디스크에서 통합된 가상 디스크를 생성, 확장 및 관리할 수 있습니다.                 | Pri 1 /  Rel: (Q2 2024)    |
| 6    | Local-PV 데이터 엔진 통합 + 활성화     | non-SPDK Blobstor를 스토리지로 사용하여 LocalPV(non-replicated) 유형의 영구 볼륨을 동적으로 프로비저닝합니다.  | Pri 1 /  Rel: (Q1 2024)    |
| 6    | Local-PV 데이터 엔진 통합 + 활성화     | non-SPDK Blobstor를 스토리지로 사용하여 LocalPV(non-replicated) 유형의 영구 볼륨을 동적으로 프로비저닝합니다.  | Pri 1 /  Rel: (Q1 2024)    |
| 6.1  | Local-PV Hostpath 활성화                     | K8s 호스트 경로 주소 지정 스토리지 유형을 사용하여 Local-PV(non-replicated)의 영구 볼륨을 프로비저닝할 수 있습니다.  | Pri 2 /  Rel: (Q2 2024)    |
| 6.2  | Local-PV 디바이스 활성화                       | K8s 장치 주소 지정 스토리지 유형을 사용하여 Local-PV(non-replicated)의 영구 볼륨을 프로비저닝할 수 있습니다.    | Pri 2 /  Rel: (Q2 2024)    |
| 6.3  | Local-PV RawFile 소프트 LUN 활성화           | K8s 소프트 파일 시스템 LUN 주소 지정 스토리지 유형을 사용하여 LocalPV(non-replicated)의 영구 볼륨을 프로비저닝할 수 있습니다.    | Pri 3 /  Rel: (Q3 2024)  |
| 6.4  | Local-PV RawFile 다중 파일 시스템 지원   | Local-PV RawFile Soft luns에 대한 다중 파일 시스템 지원: ext3, ext4, XFS, BTRFS, f2fs, ZNS                    | Pri 3 /  Rel: (Q3 2024)   |
| 6.5  | NDM 통합 + 활성화                      | 모든 Local-PV 종속 서비스에 대한 NDM 지원.                                                                | Pri 2 /  Rel: (Q2 2024)   |
| 7    | HyperLocal-PV 데이터 엔진                     | 스토리지 + NVMe 대상 장치로 SPDK blobstor LVol을 통해 복제되지 않은 Local-PV 유형의 PV를 동적으로 프로비저닝합니다. |  Pri 2 /  Rel: (Q2 2024)   |
| 7.1  | HyperLocal-PV : UBlock 모드                   | SPDK blobstor LVol에 대한 UBlock 커널 통합을 통해 Local-PV 유형의 Non-replicated PV를 스토리지로 사용합니다.                   |  Pri 2 /  Rel: (Q2 2024)   |
| 7.2  | HyperLocal-PV : PCIe 모드                     | SPDK blobstor LVol에 대한 PCIe 기반 NVMe 커널 통합을 통해 Local-PV 유형의 복제되지 않은 PV를 스토리지로 사용합니다.          |  Pri 2.5 /  Rel: (Q2 2024)*   |
| 8    | GUI Mgmt 포털 & 데쉬보드                   | RESTful GUI 인터페이스를 사용하여 Mayastor 배포를 프로비저닝, 관리, 모니터링합니다. - @ parity with Shell & kubectl cmds | Pri 3 /  Rel: (Q3 2024)    |
| 8.1  | GUI Mgmt 포털 & 데쉬보드 : On-Prem         | Mgnt 포털 및 대시보드는 Air-Gapped 아키텍처를 위해 온프레미스에 비공개로 배포되었습니다.                                     | Pri 3 /  Rel: (Q3 2024)    |
| 8.2  | GUI Mgmt 포털 & 데쉬보드 : In-Cloud SaaS   | 클라우드 지원 아키텍처를 위해 클라우드 내에서 비공개로 SaaS로 배포된 Mgnt 포털 및 대시보드입니다.                        | Pri 3 /  Rel: (Q3 2024)    |
| 8.3  | GUI Mgmt 포털 & 데쉬보드 : Global view     | Mgmt 포털은 익명화된 글로벌 통계를 제공하도록 구성된 모든 k8s 클러스터의 글로벌 세계 보기를 집계했습니다.     | Pri 3 /  Rel: (Q3 2024)    |
| 9    | Storgae 암호화                            | SPDK LVol 계층을 통해 암호화된 미사용 데이터 볼륨 프로비저닝 - 다중 파일 시스템 지원(ext3, ext4, XFS, BRFS)  | Pri 3 /  Rel: (Q3 2024)    |
| 10   | Health & Supportability 메트릭스 + 데쉬보드   | OpenEBS가 관리하는 모든 요소에 대한 심층 상태 진단 보기 - 지원 번들 업로드에 지표 포함을 활성화합니다. |  Pri 2.5 /  Rel: (Q2 2024*)   |
| 11   | E2E 스토리지 UNMAP 회수 통합          | Support Discard: LINUX / UNMAP: SCSI / 할당 해제: 파일 시스템에서 SPDK Blobstor 요소까지 발행된 NVMe.    | Pri 3 /  Rel: (Q4 2024)    |
| 12   | 씬 프로비저닝 2단계                     | Thin Provision 인식 및 DiskPool 메트릭과의 통합, 선제적 인텔리전스 작업.                  | Pri 3 /  Rel: (Q4 2024)    |
| 13   | 네이티브 객체 저장소                           | SPDK LVstore/LVols Blobstor 및 HyperLocal-PV vols와 통합된 S3 호환 빠른 개체 저장소입니다.               | Pri 3 /  Rel: (Q4 2024)    |
| 14   | Zoned-SSD 지원                             | 매우 높은 성능의 볼륨을 위한 통합 Western Digital 팀의 Mayastor ZNS 기능.                             | Pri 2.5 /  Rel: (Q2 2024)   |



## 확장성

OpenEBS는 임의로 많은 수의 컨테이너화된 스토리지 컨트롤러를 포함하도록 확장할 수 있습니다. Kubernetes는 인벤토리에 etcd를 사용하는 등 기본적인 부분을 제공하는 데 사용됩니다. OpenEBS는 Kubernetes가 확장되는 만큼 확장됩니다.

## 설치 및 시작하기

OpenEBS는 몇 가지 간단한 단계를 거쳐 설정할 수 있습니다. Kubernetes 노드에 open-iscsi를 설치하고 kubectl을 사용하여 openebs-operator를 실행하면 원하는 Kubernetes 클러스터를 선택할 수 있습니다.

**Operator를 이용하여 OpenEBS 서비스 시작**
```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Helm을 이용하여 OpenEBS 서비스 시작**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

[빠른 시작 가이드](https://openebs.io/docs)를 참조할 수 있습니다.

OpenEBS는 클라우드, 온프레미스 또는 개발자 노트북(minikube) 등 모든 Kubernetes 클러스터에 배포할 수 있습니다. OpenEBS가 사용자 공간에서 작동할 때 필요한 기본 커널에는 변경 사항이 없습니다. [OpenEBS 설정](https://openebs.io/docs/user-guides/quickstart) 설명서를 따르세요.

## Status

OpenEBS는 업계에서 가장 널리 사용되고 테스트된 Kubernetes 스토리지 인프라 중 하나입니다. 2019년 5월 이후 CNCF 샌드박스 프로젝트인 OpenEBS는 온프레미스 시스템과 클라우드 시스템 모두에서 여러 백엔드(로컬, nfs, zfs, nvme)에서 일관된 소프트웨어 정의 스토리지 기능 세트를 제공하는 최초이자 유일한 스토리지 시스템입니다. 상태 저장 워크로드를 위한 자체 Chaos 엔지니어링 프레임워크인 [Litmus 프로젝트](https://litmuschaos.io)를 최초로 오픈 소스로 제공했습니다. 이 프레임워크는 커뮤니티에서 OpenEBS 버전의 월간 주기를 자동으로 평가할 준비가 되어 있는 데 사용됩니다. 기업 고객은 2018년부터 프로덕션 환경에서 OpenEBS를 사용해 왔습니다.

OpenEBS 영구 볼륨을 구동하는 다양한 스토리지 엔진의 상태는 아래에 제공됩니다. 상태 간의 주요 차이점은 다음과 같습니다:
- **alpha:** API는 이후 소프트웨어 릴리스에서 예고 없이 호환되지 않는 방식으로 변경될 수 있으며, 버그 위험 증가와 장기 지원 부족으로 인해 단기 테스트 클러스터에서만 사용하는 것이 좋습니다.
- **beta**: 세부 사항은 변경될 수 있지만 전체 기능에 대한 지원은 중단되지 않습니다. 버전 간 업그레이드 또는 마이그레이션에 대한 지원은 자동화 또는 수동 단계를 통해 제공됩니다.
- **stable**: 기능은 많은 후속 버전에 대해 출시된 소프트웨어에 표시되며 버전 간 업그레이드에 대한 지원은 대부분의 시나리오에서 소프트웨어 자동화를 통해 제공됩니다.

| Storage Engine | Status | Details |
|---|---|---|
| Jiva | stable | Kubernetes 작업자 노드의 임시 스토리지를 사용하는 노드에서 복제 블록 스토리지를 실행하는 데 가장 적합합니다. |
| cStor | stable | 블록 장치가 있는 노드에서 실행하기 위한 기본 옵션입니다. 스냅샷 및 클론이 필요한 경우 권장되는 옵션입니다. |
| Local Volumes | stable | 지연 시간이 짧은 스토리지(Kubernetes 노드에서 직접 연결된 스토리지)가 필요한 분산 애플리케이션에 가장 적합합니다. |
| Mayastor | stable | 네이티브에 가까운 NVMe 성능과 고급 데이터 서비스를 갖춘 Kubernetes용 영구 스토리지 솔루션입니다. |

자세한 내용은 [OpenEBS 설명서](https://openebs.io/docs/)를 참조하세요.

## 기여하기

OpenEBS는 가능한 모든 형태의 피드백과 기여를 환영합니다.

- [Kubernetes Slack에서 OpenEBS 커뮤니티에 참여하세요.](https://kubernetes.slack.com)
  - 이미 가입하셨나요? [#openebs]에서 토론을 진행하세요.(https://kubernetes.slack.com/messages/openebs/)
- 이슈를 제기하거나 수정 사항 및 기능에 대한 도움을 원하십니까?
  - 다음을 참조하세요. [open issues](https://github.com/openebs/openebs/issues)
  - 다음을 참조하세요. [기여 가이드](./CONTRIBUTING.md)
  - 기여자 커뮤니티 미팅을 원하면 다음을 참조하세요.[check this out](./community/README.md).
- OpenEBS CNCF 메일링 리스트에 가입하세요.
  - OpenEBS 프로젝트 업데이트를 받으려면 [OpenEBS 공지사항](https://lists.cncf.io/g/cncf-openebs-announcements)을 구독하세요.
  - 다른 OpenEBS 사용자와 소통하려면 [OpenEBS 사용자](https://lists.cncf.io/g/cncf-openebs-users)를 구독하세요.

## Show me the Code

OpenEBS용 메타 저장소입니다. 고정된 리포지토리 또는 [OpenEBS 아키텍처](./contribute/design/README.md) 문서로 시작하세요.

## License

OpenEBS는 프로젝트 수준에서 [Apache License 2.0](https://github.com/openebs/openebs/blob/master/LICENSE) 라이선스에 따라 개발되었습니다. 프로젝트의 일부 구성 요소는 다른 오픈 소스 프로젝트에서 파생되었으며 해당 라이선스에 따라 배포됩니다.

OpenEBS는 CNCF 프로젝트의 일부입니다.

[![CNCF Sandbox Project](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)](https://landscape.cncf.io/selected=open-ebs)

## 상업용 제품

OpenEBS와 관련된 제품이나 서비스를 제공하는 제3자 회사 및 개인의 목록입니다. OpenEBS는 어떤 회사도 보증하지 않는 CNCF 프로젝트입니다. 목록은 알파벳순으로 제공됩니다.
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [DataCore](https://www.datacore.com/support/openebs/)
- [Gridworkz Cloud Services](https://gridworkz.com/)
