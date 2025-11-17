# 📱 Kick Chronicle Mobile: Sorotan & Jadwal Sepak Bola (Flutter)

Aplikasi mobile ini adalah kelanjutan dari proyek web **Kick Chronicle** mata kuliah Pemrograman Berbasis Platform. Tujuannya adalah menghadirkan fitur-fitur informasi highlight dan jadwal sepak bola ke platform Android dan iOS menggunakan Flutter, dengan tetap terintegrasi penuh dengan *backend* web service yang sudah ada.

[![Tautan Figma](https://img.shields.io/badge/Design%20on-Figma-blue?style=for-the-badge&logo=figma)](https://www.figma.com/design/IoJuqP32KoKrtjMn1QZBU2/Web-PBP?node-id=0-1&t=wWxrSbKCbXsgsOid-1)
[![Backend Repository](https://img.shields.io/badge/Web%20Backend-Django-darkgreen?style=for-the-badge&logo=django)](https://github.com/pbp-kelompok-c12/KickChronicle.git) 

---

## ✨ Deskripsi Aplikasi

**Kick Chronicle** merupakan sebuah platform yang dirancang untuk memudahkan para penggemar sepak bola untuk mengakses **video highlight pertandingan**, **memantau statistik tim**, dan **mengelola jadwal pertandingan favorit** dalam satu platform yang utuh.

| Fitur Utama | Deskripsi |
| :--- | :--- |
| **Video Highlight** | Menonton sorotan pertandingan sepak bola yang relevan. |
| **Statistik & Klasemen** | Akses data klasemen liga dan statistik tim. |
| **Fitur Interaktif** | Memberikan Like, Komentar, dan Rating pada setiap highlight. |
| **Manajemen Jadwal** | Fitur kalender dan ekspor jadwal ke kalender pribadi (*.ics). |
| **Autentikasi** | Login/Registrasi standar dan integrasi Google OAuth. |

---

## 👥 Tim Pengembang

| Nama Anggota | NPM |
| :--- | :--- |
| Derrick | 2406351440 |
| Go Nadine Audelia | 2406348774 |
| Rehema Zurafa Saputra | 2406432072 |
| Andi Maura Azzahra | 2406409076 |
| Daffa Abhinaya Avensinanoor | 2406405720 |

---

## 👑 Peran Aktor Pengguna

Kami membagi peran pengguna menjadi dua aktor utama:

### ⚽ User (Penggemar)
* **Autentikasi** dengan Google OAuth.
* **Menonton** *highlight* pertandingan.
* **Memperoleh** statistik dan klasemen tim.
* **Menambahkan** jadwal pertandingan ke kalender (export file .ics).
* **Berinteraksi** dengan video (komentar, *like*, dan *rating*).

### 👑 Admin (Staf)
* **Mengelola** data tim, jadwal, dan *highlight* (CRUD).
* **Melakukan** Impor dan Ekspor dataset.
* **Bertindak** sebagai moderator untuk mengelola sesi komentar.

---

## 🛠️ Daftar Modul dan Pembagian Kerja

| Modul | Deskripsi | Penanggung Jawab |
| :--- | :--- | :--- |
| **Auth & Profil** | Login, Registrasi, Google OAuth, dan pengelolaan profil pengguna. | Derrick |
| **Highlight** | Daftar dan detail highlight serta fitur pencarian. | Rehema Zurafa Saputra |
| **Tim** | Daftar tim dan klasemen. | Daffa Abhinaya Avensinanoor |
| **Komentar, Like, Rating** | Fitur interaksi pada video highlight dan halaman favorit. | Andi Maura Azzahra |
| **Kalender** | Integrasi jadwal pertandingan. | Go Nadine Audelia |

---

## 🌐 Alur Pengintegrasian dengan Web Service

Aplikasi Flutter ini beroperasi sebagai **Client** yang sepenuhnya bergantung pada *web service* Django (**Backend**) yang telah dikembangkan di Proyek Tengah Semester. Integrasi dilakukan melalui **RESTful API** menggunakan protokol **HTTPS**.

1.  **Inisiasi Permintaan (Client):**
    * Aplikasi Flutter mengirimkan *request* HTTP (e.g., `GET` untuk data, `POST` untuk interaksi) ke *endpoint* API Django (misalnya `/tim/api/standings/` untuk klasemen).

2.  **Pemrosesan di Backend (Django):**
    * Server Django menerima dan memproses *request*.
    * Jika *request* memerlukan otentikasi (seperti membuat komentar atau *rating*), Django memvalidasi *token* otentikasi pengguna.
    * Data diambil dari model Django (e.g., `Standing`, `Highlight`, `Comment`).

3.  **Transfer Data (JSON):**
    * Django mengembalikan respons dalam format **JSON** yang berisi data yang diminta atau pesan status/kesalahan.

4.  **Pembaruan UI (Flutter):**
    * Flutter menerima dan mengurai (parse) respons JSON.
    * Data diubah menjadi objek Dart dan diperbarui ke antarmuka pengguna secara reaktif.

### Contoh Endpoints Utama:
| Kategori | Endpoint API (Backend Django) | Fungsi |
| :--- | :--- | :--- |
| **Tim** | `/tim/api/standings/` | Mengambil data klasemen berdasarkan musim. |
| **Kalender** | `/kalender/api/get_matches/` | Mengambil data jadwal pertandingan harian. |
| **Interaksi** | `/komen/submit-rating/` | Mengirimkan rating pengguna untuk highlight tertentu. |

---

## 🎨 Link Figma

**Link Figma:** `https://www.figma.com/design/TIgzIwJN8EFOYjLH42A5P7/Flutter-Kick-Chronicle?node-id=0-1&m=dev&t=43PBPB8JzqbaSMip-1`