# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**Read this in**
[🇩🇪](translations/README.de.md)
[🇷🇺](translations/README.ru.md)
[🇹🇷](translations/README.tr.md)
[🇺🇦](translations/README.ua.md)
[🇨🇳](translations/README.zh.md)
[🇫🇷](translations/README.fr.md)
[id](translations/README.id.md)
**[other languages](translations/#readme).**

**OpenEBS** adalah penyimpanan _open-source_ yang paling mudah dan banyak digunakan untuk solusi penyimpanan _Kubernetes_

**OpenEBS** memimpin dalam kategori _open-source example of storage solutions_ yang biasa dikenal dengan [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). **OpenEBS** juga terdaftar sebagai _open-source example_ dalam [CNCF Storage Landscape White Paper](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) dibawah _the hyperconverged storage solutions_.

Beberapa aspek utama yang membuat OpenEBS berbeda dari solusi penyimpanan tradisional lainnya sebagai berikut :

- Dibuat menggunakan arsitektur _micro-services_ yang umum digunakan. OpenEBS sendiri dibangun dari beberapa _containers_ di Kubertas itu sendiri.
- Dibangun disisi pengguna sehingga sangat simpel di gunakan di berbagai _OS/Platform_.
- Sepenuhnya di buat untuk memudahakan pengguna dalam menerapkan prinsip dari penggunaan Kubernetes.
- OpenEBS mendukung banyak _storage engine_ sehingga pengembang dapat menerapkan teknologi penyimpanan apapun pada desain aplikasi yang mereka buat. Aplikasi distribusi seperti Cassandra dapat menggunakan _LocalPV engine_ untuk penulisan latensi yang rendah. Aplikasi monolitik seperti _MYSQL_ dan _PostgreSQL_ dapat menggunakan _ZFS engine (cStor)_ untuk pengoptimalan. Aplikasi _streaming_ seperti Kafka dapat menggunakan _NVMe engine [Mayastor](https://github.com/openebs/Mayastor)_ untuk pengembangan performa yang lebih baik. Dan tipe _engine_ lainya, OpenEBS menjadi _framework_ pilihan yang sangat cocok untuk _high availability, snapshots, clones_ dan _manageability._

OpenEBS itu sendiri di terapkan sebagai sebuah _container_ didalam _host_ dan digunakan sebagai _storage services_ yang dapat didesain pada setiap pod, aplikasi, cluster, atau _container level_ termasuk :

- Otomatisasi manajemen penyimpanan _Kubernetes worker nodes_ dan memungkinkan penyimpanan digunakan untuk penyimpanan dinamis OpenEBS PVs atau Local PVs.
- Persistensi data di seluruh node, secara dramatis mengurangi waktu yang dihabiskan untuk membangun kembali _Cassandra rings_, misalnya.
- Singkronisasi data dapat digunakan di seluruh zona dan penyedia _cloud_.
- Layanan yang umum, sehingga dimanapun anda menggunakannya AKS, _your bare metal_, GKE, atau AWS - kalian dapat menyambungkanya dan pelamanan kalian dalam membauat sebuah _storage services_ dapat digunakan dengan baik.
- Tingkat managemen S3 dan target lainya.

Kelebihan lainya yang dimiliki _Kubernetes native_ adalah administrasi dan pengembangan yang interaktif dan mudah di kelola, OpenESB mengimplementasikan seluruh teknologi tersebut seperti _kubectl, Helm, Prometheus, Grafana, Weave Scope, etc._

**Visi Kami** sangat sederhana. membuat penyimpanan dan layanan penyimpanan terintegrasi secara penuh dalam pengembanganya, sehingga setiap tim dan layanan penyimpanan mendapatkan _benefit_ yang sesuai dan terkontrol didalam pengembangan _Kubernetes native_.

## Scalability

OpenEBS dapat mengukur berapa banyak _container_ dalam kontrol penyimpanan. Kubernetes menggunakan beberapa _library_ seperti etcd untuk penyimpanan. OpenEBS mengukur sejauh mana Kubernetes anda dapat mengukurnya.

## Panduan Penggunaan dan Installasi

OpenEBS dapat di _set up_ dengan beberapa cara yang mudah. Anda dapat menggunakan _kubernetes cluster_ dengan memasang _open-iscsi_ pada _Kubernetes nodes_ dan menjalankan _openebs-operator_ menggunakan _kubectl_, sebagai berikut.

**Install OpenEBS Service menggunakan Operator**

```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Install OpenEBS Service menggunakan helm**

```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

Untuk Panduan lebih lengkap bisa di lihat pada _[QuickStart Guide](https://docs.openebs.io/docs/overview.html)_.

OpenEBS dapat di _deploy_ pada _Kubernete cluster_ manapun -kecuali pada _cloud_, di PC ataupun laptop (minikube).Perhatikan bahwa tidak ada perubahan pada kernel pokok yang diperlukan karena OpenEBS beroperasi di ruang pengguna. Untuk lebih jelas dapat di lihat pada panduan penggunaan di [OpenEBS Setup](https://docs.openebs.io/docs/overview.html). Selain itu kami memiliki _Vagrant environment_ yang menyedikaan sampel _kubernetes deployment_ dan _syntetic load_ yang dapat di gunakan untuk simulasi performa dari OpenEBS. Anda dapat melihat project yang telah menggunakan OpenEBS yang bernama Litmus (https://litmuschaos.io) yang dapat membantu kalian dalam menganalisa beban kerja dari _stateful on Kubernetes_.

## Status

OpenEBS adalah salah satu infrastruktur penyimpanan Kubernetes yang paling banyak digunakan dan teruji di industri. Proyek CNCF Sandbox sejak Mei 2019, OpenEBS adalah aplikasi sistem penyimpanan pertama dan satu-satunya yang menyediakan serangkaian kemampuan penyimpanan yang konsiten-kemampuan penyimpanan yang ditentukan pada beberapa backend (local, nfs, zfs, nvme) baik secara lokal ataupun _cloud system_, dan _open-source_ pertama yang memiliki _Chaos Engineering Framework_ untuk _Stateful Workloads_, dengan [Litmus Project](https://litmuschaos.io), komunitas dapat secara otomatis mengetahui perkembangan bulanan dari versi OpenEBS. Pelanggan perusahaan telah menggunakan OpenEBS dalam produksi sejak 2018 dan proyek ini mendukung lebih dari 2,5 juta docker pull per minggu.

The status of various storage engines that power the OpenEBS Persistent Volumes are provided below. The key difference between the statuses are summarized below:

Status dari berbagai _storage engine_ yang dikeluarkan OpenEBS dapat dilihat dibawah ini. Perbedaan utama antar status dirangkum dibawah ini:

- **alpha:** API dapat berubah kapanpun didalam aplikasi tanpa pemberitahuan terlebih dahulu, disarankan digunakan untuk pengembangan dan pengujian, demi menghindari bertambahnya _bugs_ dan pemutusan dukungan jangka panjang.
- **beta**: Dukungan untuk keseluruhan fitur tidak akan dihentikan, meskipun detailnya dapat berubah. Dukungan untuk peningkatan atau migrasi antar versi akan diberikan, baik melalui otomatisasi atau langkah manual.
- **stable**: Fitur yang akan di rilis pada _software_ didalam banyak versi dan peningkatan setiap versi akan dilakukan secara otomatis pada setiap perangkat.

| Storage Engine | Status | Details                                                                                                                                                                                                  |
| -------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Jiva           | stable | Paket cocok digunakan pada _Replicated Block Storage_ di _nodes_ yang menggunakan ephemeral _storage_ pada pengguna Kubernetes                                                                           |
| cStor          | beta   | Salah satu pilihan yang dapad digunakan untuk nodes yang memiliki _Block Devices_. Rekomendasi tambahan, Snapshot dan Clones dibutuhkan                                                                  |
| Local Volumes  | beta   | Paket yang cocok digunakan pada Aplikasi Distribsi yang membutuhkan latensi rendah pada penyimpanan - _direct-attached storage from the Kubernetes nodes_.                                               |
| Mayastor       | alpha  | _Storage engine_ baru yang dapat beroperasi efisien didalam penyimpanan lokal namun tetap menggunakan layanan penyimpanan seperti _Replication_. Sedang dikembangkan untuk mendukung Snapshot dan Clone. |

Untuk lebih detail, dapat di lihat pada [OpenEBS Documentation](https://docs.openebs.io/docs/next/quickstart.html).

## Contributing

OpenEBS terbuka untuk _feedback_ dan kontribusi di form manapun.

- [Join OpenEBS community on Kubernetes Slack](https://kubernetes.slack.com)
  - Already signed up? Head to our discussions at [#openebs](https://kubernetes.slack.com/messages/openebs/)
- Want to raise an issue or help with fixes and features?
  - See [open issues](https://github.com/openebs/openebs/issues)
  - See [contributing guide](./CONTRIBUTING.md)
  - Want to join our contributor community meetings, [check this out](./community/README.md).
- Join our OpenEBS CNCF Mailing lists
  - For OpenEBS project updates, subscribe to [OpenEBS Announcements](https://lists.cncf.io/g/cncf-openebs-announcements)
  - For interacting with other OpenEBS users, subscribe to [OpenEBS Users](https://lists.cncf.io/g/cncf-openebs-users)

## Ayo Bergabung

Ini adalah meta-repository untuk OpenEBS. Silahkan mulai dengan pin repositori atau lihat pada dokumentasi [OpenEBS Architecture](./contribute/design/README.id.md)

## Lisensi

Lisensi OpenEBS berada di bawah projek [Apache License 2.0](https://github.com/openebs/openebs/blob/master/LICENSE). Beberapa komponen pada projek didapatkan dari _open-source_ projek lainya dan didistribusikan dibawah lisensi setiap projek tersebut.

OpenEBS adalah bagian dari Projek CNCF.

[![CNCF Sandbox Project](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)](https://landscape.cncf.io/selected=open-ebs)

## Commercial Offerings

Ini adalah list dari _third-party companies_ dan individual yang menggunakan poroduk dan servis dari OpenEBS. OpenEBS adalah sebuah projek CNCF yang tidak mendukung perusahaan manapun.

- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [Gridworkz Cloud Services](https://gridworkz.com/)
- [MayaData](https://mayadata.io/)
