# Kontribusi pada OpenEBS

Fantastis!! Kami selalu menunggu OpenEBS _hackers_. Anda dapat memulai dengan membaca [overview](./contribute/design/README.md)

Pertama, jika kalian tidak yakin dan takut, anda dapat bertanya atau mengirim _issue_ atau _pull request_ kapanpun. Anda akan mendapatkan penghargaan untuk pencapaian terbaikmu. Yang terburuk pun akan menjadi baik ketika anda membuat sebuah perubahan. Kami mengapresiasi setiap kontribusi sekecil apapun dan jangan jadikan peraturan sebagai dinding pembatasmu.

Selain itu, untuk setiap orang yang ingin memberikan panduan kecil, cara terbaik untuk kontribusi pada projek ini, baca dokumen di bawah ini. Dokumen tersebut mencakup setiap poin dimana kami membutuhan kontribusi kalian, sebuah perubahan akan kami _margin_ sebagai sebuah kontribusi anda.

Akhir kata, OpenEBS adalah projek inovasi yang _Open Source_. Anda dipersilakan untuk berkontribusi dengan cara apa pun yang Anda bisa dan semua bantuan yang diberikan sangat kami hargai.

- [Issu untuk menyediakan Fungsional baru, perbaikan dokumentasi atau report _bugs_.](#topik-masalah)
- [Kirim perubahan untuk pengembangan dokumentasi.](#pengembangan-dokumentasi)
- [Kirim proposal untuk fitur/ pengembangan baru.](#fitur-baru)
- [Pecahkan masalah yang terjadi baik itu dokumentasi ataupun code.](#kontribusi-source-code-dan-fix-bugs)

Ada beberapa pedoman sederhana yang perlu Anda ikuti sebelum memberikan peretasan Anda.

## Topik Masalah

Ketika memberikan topik masalah,harap berikan spesifikasi:

- Detail masalah harus diisi sebagaimana ditentukan dalam template masalah dengan jelas untuk diperiksa oleh pengulas.
- Skenario saat masalah terjadi (dengan detail tentang cara mereproduksinya).
- Kesalahan dan pesan log yang ditampilkan oleh perangkat lunak.
- Keterangan tambahan yang menyangkut dengan masalah.

## Pengembangan Dokumentasi

Membuat dokumentasi yang benar itu sulit! Periksa pada bagian ini [page](./contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) untuk informasi lebih lanjut tentang bagaimana cara memperbaharui documentasi dengan menambahkan _pull request_ dengan tag yang sesuai. Ini adalah [list of tags](./contribute/labels-of-issues.md) yang dapat digunakan.Bantu kami untuk membuat dokumentasi yang rapi, mudah dimengerti dan mudah di akses.

## Fitur Baru

Ada sesuatu yang lebih penting dari membuat sebuah fitur baru, membuatnya mudah di gunakan. Silahkan bergabung dengan kasus untuk sebuah fitur baru atau menambahkan PR dengan alasan perubahan anda.

- [Join OpenEBS community on Kubernetes Slack](https://kubernetes.slack.com)
  - Already signed up? Head to our discussions at [#openebs](https://kubernetes.slack.com/messages/openebs/)

## Kontribusi source code dan fix bugs

Lampirkan PR dengan tag yang sesuai untuk fix bug atau memperbaharui _source code_. Untuk list tag, dapat dilihat di halaman [ini](./contribute/labels-of-issues.md).

- Untuk kontribusi pada K8s demo, silahkan lihat [document ini](./contribute/CONTRIBUTING-TO-K8S-DEMO.md).
  - Untuk melihat apa yang sedang OpenEBS kerjakan pda K8s, lihat [dokumen ini](./k8s/README.md).

* Untuk kontribusi pada _Kubernetes OpenEBS Provisioner_, silihkan lihat [document ini](./contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md).

Lihat [document](./contribute/design/code-structuring.md) untuk mendapatkan informasi tentang struktur code dan panduannya.

## Solve Existing Issues

Pergi ke halaman [issues](https://github.com/openebs/openebs/issues) untuk menemukan isu yang dapat anda selesaikan. Lihat [list of labels guide](./contribute/labels-of-issues.md) untuk membantumu menemukan issue yang dapat kamu selesaikan dengan cepat.

## Seseorang yang ingin berkontribusi dapat menangani masalah dengan mengklaimnya sebagai komentar / menetapkan ID GitHub mereka untuk masalah tersebut. Jika tidak ada PR atau pembaruan yang sedang berlangsung selama seminggu tentang masalah tersebut, maka masalah tersebut akan terbuka kembali untuk siapa saja yang akan membahasnya lagi. Kita perlu mempertimbangkan masalah / regresi prioritas tinggi di mana waktu respons harus sekitar satu atau dua hari.

### Sign your work

Kami menggunakan _Certificate of Origin (DCO)_ sebagai keamanan tambahan untuk OpenEBS projek.

We use the Developer Certificate of Origin (DCO) as an additional safeguard for the OpenEBS project. Ini adalah mekanisme yang mapan dan banyak digunakan untuk memastikan kontributor telah mengkonfirmasi hak mereka untuk melisensikan kontribusi mereka di bawah lisensi proyek. Silahkan baca [developer-certificate-of-origin](./contribute/developer-certificate-of-origin).

Jika Anda dapat mengesahkannya, cukup tambahkan baris ke setiap pesan git commit:

```
  Signed-off-by: Random J Developer <random@developer.example.org>
```

ata gunakan comment `git commit -s -m "commit message comes here"` untum menambahkannya pada commit anda.

Gunakan nama asli anda (maaf, bukan pseudonyms atau anonymous kontributor). jika anda setel `user.name` anda dan `user.email` pada git config, anda dapat sign comit secara otomatis dengan `git commit -s`. Anda juga dapat menggunakan [aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) seperti `git config --global alias.ci 'commit -s'`. Sekarang anda dapat comiit dengan `git ci` dan commit akan masuk otomatis.

---

## Join our community

Ingin menjadi _developer_ dan kontriubtor aktif pada OpenEBS _community_, silahkan baca [document](./community/README.md).
