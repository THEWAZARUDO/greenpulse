# 🌱 GreenPulse - Hệ Thống Giám Sát & Quản Lý Nông Nghiệp Thông Minh (Smart Agriculture IoT)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Supported-orange.svg?logo=firebase)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg)]()
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)]()

**GreenPulse** là ứng dụng di động được xây dựng bằng **Flutter** kết hợp với hệ sinh thái **Firebase** và thiết bị **IoT (ESP32)**, hỗ trợ người nông dân và người quản lý giám sát, điều khiển và theo dõi các chỉ số môi trường nông nghiệp theo thời gian thực.

---

## 🚀 Tính Năng Nổi Bật

* **🔐 Xác thực người dùng (Authentication):** Đăng nhập, đăng ký tài khoản bảo mật qua Firebase Auth.
* **📊 Dashboard Giám sát Realtime:** Theo dõi liên tục các thông số môi trường như nhiệt độ, độ ẩm không khí, độ ẩm đất, ánh sáng và trạng thái các thiết bị (bơm tưới, đèn, quạt).
* **🏡 Quản lý Nông trại (Farms Management):** Quản lý danh sách các nông trại, nhà kính, khu vực canh tác riêng biệt.
* **🔌 Cấu hình & Kết nối IoT (Wi-Fi Provisioning):** Hướng dẫn và gửi cấu hình Wi-Fi trực tiếp cho mạch điều khiển ESP32 thông qua cổng phát sóng Wi-Fi AP nội bộ của mạch.
* **🔔 Cảnh báo Thông minh (Alerts & Notifications):** Nhận thông báo tự động và phát cảnh báo khi các chỉ số vượt ngưỡng an toàn (sử dụng `flutter_local_notifications`).
* **👤 Quản lý Hồ sơ (Profile):** Cập nhật thông tin cá nhân, thay đổi mật khẩu và tùy chỉnh cài đặt ứng dụng.

---

## 🛠️ Công Nghệ Sử Dụng

* **Framework:** [Flutter](https://flutter.dev/) (Dart SDK ^3.12.2)
* **Backend & Database:**
  * **Firebase Authentication:** Quản lý người dùng.
  * **Cloud Firestore:** Lưu trữ dữ liệu danh mục nông trại, lịch sử & cấu hình người dùng.
  * **Firebase Realtime Database:** Cập nhật tức thời các thông số cảm biến IoT.
* **IoT & Networking:**
  * Giao tiếp HTTP AP để truyền tham số SSID/Password cho vi điều khiển (ESP32).
* **Local Notification:** `flutter_local_notifications` phát thông báo đẩy cục bộ.

---

## 📂 Cấu Trúc Dự Án

```text
lib/
├── firebase_options.dart   # Cấu hình kết nối Firebase
├── main.dart               # Điểm khởi chạy ứng dụng (Entry point)
├── models/                 # Chứa các Data Model (User, Farm, Sensor...)
├── screens/                # Giao diện chính của ứng dụng
│   ├── login_screen.dart       # Màn hình đăng nhập
│   ├── register_screen.dart    # Màn hình đăng ký
│   ├── main_tab_screen.dart    # Màn hình chứa thanh điều hướng Tab
│   ├── provision_screen.dart   # Màn hình kết nối & cấu hình Wi-Fi cho ESP32
│   └── tabs/                   # Các trang Tab chính
│       ├── dashboard_tab.dart  # Bảng điều khiển thời gian thực
│       ├── farms_tab.dart      # Danh sách & quản lý nông trại
│       ├── alerts_tab.dart     # Nhật ký & thông báo cảnh báo
│       └── profile_tab.dart    # Thông tin tài khoản & cài đặt
└── services/               # Chứa các dịch vụ xử lý logic & kết nối
    ├── auth_service.dart         # Xử lý đăng nhập/đăng ký Firebase
    ├── firestore_service.dart    # Tương tác dữ liệu Cloud Firestore
    ├── rtdb_service.dart         # Kết nối Firebase Realtime Database
    └── notification_service.dart # Xử lý thông báo đẩy
```

---

## 💻 Hướng Dẫn Cài Đặt & Chạy Dự Án

### Yêu cầu hệ thống:
* Đã cài đặt **Flutter SDK** (phiên bản `>= 3.12.2`).
* Đã cài đặt **Android Studio** hoặc **VS Code** có plugin Flutter & Dart.
* Thiết bị di động thật hoặc máy ảo (Emulator/Simulator).

### Các bước thực hiện:

1. **Clone repository về máy:**
   ```bash
   git clone https://github.com/USERNAME/greenpulse.git
   cd greenpulse
   ```

2. **Cài đặt các gói phụ thuộc (Dependencies):**
   ```bash
   flutter pub get
   ```

3. **Cấu hình Firebase (Nếu sử dụng dự án Firebase riêng):**
   * Đảm bảo file `android/app/google-services.json` đã được thêm vào thư mục ứng dụng Android.
   * Cập nhật file `lib/firebase_options.dart` phù hợp với Firebase Project của bạn.

4. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```

---

## 🤝 Đóng Góp (Contributing)

Mọi đóng góp nhằm cải thiện dự án đều được hoan nghênh! Nếu bạn có ý tưởng hoặc phát hiện lỗi, hãy:
1. Fork dự án này.
2. Tạo nhánh tính năng mới (`git checkout -b feature/AmazingFeature`).
3. Commit thay đổi của bạn (`git commit -m 'Add some AmazingFeature'`).
4. Push lên nhánh (`git push origin feature/AmazingFeature`).
5. Mở một **Pull Request**.

---

## 📄 Giấy Phép (License)

Dự án được phân phối dưới giấy phép **MIT License**. Xem file `LICENSE` để biết thêm chi tiết.
