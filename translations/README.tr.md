# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**OpenEBS**, kritik işlevli, verileri kalıcı olan ve örneğin günlük oluşturma (logging) veya Prometheus gibi uygulamaların depolama ihtiyaçlarını karşılamak için kullanılır. OpenEBS konteyner depolama ve ilgili veri depolama hizmetlerini sunar.
 
**OpenEBS**, örneğin konteynerler içerisinde çalışan veritabanları gibi kalıcı uygulama konteynarlarını adeta diğer konteynerlar gibi kullanmanızı sağlar. Diğer mevcut kurumsal depolama çözümlerinden farklı olarak OpenEBS'in kendisi de sunucunuzda konteynerlar aracılığıyla dağıtılır. OpenEBS depolama servisleri bir pod, uygulama (application), cluster veya konteyner düzeyinde atanabilecek depolama hizmetlerini etkinleştirir:
- Sunucular arası veri kalıcılığı, örneğin Cassandra halkalarının yeniden inşası için harcanan zamanı önemli ölçüde azaltır.
- Bulut üzerinde kullanılabilirlik bölgeleri (Availability Zone) ve bulut sağlayıcıları arasında verilerin kullanılabilirliğini iyileştirmesi ve örneğin ekleme / çıkarma zamanlarını azaltma.
- Ortak bir API tabanı oluşturur. İster AKS, ister direkt olarak sunucu üzerinde veya GKE ya da AWS'de çalışıyor olsanız dahi, yazılım geliştirici deneyiminin mümkün olduğunca benzer olmasını sağlar. Bu sayede farklı platformlar üzerinde hiçbir değişiklik yapmaksınız çalışmanızı sağlar.
- Kubernetes ile entegredir. Geliştirici ve uygulamanın talepleri otomatik olarak OpenEBS konfigürasyonlarına aktarılır.
- S3 ve diğer depolama hedeflerinin yönetimini kolaylaştırır.

**Vizyonumuz** gayet basit: Verileri kalıcı olan uygulamalar için depolama ve depolama hizmetlerinin konteyner ekosistemine tamamen entegre olmasını sağlamak. Böylelikle her uygulama geliştirici ekibi granüler yönetim ve Kubernetes'e özgü davranışlardan yararlanır.

#### *Bu dosyayı [diğer dillerde](/translations#readme) oku.*

## Ölçeklenebilirlik
 
OpenEBS, isteğe bağlı olarak çok sayıda konteyner depolama denetleyicisi içerecek şekilde ölçeklendirilebilir. Kubernetes, envanter için etcd'nin kullanımı gibi temel bileşenlerden yararlanmak için kullanılır. OpenEBS, Kubernetes'in ölçeklenebileceği ölçüde ölçeklendirir.

## Kurulum ve Başlangıç
 
OpenEBS birkaç kolay adımda kurulabilir. Kubernetes kümenizde (cluster) open-iscsi paketlerini yükledikten sonra kubectl kullanarak openebs-operator hizmetini başlatabilirsiniz.

**Operatör kullanarak OpenEBS hizmetlerini başlatınız**

```bash
# bu yaml'ı uygulayın
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**OpenEBS servislerini Helm ile başlatın**

```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

Ayrıca [Hızlı Başlangıç ​​Kılavuzu](https://docs.openebs.io/docs/overview.html)'nu da takip edebilirsiniz.

OpenEBS, kurumsal bulut, şirket içi veya geliştirici dizüstü bilgisayarı (minikube) gibi herhangi bir Kubernetes kümesine (cluster) kurulabilir. OpenEBS kullanıcı alanında (userspace) çalıştığı için kernel diye de bilinen Linux çekirdeğinde hiçbir değişiklik gerektirmez. Lütfen [OpenEBS Kurulumu](https://docs.openebs.io/docs/overview.html) dokümantasyonumuzu takip edin. Ayrıca, OpenEBS'in performansını simüle etmek için kullanabileceğiniz örnek bir Kubernetes dağıtımı ve sentetik yük içeren bir Vagrant kurulumu da mevcut. Ayrıca, Kubernetes'teki kalıcı veri gerektiren uygulamalar için kaos mühendisliği ile yardımcı olan [Litmus](https://litmuschaos.io/) adlı ilgili projeyi de ilginç bulabilirsiniz.

## Durum

OpenEBS en çok kullanılan ve test edilmiş Kubernetes depolama altyapılarından bir tanesi. Kurumsal müşterilerimiz OpenEBS'i 2018'den beri üretimde kullanıyor ve projemiz haftada 2.5 milyondan fazla Docker pull işlemlerini destekliyor.

Projemizin güncel durumu hakkında daha fazla bilgi için [Project Tracker](https://github.com/openebs/openebs/wiki/Project-Tracker)'a bakınız.
 
## Katkı
 
OpenEBS, her açık kaynak kodlu uygulama gibi kullanıcı katılarıyla güçlenen bir projedir. Yorumlarınızlardan ve katkılarınızdan minnettarız.
 
- [Slack üzerinden topluluğumuza katılın](https://kubernetes.slack.com).
  - Eğer kayıtlıysanız tartışmalarımıza [#openebs](https://kubernetes.slack.com/messages/openebs/) kanalından ulaşabilirsiniz.
- Bir sorunu bildirmek ister misiniz?
  - Eğer çözüm bulamadığınız bir sorununuz varsa, bunu  [sorunlar](https://github.com/openebs/openebs/issues) altında rapor edebilirsiniz.
  - Proje (repo) ile ilgili belirli konular ayrıca [sorunlar](https://github.com/openebs/openebs/issues) ve *repo/maya* gibi tek tek etiketlerle etiketlenebilir.
- Düzeltmeler ve özellikler konusunda yardımcı olmak ister misiniz?
  - Bkz. [Açık sorunlar](https://github.com/openebs/openebs/labels)
  - Bkz. [Katkıda bulunma rehber](/CONTRIBUTING.md)
  - Topluluğumuza katılmak isterseniz, [buraya bakınız](/community/README.md).

## Bana kodu göster

Kaynak kodlarını aşağıdaki yerlerde bulabilirsiniz:
- İlk depolama motorunun kaynak kodu [openebs/jiva](https://github.com/openebs/jiva) altındadır.
- Depolama orkestrasyon kaynak kodu [openebs/maya](https://github.com/openebs/maya) altındadır.
- *jiva* ve *maya* önemli miktarda kaynak kodu içeriyor olsa da, bazı orkestrasyon ve otomasyon kodları OpenEBS organizasyonu altında diğer depolarda da dağıtılır.

Lütfen yukarıdaki repolarla veya [OpenEBS Architecture](/contribute/design/README.md) dosyasından başlayın.

## Lisans

OpenEBS, proje düzeyinde Apache 2.0 lisansı altında geliştirilmiştir.
Projenin bazı bileşenleri diğer açık kaynak projelerinden türetilmiştir ve ilgili lisansları altında dağıtılmaktadır.
