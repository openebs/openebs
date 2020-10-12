# OpenEBS

[![Wersje](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![Przyjmujemy PR](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![Status FOSSA](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![Najlepsze praktyki CII](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**Przeczytaj ten dokument w [innym języku](/translations#readme).**

**OpenEBS** to najczęściej wdrażane i najłatwiejsze w obsłudze rozwiązanie pamięci masowej typu open-source dla platformy Kubernetes.

**OpenEBS** to wiodący przykład oprogramowania kategorii open-source do przechowywania danych, czasami nazywanych [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). **OpenEBS** jest wymieniony jako przykład oprogramowania typu open-source w [dokumencie White Paper CNCF Storage Landscape](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) w ramach hiperkonwergentnych rozwiązań pamięci masowej.

Niektóre kluczowe aspekty, które odróżniają OpenEBS od innych tradycyjnych rozwiązań pamięci masowej:
- Zbudowany przy użyciu architektury mikrousług, podobnie jak aplikacje, które obsługuje. Sam OpenEBS jest wdrażany jako zestaw kontenerów w węzłach roboczych Kubernetes. Używa samego Kubernetes do organizowania i zarządzania komponentami OpenEBS
- Zbudowany całkowicie w przestrzeni użytkownika, dzięki czemu jest wysoce przenośny do pracy na dowolnym systemie operacyjnym/platformie
- Całkowicie oparty na zamysłach, dziedziczący te same zasady, które zapewniają łatwość użytkowania z Kubernetes
- OpenEBS obsługuje szereg silników pamięci masowej, dzięki czemu programiści mogą wdrażać technologię pamięci masowej odpowiednią do celów projektu aplikacji. Aplikacje rozproszone, takie jak Cassandra, mogą używać silnika LocalPV w celu uzyskania najniższych opóźnień w zapisach. Aplikacje monolityczne, takie jak MySQL i PostgreSQL, mogą używać silnika ZFS (cStor) w celu zapewnienia odporności. Aplikacje do przesyłania strumieniowego, takie jak Kafka, mogą korzystać z silnika NVMe [Mayastor](https://github.com/openebs/Mayastor) w celu uzyskania najlepszej wydajności w środowiskach brzegowych. We wszystkich typach silników OpenEBS zapewnia spójną strukturę zapewniającą wysoką dostępność, migawki, klony i łatwość zarządzania.

Sam OpenEBS jest wdrażany jako kolejny kontener na twoim hoście i umożliwia usługi pamięci masowej, które można wyznaczyć na poziomie poda, aplikacji, klastra lub kontenera, w tym:
- Zautomatyzuj zarządzanie pamięcią masową podłączoną do węzłów roboczych Kubernetes i pozwól, aby pamięć masowa była używana do dynamicznego udostępniania PV OpenEBS lub lokalnych PV.
- Trwałość danych w węzłach, radykalnie skracająca czas poświęcony na przykład na odbudowę pierścieni Cassandry.
- Synchronizacja danych między strefami dostępności i dostawcami usług w chmurze, poprawiająca dostępność i skracająca na przykład czasy dołączania/odłączania.
- Wspólna warstwa, więc niezależnie od tego, czy korzystasz z AKS, czy na komputerze, GKE czy AWS - Twoje okablowanie i doświadczenie programisty w zakresie usług pamięci masowej jest jak najbardziej podobne.
- Zarządzanie ustalaniem poziomów do i z S3 i innych celów.

Dodatkową zaletą bycia całkowicie natywnym rozwiązaniem Kubernetes jest to, że administratorzy i programiści mogą wchodzić w interakcje i zarządzać OpenEBS przy użyciu wszystkich wspaniałych narzędzi dostępnych dla Kubernetes, takich jak kubectl, Helm, Prometheus, Grafana, Weave Scope itp.

**Nasza wizja** jest prosta: niech usługi pamięci masowej i pamięci masowej dla trwałych obciążeń zostaną w pełni zintegrowane ze środowiskiem, tak aby każdy zespół i obciążenie skorzystały na szczegółowości kontroli i natywnym zachowaniu Kubernetes.

## Skalowalność

OpenEBS można skalować tak, aby obejmował dowolnie dużą liczbę kontrolerów pamięci masowej w kontenerach. Kubernetes służy do dostarczania podstawowych elementów, takich jak używanie etcd do inwentaryzacji. OpenEBS skaluje się w stopniu, w jakim skaluje się Twój Kubernetes.

## Instalacja i rozpoczęcie pracy

OpenEBS można skonfigurować w kilku prostych krokach. Możesz rozpocząć wybór klastra Kubernetes, instalując open-iscsi w węzłach Kubernetes i uruchamiając operatora openebs za pomocą kubectl.

**Uruchom usługi OpenEBS za pomocą operatora**
``` bash
# zastosuj ten yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Uruchom usługi OpenEBS przy użyciu programu Helm**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

Możesz również skorzystać z naszego [Przewodnika szybkiego startu](https://docs.openebs.io/docs/overview.html).

OpenEBS można wdrożyć w dowolnym klastrze Kubernetes - w chmurze, lokalnie lub na laptopie programisty (minikube). Zauważ, że nie ma żadnych zmian w bazowym jądrze, które są wymagane, ponieważ OpenEBS działa w przestrzeni użytkownika. Skorzystaj z naszej dokumentacji [Instalacja OpenEBS](https://docs.openebs.io/docs/overview.html). Mamy również dostępne środowisko Vagrant, które zawiera przykładowe wdrożenie Kubernetes i syntetyczne obciążenie, którego można użyć do symulacji wydajności OpenEBS. Możesz również znaleźć interesujący powiązany projekt o nazwie [Litmus](https://litmuschaos.io), który pomaga w inżynierii chaosu dla obciążeń stanowych na Kubernetes.

## Status

OpenEBS to jedna z najczęściej używanych i przetestowanych infrastruktur pamięci masowej Kubernetes w branży. OpenEBS to projekt CNCF Sandbox od maja 2019 r., Który jest pierwszym i jedynym systemem pamięci masowej, który zapewnia spójny zestaw definiowanych programowo funkcji pamięci masowej na wielu backendach (lokalnych, nfs, zfs, nvme) zarówno w systemach lokalnych, jak i chmurowych. [Litmus Project](https://litmuschaos.io), który jako pierwszy otworzył swoje własne Chaos Engineering Framework dla Stateful Workloads, na którym społeczność polega na automatycznej ocenie gotowości do oceny miesięcznej kadencji wersji OpenEBS. Klienci korporacyjni używają OpenEBS na środowiskach produkcyjnych od 2018 roku, a projekt obsługuje ponad 2,5 miliona pobrań docker w tygodniu.

Poniżej przedstawiono stan różnych silników pamięci masowej, które zasilają trwałe woluminy OpenEBS. Najważniejsze różnice między statusami podsumowano poniżej:
- **alpha:** API może ulec zmianie w niekompatybilny sposób w późniejszej wersji oprogramowania bez powiadomienia, zalecane do użytku tylko w krótkotrwałych klastrach testowych, ze względu na zwiększone ryzyko błędów i brak długoterminowego wsparcia.
- **beta**: wsparcie dla ogólnych funkcji nie zostanie porzucone, chociaż szczegóły mogą ulec zmianie. Zapewniona zostanie obsługa aktualizacji lub migracji między wersjami, za pomocą automatyzacji lub ręcznych kroków.
- **stabilny**: funkcje pojawią się w wydanym oprogramowaniu dla wielu kolejnych wersji, a obsługa uaktualniania między wersjami zostanie zapewniona wraz z automatyzacją oprogramowania w większości scenariuszy.


| Silnik pamięci masowej | Status | Szczegóły |
| --- | --- | --- |
| Jiva | stabilny | Najlepiej nadaje się do uruchamiania replikowanej pamięci blokowej w węzłach, które korzystają z pamięci tymczasowej w węzłach roboczych Kubernetes |
| cStor | beta | Preferowana opcja do uruchamiania na węzłach z urządzeniami blokowymi. Zalecana opcja, jeśli wymagane są migawki i klony |
| Woluminy lokalne | beta | Najlepiej nadaje się do aplikacji rozproszonych, które wymagają magazynowania o małych opóźnieniach - pamięci masowej podłączanej bezpośrednio z węzłów Kubernetes. |
| Burmistrz | alfa | Nowy silnik pamięci masowej, który działa z wydajnością pamięci lokalnej, ale oferuje również usługi pamięci masowej, takie jak replikacja. Trwają prace nad obsługą migawek i klonów. |

Więcej informacji można znaleźć w [Dokumentacji OpenEBS](https://docs.openebs.io/docs/next/quickstart.html).

## Współtworzenie

OpenEBS z radością przyjmuje Twoje opinie i wkład w każdej możliwej formie.

- [Dołącz do społeczności OpenEBS na Kubernetes Slack](https://kubernetes.slack.com)
  - Już się zapisałeś? Przejdź do naszych dyskusji pod adresem [#openebs](https://kubernetes.slack.com/messages/openebs/)
- Chcesz zgłosić problem lub pomóc w poprawkach i funkcjach?
  - Zobacz [otwarte problemy](https://github.com/openebs/openebs/issues)
  - Zobacz [przewodnik dla współtwórców](./CONTRIBUTING.pl.md)
  - Chcesz dołączyć do naszych spotkań społeczności współpracowników, [sprawdź to](./community/README.md).
- Dołącz do naszych list mailingowych OpenEBS CNCF
  - Aby otrzymywać aktualizacje projektów OpenEBS, zasubskrybuj [OpenEBS Announcements](https://lists.cncf.io/g/cncf-openebs-announcements)
  - Aby współpracować z innymi użytkownikami OpenEBS, zasubskrybuj [Użytkownicy OpenEBS](https://lists.cncf.io/g/cncf-openebs-users)

## Pokaż mi kod

To jest meta-repozytorium OpenEBS. Zacznij od przypiętych repozytoriów lub dokumentu [Architektura OpenEBS](./contrib/design/README.md).

## Licencja

OpenEBS jest rozwijany na licencji [Apache License 2.0](https://github.com/openebs/openebs/blob/master/LICENSE) na poziomie projektu. Niektóre komponenty projektu pochodzą z innych projektów open source i są rozpowszechniane na ich odpowiednich licencjach.

OpenEBS jest częścią projektów CNCF.

[![Projekt CNCF Sandbox](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)](https://landscape.cncf.io/selected=open-ebs)


## Oferty komercyjne

To jest lista firm zewnętrznych i osób, które dostarczają produkty lub usługi związane z OpenEBS. OpenEBS to projekt CNCF, który nie promuje żadnej firmy. Lista jest podana w kolejności alfabetycznej.
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [Gridworkz Cloud Services](https://gridworkz.com/)
- [MayaData](https://mayadata.io/)