# 🌱 GreenPulse - Hệ Thống Giám Sát & Quản Lý Nông Nghiệp Thông Minh (Smart Agriculture IoT)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Supported-orange.svg?logo=firebase)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg)]()
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)]()

**GreenPulse** là ứng dụng di động được xây dựng bằng **Flutter** kết hợp với hệ sinh thái **Firebase** và thiết bị **IoT (ESP8862)**, hỗ trợ người nông dân và người quản lý giám sát, điều khiển và theo dõi các chỉ số môi trường nông nghiệp theo thời gian thực.

---

## Tính Năng Nổi Bật

* ** Xác thực người dùng (Authentication):** Đăng nhập, đăng ký tài khoản bảo mật qua Firebase Auth.
* ** Dashboard Giám sát Realtime:** Theo dõi liên tục các thông số môi trường như nhiệt độ, độ ẩm không khí, độ ẩm đất, ánh sáng và trạng thái các thiết bị (bơm tưới, đèn, quạt).
* ** Quản lý Nông trại (Farms Management):** Quản lý danh sách các nông trại, nhà kính, khu vực canh tác riêng biệt.
* ** Cấu hình & Kết nối IoT (Wi-Fi Provisioning):** Hướng dẫn và gửi cấu hình Wi-Fi trực tiếp cho mạch điều khiển ESP8862 thông qua cổng phát sóng Wi-Fi AP nội bộ của mạch.
* ** Cảnh báo Thông minh (Alerts & Notifications):** Nhận thông báo tự động và phát cảnh báo khi các chỉ số vượt ngưỡng an toàn (sử dụng `flutter_local_notifications`).
* ** Quản lý Hồ sơ (Profile):** Cập nhật thông tin cá nhân, thay đổi mật khẩu và tùy chỉnh cài đặt ứng dụng.
---

## Công Nghệ Sử Dụng

* **Framework:** [Flutter](https://flutter.dev/) (Dart SDK ^3.12.2)
* **Backend & Database:**
  * **Firebase Authentication:** Quản lý người dùng.
  * **Cloud Firestore:** Lưu trữ dữ liệu danh mục nông trại, lịch sử & cấu hình người dùng.
  * **Firebase Realtime Database:** Cập nhật tức thời các thông số cảm biến IoT.
* **IoT & Networking:** Giao tiếp HTTP AP để truyền tham số SSID/Password cho vi điều khiển (ESP8862).
* **Local Notification:** `flutter_local_notifications` phát thông báo đẩy cục bộ.

---

## 📂 Cấu Trúc Dự Án

```text
lib/
├── firebase_options.dart
├── main.dart
├── models/
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── main_tab_screen.dart
│   ├── provision_screen.dart
│   └── tabs/
│       ├── dashboard_tab.dart
│       ├── farms_tab.dart
│       ├── alerts_tab.dart
│       └── profile_tab.dart
└── services/
    ├── auth_service.dart
    ├── firestore_service.dart
    ├── rtdb_service.dart
    └── notification_service.dart
```