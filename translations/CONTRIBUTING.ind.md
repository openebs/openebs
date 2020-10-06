# Berkontribusi ke OpenEBS

Bagus!! Kami selalu mencari lebih banyak lagi peretas OpenEBS. Anda dapat memulai dengan membaca [ikhtisar](./contribute/labels-of-issues.md) ini

Pertama, jika Anda tidak yakin atau takut pada sesuatu, tanyakan atau ajukan masalah atau tarik permintaan. Anda tidak akan dimarahi karena memberikan upaya terbaik Anda. Hal terburuk yang bisa terjadi adalah Anda akan diminta dengan sopan untuk mengubah sesuatu. Kami menghargai kontribusi apa pun dan tidak ingin tembok peraturan menghalangi hal itu.

Namun, bagi individu yang menginginkan panduan lebih lanjut tentang cara terbaik untuk berkontribusi pada proyek, baca terus. Dokumen ini akan mencakup semua poin yang kami cari dalam kontribusi Anda, meningkatkan peluang Anda untuk menggabungkan atau menangani kontribusi Anda dengan cepat.

Konon, OpenEBS adalah inovasi dalam Open Source. Anda dipersilakan untuk berkontribusi dengan cara apa pun yang Anda bisa dan semua bantuan yang diberikan sangat kami hargai.

- [Angkat masalah untuk meminta fungsionalitas baru, memperbaiki dokumentasi, atau untuk melaporkan bug.](raising-issues)
- [Kirimkan perubahan untuk meningkatkan dokumentasi.](submit-change-to-improve-documentation) 
- [Kirimkan proposal untuk fitur / penyempurnaan baru.](submit-proposals-for-new-features)
- [Selesaikan masalah yang ada terkait dengan dokumentasi atau kode.](contributing-to-source-code-and-bug-fixes)

Ada beberapa pedoman sederhana yang perlu Anda ikuti sebelum memberikan peretasan Anda.

## Mengangkat Masalah

Saat mengangkat masalah, harap sebutkan hal berikut:
- Detail penyiapan harus diisi seperti yang ditentukan dalam templat terbitan dengan jelas untuk diperiksa pengulas.
- Skenario di mana masalah terjadi (dengan detail tentang cara mereproduksinya).
- Kesalahan dan pesan log yang ditampilkan oleh perangkat lunak.
- Detail lain yang mungkin berguna.

## Kirim Perubahan untuk Meningkatkan Dokumentasi

Sulit untuk mendapatkan dokumentasi dengan benar! Lihat [halaman](./contribute/CONTRIBUTING-TO-DEVELOPER-DOC.md) ini untuk informasi lebih lanjut tentang bagaimana Anda dapat meningkatkan dokumentasi pengembang dengan mengirimkan permintaan penarikan dengan tag yang sesuai.Berikut adalah [daftar tag](./contribute/labels-of-issues.md) yang bisa digunakan untuk hal yang sama. Bantu kami menjaga dokumentasi kami tetap bersih, mudah dipahami, dan dapat diakses.

## Kirimkan Proposal untuk Fitur Baru

Selalu ada sesuatu yang lebih dibutuhkan, untuk membuatnya lebih mudah untuk disesuaikan dengan kasus penggunaan Anda. Jangan ragu untuk bergabung dalam diskusi tentang fitur baru atau meningkatkan humas dengan perubahan yang Anda usulkan.

- [Bergabung dengan komunitas OpenEBS di Kubernetes Slack](https://kubernetes.slack.com)
  - Sudah mendaftar? Ikuti diskusi kami di [#openebs](https://kubernetes.slack.com/messages/openebs/)

## Berkontribusi pada Kode Sumber dan Perbaikan Bug

Berikan kepada PR tag yang sesuai untuk perbaikan bug atau peningkatan pada kode sumber. Untuk daftar tag yang dapat digunakan, lihat [ini](./contribute/labels-of-issues.md).

* Untuk berkontribusi pada demo K8s, silakan merujuk ke [dokumen](./contribute/CONTRIBUTING-TO-K8S-DEMO.md) ini.
     - Untuk melihat bagaimana OpenEBS bekerja dengan K8s, lihat [dokumen](./k8s/README.md)  ini .
- Untuk berkontribusi pada Kubernetes OpenEBS Provisioner, silakan merujuk ke [dokumen](./contribute/CONTRIBUTING-TO-KUBERNETES-OPENEBS-PROVISIONER.md) ini.

Lihat [dokumen](./contribute/design/code-structuring.md)  ini  untuk informasi lebih lanjut tentang penataan kode dan pedoman untuk mengikuti hal yang sama.

## Selesaikan Masalah yang Ada
Buka [masalah](https://github.com/openebs/openebs/issues) untuk menemukan masalah yang memerlukan bantuan dari kontributor. Lihat [panduan daftar label](./contribute/labels-of-issues.md) untuk membantu Anda menemukan masalah yang dapat Anda selesaikan lebih cepat.

Seseorang yang ingin berkontribusi dapat menangani masalah dengan mengklaimnya sebagai komentar / menetapkan ID GitHub mereka untuk masalah tersebut. Jika tidak ada PR atau pembaruan yang sedang berlangsung selama seminggu tentang masalah tersebut, maka masalah tersebut akan terbuka kembali untuk siapa saja yang akan membahasnya lagi. Kita perlu mempertimbangkan masalah / regresi prioritas tinggi di mana waktu respons harus sekitar satu atau dua hari.

---
### Tanda tangani pekerjaan Anda

Kami menggunakan Developer Certificate of Origin (DCO) sebagai pengaman tambahan untuk proyek OpenEBS. Ini adalah mekanisme yang mapan dan banyak digunakan untuk memastikan kontributor telah mengkonfirmasi hak mereka untuk melisensikan kontribusi mereka di bawah lisensi proyek. Silakan baca [pengembang-sertifikat-asal](./contribute/developer-certificate-of-origin).

Jika Anda dapat mengesahkannya, cukup tambahkan baris ke setiap pesan git commit:

`` ''
  Ditandatangani oleh: Random J Developer <random@developer.example.org>
`` ''
atau gunakan perintah `git komit -s -m" pesan komit datang di sini "` untuk keluar dari komit Anda.

Gunakan nama asli Anda (maaf, tidak ada nama samaran atau kontribusi anonim). Jika Anda menyetel konfigurasi git ʻuser.name` dan ʻuser.email`, Anda dapat menandatangani komit secara otomatis dengan `git commit -s`. Anda juga dapat menggunakan git [alias](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) seperti `git config --global alias.ci 'commit -s'`. Sekarang Anda dapat melakukan dengan `git ci` dan komit akan ditandatangani.

---

## Bergabunglah dengan komunitas kami

Ingin secara aktif mengembangkan dan berkontribusi pada komunitas OpenEBS, lihat [dokumen](./community/README.md) ini.
