# Cleanly: Cleaning Checklist

Checklist pembersihan rumah yang mengikuti waktu yang benar-benar Anda punya. Pilih durasi, pilih area, lalu ikuti daftar langkah sambil hitung mundur berjalan. Seluruh data disimpan lokal di perangkat: tanpa akun, tanpa backend, tanpa sinkronisasi.

Prototipe Android ini adalah **vertical slice** yang bisa langsung dipasang sebagai APK.

> **Penting:** Cleanly memakai `applicationId` yang sama dengan aplikasi Arunika yang sudah live (`id.arunika.arunika_growth`), jadi rilisnya dikirim sebagai **update dari listing Play Console yang sama**, bukan aplikasi baru. Konsekuensinya ada di bagian [Status rilis](#status-rilis).

## Alur utama

1. **Home** — pilih durasi (5 / 10 / 20 / 30 menit), pilih area (Kitchen, Bedroom, Bathroom, Living Room, atau Quick Home Reset), lalu tekan mulai. Pilihan terakhir dipakai lagi pada sesi berikutnya sehingga sesi baru bisa dimulai dengan satu ketukan. Bila aplikasi sempat tertutup di tengah sesi, kartu **lanjutkan sesi** muncul di atas dan tombol mulai dikunci sampai sesi itu ditutup atau dibuang.
2. **Sesi** — ring hitung mundur, bilah progres langkah, kartu "up next" berisi petunjuk singkat, dan checklist yang bisa dicentang. Bisa dijeda, diakhiri lebih awal, atau ditambah satu langkah dari katalog.
3. **Selesai** — confetti, jumlah menit, langkah yang dicentang, streak, dan ringkasan minggu.
4. **Routines** — rutinitas buatan sendiri (nama, area, durasi, dan langkah pilihan). Satu rutinitas bisa dipasang sebagai tombol cepat di Home. Tersedia juga empat template awal.
5. **History** — grafik batang minggu berjalan, streak berjalan dan terpanjang, total sesi/menit, serta daftar sesi terakhir beserta langkah yang dicentang.
6. **Settings** — tema, mode gelap, pengurangan animasi, jadwal + pengingat, hapus riwayat, opsi privasi iklan, dan info versi.

## Jadwal dan pengingat

Jadwal bisa harian atau mingguan, dengan pilihan hari, jam, area, dan durasi. Kartu jadwal menampilkan kapan pengingat berikutnya berbunyi. Pengingat memakai notifikasi lokal (`flutter_local_notifications`) dengan zona waktu yang dibaca dari perangkat, jadi jadwal tidak bergeser saat pergantian waktu musiman. Bila izin notifikasi ditolak, jadwalnya tetap tersimpan supaya pengguna tidak kehilangan pengaturan.

Hal yang sama dipakai untuk timer sesi: bila izin notifikasi sudah ada, Cleanly menjadwalkan satu notifikasi "time is up" saat sesi dimulai, sehingga pengguna tetap diberi tahu ketika hitung mundur habis sementara aplikasi di latar belakang. Notifikasi itu dibatalkan begitu sesi disimpan, dibuang, atau dijeda.

## Monetisasi

- **Banner** hanya di Home dan History. Slot tingginya tetap walau iklan gagal dimuat sehingga daftar di atasnya tidak melompat.
- **Interstitial** hanya setelah sesi selesai, yaitu setelah pengguna menutup layar ringkasan. Tidak pernah muncul selama timer berjalan. Aturan frekuensi: minimal setiap sesi kedua, dengan jeda 5 menit.
- **Rewarded** sepenuhnya opsional dan hanya untuk membuka tema (Bloom, Midnight) dan preset **deep clean 45 menit**. Hadiah hanya diberikan dari callback `onUserEarnedReward`; menutup iklan lebih awal tidak membuka apa pun.
- Tidak ada pembelian dalam aplikasi. Semua tab dan fitur inti gratis.

Semua permintaan iklan menunggu consent UMP selesai. Bila consent tidak tersedia, slot iklan tetap kosong tanpa mengganggu aplikasi.

## Build

Prasyarat: Flutter **3.44.6**, Dart **3.12.2**, JDK 21, Android SDK 36.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Urutan yang disarankan: uji lewat APK dulu, lalu kirim AAB ketika sudah pas.

APK untuk pemasangan lokal:

```powershell
flutter build apk --release
# atau, bila hanya butuh arsitektur perangkat modern:
flutter build apk --release --split-per-abi
```

Artefak versi 1.5.2 yang dihasilkan dari pohon kode ini:

| Berkas | Identitas | Dipakai untuk |
| --- | --- | --- |
| `Cleanly-v1.5.2-dev-arm64.apk` | `id.arunika.arunika_growth.dev`, ID iklan uji | Dipasang berdampingan dengan Arunika untuk uji di ponsel |
| `Cleanly-v1.5.2-live.aab` | `id.arunika.arunika_growth`, v1.5.2+12, upload key Arunika, ID iklan produksi | **Unggah ke Play Console** sebagai update listing |

### Mencoba APK tanpa menyentuh Arunika

APK dengan package id live **tidak bisa menimpa** Arunika yang terpasang dari Play (beda tanda tangan), dan menghapus Arunika dari ponsel akan menghapus data jurnalnya. Untuk mencoba berdampingan, bangun APK versi uji dengan package id bersuffix `.dev`:

```powershell
flutter build apk --release --split-per-abi `
  --dart-define=CLEANLY_APPLICATION_ID=id.arunika.arunika_growth.dev
```

Hasilnya `id.arunika.arunika_growth.dev` yang berdiri sendiri: Arunika tetap utuh dan data kedua aplikasi terpisah. Tanpa `--dart-define` tersebut, package id kembali ke id live secara otomatis.

Release AdMob asli dibaca dari `--dart-define-from-file`:

```powershell
flutter build apk --release --dart-define-from-file=tool/release/monetization.json
```

Tanpa berkas itu, build memakai **ID uji Google** dan **kunci debug** supaya APK tetap bisa dipasang untuk pengujian. Ini berlaku sama untuk profil debug maupun rilis: selama `ADMOB_*` belum diisi, konfigurasi Dart dan resource Gradle sama-sama jatuh ke ID uji Google (banner `6300978111`, interstitial `1033173712`, rewarded `5224354917`), sehingga APK uji rilis tetap menampilkan iklan tanpa risiko pelanggaran kebijakan. `isValidForRelease` menandai build yang masih membawa ID uji — jangan pernah naik ke produksi dalam keadaan itu. Untuk mengunggah ke Play Console, isi `android/key.properties` dengan keystore asli; konfigurasi tersebut diabaikan Git.

### Status rilis

Cleanly dikirim sebagai pembaruan aplikasi yang sudah live, jadi dua hal ini wajib:

1. **Kunci yang sama.** Update hanya diterima Play kalau ditandatangani dengan upload key yang sama seperti rilis Arunika. Salin konfigurasi privat dari proyek lama sekali saja:

   ```powershell
   cp ../arunika_growth/android/key.properties android/key.properties
   mkdir -p tool/release
   cp ../arunika_growth/tool/release/arunika-upload-key.jks tool/release/
   cp ../arunika_growth/tool/release/monetization.json tool/release/
   ```

   Keduanya sudah diabaikan `.gitignore` (`key.properties`, `/tool/release/`).
2. **versionCode lebih tinggi.** Rilis Arunika terakhir adalah `1.4.1+9`, sehingga versi di sini disetel `1.5.2+12`. Play menolak versionCode yang sudah pernah dipakai.

Catatan yang perlu diingat sebelum mengunggah:

- Karena `applicationId`-nya sama, Cleanly **tidak bisa dipasang berdampingan** dengan Arunika di satu perangkat, dan aplikasi Arunika akan tertimpa untuk pengguna lama.
- APK yang ditandatangani kunci debug **tidak bisa menimpa** Arunika yang terpasang dari Play (tanda tangan beda). Untuk uji cepat di ponsel: hapus Arunika dulu, atau bangun dengan upload key asli.
- Menghapus Arunika dari ponsel berarti **data jurnal keluarganya hilang permanen** — aplikasinya mematikan backup otomatis (`allowBackup=false`). Lakukan ekspor cadangan dari Arunika lebih dulu bila datanya masih dibutuhkan.
- Google dapat menilai perubahan fungsi sebesar ini pada satu listing sebagai misleading, karena pengguna lama tiba-tiba menerima aplikasi kebersihan. Siapkan catatan "what's new" yang jujur, dan pertimbangkan untuk berhenti di listing lama bila risikonya terlalu besar.
- Cleanly memakai database sendiri (`cleanly.db`), jadi data Arunika tidak dibaca maupun dimigrasikan.

Ikon launcher digambar dari skrip, bukan dari aset biner. Setelah mengubah bentuknya:

```powershell
dart run tool/generate_icon.dart            # menulis ulang seluruh mipmap
dart run tool/generate_icon.dart --preview  # pratinjau ASCII tanpa menulis berkas
```

## Struktur

- `lib/core/theme/` — palet tiga tingkat (`AccentFamily`), lima skin tema, dan `ThemeData` yang dibangun dari skin tersebut.
- `lib/core/widgets/` — kartu, ring progres, dan confetti yang digambar sendiri tanpa paket tambahan.
- `lib/domain/catalog/` — katalog 4 area × 10 langkah beserta perencana durasi.
- `lib/domain/monetization/` — batas tipis ke AdMob: gate interstitial, manager rewarded, policy retry banner.
- `lib/domain/notifications/` — penjadwalan notifikasi lokal.
- `lib/data/` — model dan SQLite (`cleaning_sessions`, `session_tasks`, `custom_routines`, `cleaning_schedules`).
- `lib/state/` — provider Riverpod: preferensi, draf sesi, sesi aktif, pengingat, iklan.
- `lib/ui/` — layar: `splash`, `onboarding`, `navigation`, `home`, `session`, `routines`, `history`, `schedule`, `settings`, `monetization`.

## Perencana checklist

Setiap langkah punya perkiraan waktunya sendiri dan satu tingkat prioritas:

| Tingkat | Peran | Contoh |
| --- | --- | --- |
| 1 | Kemenangan cepat, selalu dipakai | Make the bed, wipe the counters |
| 2 | Pembersihan standar | Scrub the toilet, dust the shelves |
| 3 | Pembersihan menyeluruh | Sort the fridge, scrub the grout |

Pemetaan durasi: 5 menit → tiga langkah tingkat 1, 10 menit → +2 langkah tingkat 2, 20 menit → seluruh tingkat 1 dan 2, 30 menit → +3 langkah tingkat 3. **Quick Home Reset** membagi durasi ke empat ruangan sehingga setiap ruangan mendapat satu atau dua kemenangan cepat.

## Pengujian

90 tes, semuanya berjalan tanpa perangkat:

- `cleaning_catalog_test.dart` — pemetaan durasi, keunikan id, dan panjang daftar tiap ruangan.
- `stats_test.dart` — streak berjalan/terpanjang, minggu yang mulai hari Senin, sesi ganda dalam satu hari, data tidak terurut.
- `insights_test.dart` — pengelompokan menit per area, area favorit, dan hitungan hari sejak sesi terakhir menurut hari kalender.
- `repository_test.dart` — SQLite asli: simpan/baca sesi beserta langkahnya, penggantian baris, hapus berantai, rutinitas, jadwal, dan penyaringan nilai jam yang rusak.
- `session_controller_test.dart` — mulai, centang, jeda, tambah langkah, buang, dan menyimpan sesi.
- `session_restore_test.dart` — pemulihan sesi setelah aplikasi ditutup: waktu yang berjalan dihitung, sesi jeda tidak maju, sesi kedaluwarsa kembali sebagai selesai, dan sesi berumur lebih dari sehari dibuang.
- `active_session_store_test.dart` — bolak-balik JSON, stempel waktu, data rusak dibuang tanpa crash, dan status jeda dipertahankan.
- `schedule_occurrence_test.dart` — kejadian pengingat berikutnya: harian lewat/tengah malam, mingguan per hari, batas bulan, dan tidak pernah lebih dari tujuh hari.
- `session_stop_test.dart` — keluar dari sesi lewat tombol X, tombol batal, dan gestur back sistem.
- `resume_card_test.dart` — kartu lanjutkan sesi di Home, tombol mulai terkunci, dan sesi yang selesai saat aplikasi mati bisa disimpan.
- `small_screen_test.dart` — seluruh alur pada 320×568, 360×640, dan 412×915, termasuk overlay jeda.
- `monetization_test.dart` — fallback ID uji AdMob (debug & rilis), validasi produksi, dan kebijakan frekuensi interstitial.
- `app_flow_test.dart` — alur end-to-end sebagai widget: onboarding → Home → pilih area → sesi → centang → Finish → ringkasan → kembali ke Home.

## Iklan 1.5.2

Kebijakan monetisasi yang berlaku:

- **Banner** 320×50 hanya di Home dan History, tinggi slot tetap agar daftar tidak melompat; tidak ada banner di layar sesi, ringkasan, atau editor.
- **Interstitial** hanya setelah layar ringkasan ditutup — tidak pernah di tengah timer. Frekuensi dibatasi `InterstitialGate`: minimal pada **sesi ketiga** sejak iklan terakhir dan tidak dua kali dalam **6 menit** (kira-kira satu iklan per 20–30 menit membersihkan). Iklan dimuat sejak aplikasi dibuka dan dimuat ulang otomatis setelah tampil, jadi tidak pernah menunda navigasi.
- **Rewarded** hanya dari aksi eksplisit (buka tema Bloom/Midnight dan preset deep-clean 45 menit). Hadiah hanya diberikan dari callback `onUserEarnedReward`; menutup iklan lebih awal tidak membuka apa pun. **Catatan AAB 1.5.2**: rewarded dinonaktifkan (`ENABLE_REWARDED=false`) karena belum ada unit ID produksi — memaksa ID uji ke produksi melanggar kebijakan AdMob. Buat unit rewarded di dashboard AdMob, tambahkan `ADMOB_REWARDED_ID` ke `tool/release/monetization.json`, lalu bangun ulang tanpa flag tersebut.
- Semua permintaan iklan menunggu **consent UMP** selesai; bila consent gagal, slot tetap kosong tanpa mengganggu UI. Opsi privasi tersedia di Settings.
- Debug maupun rilis tanpa `--dart-define` otomatis memakai **ID uji Google** (terverifikasi di dalam APK); ID produksi masuk lewat `tool/release/monetization.json`.

## Audit 1.5.1

Pemeriksaan menyeluruh atas fitur, GUI, dan engine. Yang diperbaiki dan ditambahkan:

**Bug**

- **Tombol Stop tidak bisa keluar dari sesi.** `PopScope(canPop: false)` memblokir `Navigator.maybePop()`, sehingga menekan Stop memanggil ulang dialog konfirmasi tanpa henti — layar sesi tidak pernah tertutup. Keluar sekarang memakai `Navigator.pop` dengan penanda keluar, dan dialog dijaga agar tidak bisa bertumpuk.
- **Sesi bisa tertimpa diam-diam.** Menekan rutinitas saat ada sesi berjalan langsung mengganti sesi tanpa bertanya; sekarang ada konfirmasi dan tombol "Keep cleaning" membawa ke sesi yang berjalan.
- **Preferensi warisan.** Karena package id-nya sama, kunci tanpa awalan (`dark_mode`, `reduced_motion`) terbaca dari aplikasi lama. Semua kunci kini berawalan `cleanly.`, dan mode gelap/pengurangan animasi diwarisi sekali lalu disalin.
- **Tata letak di layar sempit.** Kartu ruangan memakai rasio yang membuat kartu memendek sampai isinya meluap, dan kartu statistik History meluap di 320 dp. Keduanya kini aman pada font sistem besar.

**Engine**

- **Sesi bertahan hidup dari proses yang dibunuh.** Sesi ditulis ke penyimpanan tiap lima detik dan saat aksi penting; saat aplikasi dibuka lagi, waktu yang berjalan sementara aplikasi mati ikut dihitung (kecuali sesi sedang dijeda), sesi berumur lebih dari sehari dibuang, dan sesi yang sudah kehabisan waktu kembali dalam keadaan selesai untuk disimpan.
- **Notifikasi saat timer habis.** Dijadwalkan ketika sesi mulai (hanya bila izin sudah ada — tidak pernah meminta di tengah pembersihan), dibatalkan saat sesi selesai, dibuang, atau dijeda.
- **Timer sadar jeda dan latar belakang.** Ticker dimatikan saat jeda, dan saat aplikasi kembali ke depan hitung mundur disamakan langsung dengan jam dinding.
- **Skema basis data punya jalur migrasi** (`onUpgrade`), sehingga kenaikan versi skema di rilis berikutnya tidak membuat aplikasi gagal dibuka.
- **Pengingat dipasang ulang saat aplikasi dibuka**, karena Android membatalkan alarm lokal setelah aplikasi diperbarui.

**Fitur**

- Kartu **lanjutkan sesi** di Home (termasuk "Save it" untuk sesi yang selesai saat aplikasi tidak aktif) dan tombol mulai terkunci selama masih ada sesi.
- **Wawasan per area** di History: menit dan jumlah sesi tiap ruangan.
- **Pratinjau pengingat berikutnya** di kartu jadwal ("Next: Tomorrow · 09:00").
- Sakelar **Reminders on** sekarang benar-benar memasang ulang alarm untuk jadwal tersimpan, bukan hanya membuka layar jadwal.
- **Salin checklist** sebagai teks dari layar ringkasan.
- Konfirmasi sebelum menghapus satu sesi dari History.
- Nada mengajak di Home setelah dua hari tanpa membersihkan.

## Nama dan ASO

Nama kerja: **Cleanly: Cleaning Checklist**. Kata kunci sasaran: *Cleaning Checklist, Cleaning Routine, House Cleaning, Cleaning Schedule, Chores*. UI berbahasa Inggris agar cocok dengan kata kunci tersebut; seluruh teks terpusat di lapisan UI sehingga pelokalan bisa ditambahkan kemudian.

`applicationId` diset `id.arunika.arunika_growth` agar rilis masuk sebagai update dari listing yang sudah live. Bila nanti ingin memisahkan diri menjadi aplikasi baru (identitas bersih untuk ASO, bisa dipasang berdampingan, tanpa risiko penilaian ulang), ubah `applicationId` dan `namespace` di `android/app/build.gradle.kts`, pindahkan `MainActivity.kt` ke folder package yang sesuai, lalu samakan nama `MethodChannel` di `MainActivity.kt` dan `lib/domain/notifications/notification_service.dart`.
