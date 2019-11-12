## OpenEBS'ye katkıda bulunmak

Harika!! Her zaman daha fazla OpenEBS korsanının peşindeyiz. Bunu okuyarak başlayabilirsiniz [genel bakış](../contribute/design/README.md).

Öncelikle, eğer bir şeyden emin değilseniz veya korkuyorsanız, sadece soru sorun veya istek gönderin veya çekme isteğinde bulunun. En iyi çabanı verdiğiniz için bağırılmayacaksınız. Olabilecek en kötü şey, bir şeyi değiştirmeniz istenecektir. Her türlü katkıyı takdir ediyoruz.

Ancak, projeye katkıda bulunmanın en iyi yolu hakkında biraz daha fazla rehberlik isteyen kişiler için okumaya devam edin. Bu belge, katkılarınızda aradığımız tüm noktaları kapsayacak ve katkılarınızı hızlı bir şekilde birleştirme veya adresleme şansınızı artıracaktır.

Bununla birlikte, OpenEBS Açık Kaynakta bir yazılımdır. Herhangi bir şekilde katkıda bulunabilirsiniz ve sağlanan tüm yardımlar takdir edilmektedir.

- [Yeni işlevsellik istemek, belgeleri düzeltmek veya hataları bildirmek için sorunları yükseltin.](#sorunları-yükseltme)
- [Belgeleri iyileştirmek için değişiklikleri gönderin.](#belgeleri-geliştirmek-için-değişiklik-gönder) 
- [Yeni özellikler / geliştirmeler için teklifler gönderin.](#yeni-özellikler-için-öneriler-gönderin)
- [Belgeleme veya kod ile ilgili mevcut sorunları çözün.](#kaynak-kod-ve-hata-düzeltmelerine-katkı-sağlamak)

Hack'lerinizi vermeden önce izlemeniz gereken birkaç basit yönerge vardır.

## Sorunları Yükseltme

Sorunları yükselttiğinizde lütfen şunları belirtin:
- Denetleme ayrıntıları, gözden geçirenin kontrol etmesi için konu şablonunda açıkça belirtildiği gibi doldurulmalıdır.
- Sorunun oluştuğu senaryo (nasıl yeniden üretileceği ile ilgili ayrıntılar).
- Yazılım tarafından görüntülenen hatalar ve günlük mesajları.
- Faydalı olabilecek diğer tüm detaylar.

## Belgeleri Geliştirmek İçin Değişiklik Gönder

Doğru belgelerin alınması zor! Buna bakın [sayfa](../contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) çekme etiketlerini uygun etiketlerle göndererek geliştirici belgelerini nasıl geliştirebileceğiniz hakkında daha fazla bilgi için. İşte bir [etiket listesi](../contribute/labels-of-issues.md)  aynı şekilde kullanılabilir. Dokümanlarımızı temiz, kolay anlaşılır ve erişilebilir tutmak için bize yardımcı olun.

## Yeni Özellikler için Öneriler Gönderin

Kullanım durumlarınıza uymayı kolaylaştırmak için her zaman gereken daha çok şey vardır. Yeni özelliklerle ilgili tartışmaya katılmaktan çekinmeyin veya önerilen değişikliğinizle birlikte bir PR çekin.

- [Bizim katılın topluluk](https://openebs.org/community)
 	 - Zaten kayıtlı mısınız? Tartışmalarımıza yönelin [#openebs-users](https://openebs-community.slack.com/messages/openebs-users/)

## Kaynak Kod ve Hata Düzeltmelerine Katkı Sağlamak

PR'leri hata düzeltmeleri veya kaynak kodundaki geliştirmeler için uygun etiketlerle sağlayın. Kullanılabilecek etiketlerin listesi için, [bkz.](../contribute/labels-of-issues.md).

* K8s demosuna katkıda bulunmak için lütfen bu [belge] bölümüne bakınız.(../contribute/CONTRIBUTING-TO-K8S-DEMO.md).
	- OpenEBS'in K8'lerle nasıl çalıştığını kontrol etmek için, bu belge bölümüne [bakın.](../k8s/README.md) 
- Kubernetes OpenEBS Provisioner'a katkıda bulunmak için lütfen bu dokümana [bakınız.](../contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).
	
Kod yapılandırması ve takip edilecek yönergeler hakkında daha fazla bilgi için bu belge bölümüne [bakın.](../contribute/design/code-structuring.md) 

## Mevcut Sorunları Çözme

Katkıda bulunanlardan yardıma ihtiyaç duyulan sorunları bulmak için [sorunlar](https://github.com/openebs/openebs/issues) 'a gidin. Daha hızlı çözebileceğiniz sorunları bulmanıza yardımcı olmak için [etiketler listesi](../contribute/labels-of-issues.md) bölümüne bakın.

Katkıda bulunmayı düşünen bir kişi, bir yorum olarak Github ID'sini atayarak / talep ederek bir soruyu ele alabilir. Söz konusu konuyla ilgili bir haftalık bir PR ya da güncelleme yapılmadığı takdirde, konu yeniden herkesin tekrar açılmasını talep ediyor. Yanıt süresinin bir gün veya daha uzun olması gereken yüksek öncelikli sorunları / regresyonları dikkate almamız gerekiyor.

---
### İşini imzala

OpenEBS projesi için ek bir koruma olarak, Menşe Geliştirici Belgesini (DCO) kullanıyoruz. Bu, katkıda bulunanların projenin lisansı kapsamında katkılarını lisanslama haklarını onaylamasını sağlamak için iyi kurulmuş ve yaygın bir mekanizmadır. Lütfen okuyun [geliştirici-sertifikası](../contribute/developer-certificate-of-origin).

Onaylayabilirseniz, her git taahhüt mesajına bir satır ekleyin:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
  ````
taahhütleriniz üzerinde oturum açmak için. komutu kullan `git commit -s -m "commit message comes here"`

Gerçek adınızı kullanın (üzgünüm, takma adlar veya anonim katkılar yok). `User.name` ve` user.email` git yapılandırmalarınızı ayarlarsanız, `git commit -s` ile işleminizi otomatik olarak imzalayabilirsiniz. Git [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) 'ı da kullanabilirsiniz.  `git config --global alias.ci 'commit -s'`. Şimdi `git ci` ile taahhütte bulunabilirsiniz ve taahhüt imzalanacaktır.


## Topluluğumuza Katılın

OpenEBS topluluğunda aktif olarak geliştirmek ve katkıda bulunmak istiyorsanız, bu [dokümana](../community/README.md) başvurun.
