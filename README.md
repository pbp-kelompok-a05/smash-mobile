# Smash Mobile! - Your Best Padel Forum, now Coming to Your Phone! 💥

Tugas Kelompok PBP A - A05

### Download APK

[![Build Status](https://app.bitrise.io/app/cb387238-c776-4e90-8597-8c004a372020/status.svg?token=JPiKA9uZjkC4KSkVz1g8mw&branch=master)](https://app.bitrise.io/app/cb387238-c776-4e90-8597-8c004a372020)

Public install link (Bitrise): [Download](https://app.bitrise.io/app/cb387238-c776-4e90-8597-8c004a372020/installable-artifacts/0b879d94cec807b5/public-install-page/99858cbb922032bc59882b22a7f5bf13)

All builds: [See all builds](https://app.bitrise.io/app/cb387238-c776-4e90-8597-8c004a372020)

### Anggota

- Ardyana Feby Pratiwi - 2406398274
- Christna Yosua Rotinsulu - 2406495691
- Ilham Afuw Ghaniy - 2406403495
- Nathanael Leander Herdanatra - 2406421320
- Nita Pasaribu 2406436890
- Rashika Maharani Putri Rudyanto - 2406352670

### Deskripsi Aplikasi

Repositori ini memuat kode untuk aplikasi **Smash Mobile!** yaitu versi _mobile app_ dari forum olahraga padel **Smash!**. Dengan tampilan yang dioptimalkan untuk smartphone Anda, aplikasi ini menyediakan fitur-fitur untuk membuat pengalaman berdiskusi Anda lebih baik, di antaranya:

- Fitur login, register, dan logout yang terintegrasi dengan [versi web dari aplikasi](https://nathanael-leander-smash.pbp.cs.ui.ac.id/).
- Halaman _homepage_ yang berisi tautan cepat dan _feed_ terbaru yang diperbarui setiap harinya.
- Halaman untuk melihat semua daftar postingan dan mendukung _filtering_.
- Buat post baru, komentar, like, dan dislike.
- Akses halaman profil Anda dengan mudah.

### Daftar Modul:

- Homepage: Nita, Christna
- Login-register-logout: Chika (Rashika)
- Post-comment: Nathan, Ilham
- Profile: Ardyana

### Peran atau aktor pengguna aplikasi

Terdapat dua peran user di aplikasi ini yaitu guest dan logged-in user. Guest adalah sesi user default (sebelum login) di mana user bisa melihat post, tetapi tidak bisa berkomentar, memberi like/dislike, atau membuat post baru. Sementara itu, logged-in user bisa memberi like, dislike, komentar, dan membuat post baru.

### Alur Pengintergrasian Data

Data aplikasi terintegrasi dengan [versi web dari aplikasi](https://nathanael-leander-smash.pbp.cs.ui.ac.id/) menggunakan Django API dan JSON. Ketika pengguna melakukan aksi (login, register, logout, akses halaman post atau membuat post) aksi tersebut akan diolah sebagai HTTP request dan dikirimkan ke web server secara asinkronus. Web server yang menggunakan Django akan mem-forward request tersebut pada `views.py` yang tepat (handler URL oleh `urls.py`) dan mengembalikan respons berupa JSON. Respons ini akan dikirimkan kembali ke aplikasi Flutter dan ditangkap secara asinkronus untuk kemudian diolah menjadi model data yang tepat.

### Link Figma (WIP)

[Figma Design Link](https://www.figma.com/design/3VuyZhgnNKDuvrI3NkmgK8/TK2-PBP?m=auto&t=uAIObD9s4PPWKHMY-6)

### Link Spreadsheet Planning

[Planning A05_Smash](https://docs.google.com/spreadsheets/d/1s9tCWLteShxZbHgpX9CTKBdMHocH7qI8WwD6wGcW2AU/edit?usp=sharing)
