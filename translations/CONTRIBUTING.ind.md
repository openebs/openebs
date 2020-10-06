# OpenEBS

[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack channel #openebs](https://img.shields.io/badge/slack-openebs-brightgreen.svg?logo=slack)](https://kubernetes.slack.com/messages/openebs)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/openebs/openebs/blob/master/CONTRIBUTING.md)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fopenebs%2Fopenebs?ref=badge_shield)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1754/badge)](https://bestpractices.coreinfrastructure.org/projects/1754)

https://openebs.io/

**OpenEBS** adalah solusi penyimpanan sumber terbuka yang paling banyak digunakan dan mudah digunakan untuk Kubernetes.

**OpenEBS** adalah contoh sumber terbuka terkemuka dari kategori solusi penyimpanan yang terkadang disebut [Container Attached Storage](https://www.cncf.io/blog/2018/04/19/container-attached-storage-a-primer/). **OpenEBS** terdaftar sebagai contoh sumber terbuka di [CNCF Storage Landscape White Paper](https://github.com/cncf/sig-storage/blob/master/CNCF%20Storage%20Landscape%20-%20White%20Paper.pdf) di bawah solusi penyimpanan hyperconverged.

Beberapa aspek utama yang membuat OpenEBS berbeda dibandingkan dengan solusi penyimpanan tradisional lainnya:
- Dibangun menggunakan arsitektur layanan mikro seperti aplikasi yang dilayaninya. OpenEBS sendiri di-deploy sebagai kumpulan container di node pekerja Kubernetes. Menggunakan Kubernetes sendiri untuk mengatur dan mengelola komponen OpenEBS
- Dibangun sepenuhnya di ruang pengguna sehingga sangat portabel untuk dijalankan di semua OS / platform
- Sepenuhnya didorong oleh niat, mewarisi prinsip yang sama yang mendorong kemudahan penggunaan dengan Kubernetes
- OpenEBS mendukung berbagai mesin penyimpanan sehingga pengembang dapat menerapkan teknologi penyimpanan yang sesuai dengan tujuan desain aplikasi mereka. Aplikasi terdistribusi seperti Cassandra dapat menggunakan mesin LocalPV untuk penulisan latensi terendah. Aplikasi monolitik seperti MySQL dan PostgreSQL dapat menggunakan mesin ZFS (cStor) untuk ketahanan. Aplikasi streaming seperti Kafka dapat menggunakan mesin NVMe [Mayastor](https://github.com/openebs/Mayastor) untuk performa terbaik di lingkungan edge. Di semua jenis mesin, OpenEBS menyediakan kerangka kerja yang konsisten untuk ketersediaan tinggi, snapshot, klon, dan pengelolaan.

OpenEBS sendiri di-deploy hanya sebagai container lain di host Anda dan mengaktifkan layanan penyimpanan yang dapat ditetapkan pada level per pod, aplikasi, cluster, atau container, termasuk:
- Mengotomatiskan pengelolaan penyimpanan yang terpasang ke node pekerja Kubernetes dan mengizinkan penyimpanan tersebut digunakan untuk Provisioning OpenEBS PV atau PV Lokal secara dinamis.
- Persistensi data di seluruh node, secara dramatis mengurangi waktu yang dihabiskan untuk membangun kembali cincin Cassandra misalnya.
- Sinkronisasi data di seluruh zona ketersediaan dan penyedia cloud meningkatkan ketersediaan dan mengurangi waktu pasang / lepas, misalnya.
- Lapisan umum, jadi apakah Anda menggunakan AKS, atau bare metal, atau GKE, atau AWS - pengalaman kabel dan pengembang untuk layanan penyimpanan Anda semirip mungkin.
- Manajemen tingkat ke dan dari S3 dan target lainnya.

Keuntungan tambahan menjadi solusi asli Kubernetes sepenuhnya adalah bahwa administrator dan pengembang dapat berinteraksi dan mengelola OpenEBS menggunakan semua perkakas luar biasa yang tersedia untuk Kubernetes seperti kubectl, Helm, Prometheus, Grafana, Weave Scope, dll.

**Visi kami** sederhana: biarkan layanan penyimpanan dan penyimpanan untuk beban kerja persisten diintegrasikan sepenuhnya ke dalam lingkungan sehingga setiap tim dan beban kerja mendapatkan keuntungan dari perincian kontrol dan perilaku asli Kubernetes.

#### *Read this in [other languages](translations/TRANSLATIONS.md).*

[🇩🇪](translations/README.de.md)
[🇷🇺](translations/README.ru.md)
[🇹🇷](translations/README.tr.md)
[🇺🇦](translations/README.ua.md)
[🇨🇳](translations/README.zh.md)
[🇫🇷](translations/README.fr.md)

## Skalabilitas

OpenEBS dapat menskalakan untuk menyertakan sejumlah besar pengontrol penyimpanan dalam container. Kubernetes digunakan untuk menyediakan bagian fundamental seperti menggunakan etcd untuk inventaris. OpenEBS mengukur sejauh mana Kubernetes Anda diskalakan.

## Instalasi dan Memulai

OpenEBS dapat diatur dalam beberapa langkah mudah. Anda dapat melanjutkan pilihan cluster Kubernetes dengan menginstal open-iscsi pada node Kubernetes dan menjalankan operator openebs menggunakan kubectl.

**Mulai Layanan OpenEBS menggunakan operator**
```bash
# apply this yaml
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
```

**Mulai Layanan OpenEBS menggunakan helm**
```bash
helm repo update
helm install --namespace openebs --name openebs stable/openebs
```

Anda juga bisa mengikuti kami [QuickStart Guide](https://docs.openebs.io/docs/overview.html). <br><br>
OpenEBS dapat di-deploy di cluster Kubernetes mana pun - baik di cloud, laptop lokal, atau developer (minikube). Perhatikan bahwa tidak ada perubahan pada kernel pokok yang diperlukan karena OpenEBS beroperasi di ruang pengguna. Silakan ikuti [OpenEBS Setup](https://docs.openebs.io/docs/overview.html) kami dokumentasi. Selain itu, kami memiliki lingkungan Vagrant yang mencakup penerapan Kubernetes sampel dan beban sintetis yang dapat Anda gunakan untuk mensimulasikan kinerja OpenEBS. Anda juga mungkin tertarik dengan proyek terkait yang disebut Litmus(https://litmuschaos.io) yang membantu dengan chaos engineering untuk beban kerja stateful di Kubernetes.

## Status

OpenEBS adalah salah satu infrastruktur penyimpanan Kubernetes yang paling banyak digunakan dan teruji di industri. Proyek Kotak Pasir CNCF sejak Mei 2019, OpenEBS adalah sistem penyimpanan pertama dan satu-satunya yang menyediakan serangkaian kemampuan penyimpanan yang ditentukan perangkat lunak secara konsisten pada beberapa backend (lokal, nfs, zfs, nvme) di sistem on-premise dan cloud, dan telah yang pertama membuka sumbernya sendiri Kerangka Kerja Rekayasa Chaos untuk Beban Kerja Stateful, [Proyek Litmus](https://litmuschaos.io), yang diandalkan komunitas untuk menilai kesiapan otomatis irama bulanan versi OpenEBS. Pelanggan perusahaan telah menggunakan OpenEBS dalam produksi sejak 2018 dan proyek ini mendukung 2,5 juta lebih tarikan buruh pelabuhan seminggu.

Status berbagai mesin penyimpanan yang menjalankan Volume Persisten OpenEBS disediakan di bawah ini. Perbedaan utama antara status dirangkum di bawah ini:
- **alpha:** API dapat berubah dengan cara yang tidak kompatibel dalam rilis perangkat lunak selanjutnya tanpa pemberitahuan, disarankan untuk digunakan hanya dalam cluster pengujian yang berumur pendek, karena peningkatan risiko bug dan kurangnya dukungan jangka panjang.
- **beta**: Dukungan untuk keseluruhan fitur tidak akan dihentikan, meskipun detailnya dapat berubah. Dukungan untuk peningkatan atau migrasi antar versi akan diberikan, baik melalui otomatisasi atau langkah manual.
- **stabil**: Fitur akan muncul di perangkat lunak yang dirilis untuk banyak versi berikutnya dan dukungan untuk peningkatan antar versi akan disediakan dengan otomatisasi perangkat lunak di sebagian besar skenario.

| Mesin Penyimpanan | Status | Rincian |
| --- | --- | --- |
| Jiva | stabil | Paling cocok untuk menjalankan Replicated Block Storage pada node yang menggunakan penyimpanan efemeral pada node pekerja Kubernetes |
| cStor | beta | Opsi yang lebih disukai untuk dijalankan pada node yang memiliki Block Devices. Pilihan yang disarankan jika Snapshot dan Klon diperlukan |
| Volume Lokal | beta | Paling cocok untuk Aplikasi Terdistribusi yang membutuhkan penyimpanan latensi rendah - penyimpanan yang terpasang langsung dari node Kubernetes. |
| Walikota | alpha | Mesin penyimpanan baru yang beroperasi dengan efisiensi Penyimpanan Lokal tetapi juga menawarkan layanan penyimpanan seperti Replikasi. Pengembangan sedang dilakukan untuk mendukung Snapshots dan Clones. |

Untuk lebih jelasnya, silakan merujuk ke [OpenEBS Documentation](https://docs.openebs.io/docs/next/quickstart.html).

## Berkontribusi

OpenEBS menyambut umpan balik dan kontribusi Anda dalam bentuk apapun yang memungkinkan.

- [Bergabung dengan komunitas OpenEBS di Kubernetes Slack](https://kubernetes.slack.com)
  - Sudah mendaftar? Ikuti diskusi kami di [#openebs](https://kubernetes.slack.com/messages/openebs/)
- Ingin mengemukakan masalah atau bantuan dengan perbaikan dan fitur?
  - Lihat [masalah terbuka](https://github.com/openebs/openebs/issues)
  - Lihat [panduan berkontribusi](CONTRIBUTING.ind.md)
  - Ingin bergabung dengan pertemuan komunitas kontributor kami, [lihat ini](./ community / README.md).
- Bergabunglah dengan milis OpenEBS CNCF kami
  - Untuk pembaruan proyek OpenEBS, berlangganan [OpenEBS Announcements](https://lists.cncf.io/g/cncf-openebs-announcements)
  - Untuk berinteraksi dengan pengguna OpenEBS lainnya, berlangganan ke [Pengguna OpenEBS](https://lists.cncf.io/g/cncf-openebs-users)

## Tunjukkan Kode

Ini adalah meta-repositori untuk OpenEBS. Silakan mulai dengan repositori yang disematkan atau dengan dokumen [OpenEBS Architecture](./contribute/design/README.md).

## Lisensi

OpenEBS dikembangkan di bawah lisensi [Apache License 2.0](https://github.com/openebs/openebs/blob/master/LICENSE) di tingkat proyek. Beberapa komponen proyek berasal dari proyek sumber terbuka lainnya dan didistribusikan di bawah lisensinya masing-masing.

OpenEBS adalah bagian dari Proyek CNCF.

[![CNCF Sandbox Project](https://raw.githubusercontent.com/cncf/artwork/master/other/cncf-sandbox/horizontal/color/cncf-sandbox-horizontal-color.png)](https://landscape.cncf.io/selected=open-ebs)

## Penawaran Komersial

Ini adalah daftar perusahaan dan individu pihak ketiga yang menyediakan produk atau layanan yang terkait dengan OpenEBS. OpenEBS adalah proyek CNCF yang tidak mendukung perusahaan mana pun. Daftar ini disediakan dalam urutan abjad.
- [Clouds Sky GmbH](https://cloudssky.com/en/)
- [CodeWave](https://codewave.eu/)
- [Layanan Cloud Gridworkz](https://gridworkz.com/)
- [MayaData](https://mayadata.io/)
