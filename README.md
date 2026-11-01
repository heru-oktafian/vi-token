# vi-token (Mobile Companion & Authenticator)

Aplikasi mobile berbasis **Flutter** yang berfungsi sebagai authenticator pribadi dan pemindai login untuk ekosistem **Vi-Pharma**, serta dirancang terintegrasi ke sistem absensi/kepegawaian **vi-payroll**.

Dengan aplikasi ini, staf dan apoteker tidak perlu mengetik username/password di komputer apotek/POS publik, melainkan cukup melakukan scan QR Code pada layar monitor untuk mengotorisasi sesi kerja secara aman dan instan.

---

## 🌟 Fitur Utama

1. **Secure Mobile Login**:
   - Otentikasi username & password dengan penyimpanan JWT terenkripsi aman menggunakan `flutter_secure_storage`.
   - Mengingat sesi login mobile sehingga tidak perlu login berulang kali.

2. **Scanner Kamera Cepat (`mobile_scanner`)**:
   - Deteksi QR code otomatis berkecepatan tinggi dengan viewfinder overlay modern.
   - Dilengkapi tombol senter (flashlight toggle).
   - Mendukung format payload `vipharma:qr:<sessionId>` maupun raw UUID.

3. **Simulator Mode (Manual Session Input)**:
   - Tersedia tombol "Input Session ID Manual" di halaman utama untuk kemudahan pengujian pada emulator Android / iOS yang tidak memiliki kamera fisik.

4. **Kustomisasi Server URL**:
   - Dialog pengaturan endpoint API langsung dari aplikasi untuk memudahkan switch antara `localhost` (10.0.2.2 untuk Android emulator), IP LAN WiFi, maupun domain production server.

---

## 🚀 Memulai (Getting Started)

### Prasyarat
- Flutter SDK 3.13+ (mendukung Flutter 3.24 / 3.27+)
- Android Studio / VS Code dengan Flutter extension
- Perangkat Android fisik atau Emulator

### Langkah-langkah Menjalankan:
```bash
# 1. Masuk ke direktori vi-token
cd vi-token

# 2. Ambil dependensi
flutter pub get

# 3. Jalankan aplikasi
flutter run
```

> **Catatan Pengujian di Emulator Android:**
> - Android Emulator mengakses localhost host komputer melalui IP khusus: `http://10.0.2.2:8080/api/v1`.
> - Jika menggunakan perangkat HP fisik via WiFi, gunakan IP lokal komputer Anda (contoh: `http://192.168.1.100:8080/api/v1`).
> - Anda dapat mengubah URL server ini kapan saja melalui ikon gear (Pengaturan) di layar Login atau Dashboard `vi-token`.

---

## 📱 Struktur Direktori

```text
vi-token/
├── lib/
│   ├── config.dart             # Konfigurasi default target backend URL
│   ├── main.dart               # Entry point Flutter & auto-login auth wrapper
│   ├── models/
│   │   └── user_model.dart     # Model JSON profil user
│   ├── services/
│   │   ├── auth_service.dart   # Service HTTP login & otorisasi QR code
│   │   └── storage_service.dart# Secure storage (JWT token, profile, custom server URL)
│   └── screens/
│       ├── login_screen.dart   # Layar login kredensial & dialog config URL
│       ├── home_screen.dart    # Layar utama authenticator & input manual emulator
│       └── scan_screen.dart    # Layar kamera scanner QR code
├── pubspec.yaml
└── README.md
```

---

## 🔐 Kredensial Default Uji Coba

Gunakan akun yang telah di-seed secara otomatis oleh backend `pharma-be`:
- **Username:** `admin`
- **Password:** `admin123`
