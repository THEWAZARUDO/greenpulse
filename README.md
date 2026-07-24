# 🌱 GreenPulse - Hệ Thống Giám Sát & Phân Tích Nông Nghiệp Thông Minh (Smart Agriculture IoT & Fuzzy AI)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Supported-orange.svg?logo=firebase)](https://firebase.google.com)
[![Python AI](https://img.shields.io/badge/Python-FastAPI%20%7C%20Fuzzy%20Logic-yellow.svg?logo=python)](https://fastapi.tiangolo.com/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg)]()
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)]()

**GreenPulse** là ứng dụng di động nông nghiệp thông minh thế hệ mới được xây dựng bằng **Flutter**, kết hợp với hệ sinh thái **Firebase (Realtime Database & Firestore)**, vi điều khiển **IoT ESP32/ESP8266** và dịch vụ **AI Logic Mờ (Fuzzy Logic Microservice)**. Ứng dụng hỗ trợ giám sát thông số môi trường theo thời gian thực và phân tích sức khỏe cây trồng tức thì.

---

## ⚡ Tính Năng Nổi Bật & Tối Ưu Hiệu Năng

* **🚀 Tối Ưu Phản Hồi Fast-Path (0ms Latency)**: Áp dụng kiến trúc Optimistic UI & Non-blocking Stream. Dữ liệu cảm biến và đánh giá quy chuẩn hiển thị tức thì (0ms) trên màn hình, không bị treo đơ app khi chờ kết nối mạng.
* **🧠 Phân Tích AI Mờ (Fuzzy Logic Microservice)**: Kết nối với Python FastAPI Server phân tích đa thông số (Nhiệt độ, Độ ẩm không khí, Độ ẩm đất, Ánh sáng, pH) theo từng loại cây trồng và giai đoạn sinh trưởng.
* **🛡️ Chống Treo App Với Circuit Breaker & Render.com Cold Start Support**:
  - Tự động kích hoạt Circuit Breaker (bảo vệ 30s) khi ngắt mạng hoặc server AI gián đoạn.
  - Tự động phát ping ngầm (70s timeout) đánh thức Render.com Free Tier khi server đang ngủ (Cold Start ~50s) và chuyển trạng thái `🟢 AI Online` mượt mà.
* **🎛️ Công Cụ Giả Lập Debug Cảm Biến (`//Debug function`)**:
  - Nút giả lập đổi dữ liệu ESP32 (`tune` 🎛️) trực tiếp trên Dashboard và Tab Farm để kiểm thử các kịch bản An toàn, Cảnh báo, Red Alert mà không cần thiết bị thật.
  - Nhãn hiển thị trực quan trạng thái kết nối Server AI (`🟢 AI Online` | `⏳ Render đang dậy...` | `🟡 Offline`).
* **🚨 Cảnh Báo Đỏ & Thông Báo Đẩy (Red Alert & Push Notifications)**: Tự động bật Banner Cảnh báo đỏ và phát thông báo đẩy di động (`flutter_local_notifications`) với tần suất chuẩn 1 phút/lần khi phát hiện sự cố.
* **📡 Kết Nối & Cấu HÌnh IoT (Wi-Fi Provisioning)**: Ghép nối và gửi SSID/Password trực tiếp cho phần cứng ESP32/ESP8266 qua Wi-Fi AP nội bộ.
* **📱 Giao Diện Mobile Responsive 100%**: Thiết kế tương thích hoàn hảo trên mọi dòng điện thoại (từ 360px Android/iPhone SE đến iPhone Pro Max), vùng chạm cảm ứng chuẩn di động, chống tràn chữ.

---

## 🛠️ Công Nghệ Sử Dụng

* **Mobile App:** [Flutter](https://flutter.dev/) (Dart SDK ^3.12.2, Material 3)
* **Backend Cloud Services:**
  * **Firebase Authentication:** Quản lý người dùng & xác thực email.
  * **Cloud Firestore:** Lưu trữ danh mục nông trại, cấu hình người dùng & preset cây trồng.
  * **Firebase Realtime Database:** Đồng bộ dữ liệu cảm biến thời gian thực.
* **AI Engine:** Python (FastAPI, Scikit-Fuzzy, NumPy, SciPy, Uvicorn)
* **Local Notifications:** `flutter_local_notifications`

---

## 📂 Cấu Trúc Dự Án

```text
lib/
├── firebase_options.dart
├── main.dart
├── models/
│   ├── ai_evaluation_model.dart
│   ├── crop_preset_model.dart
│   ├── farm_model.dart
│   ├── plant_preset_manager.dart
│   └── user_model.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── verify_email_screen.dart
│   ├── main_tab_screen.dart
│   ├── provision_screen.dart
│   └── tabs/
│       ├── dashboard_tab.dart   (Lưới thông số 0ms, Nút Debug 🎛️, Nhãn AI Status)
│       ├── farms_tab.dart       (Quản lý nông trại, Ghép nối ESP32, Tạo mạch Debug)
│       ├── alerts_tab.dart      (Cảnh báo AI & Phân tích chuyên sâu)
│       └── profile_tab.dart     (Hồ sơ, Tra cứu ngưỡng AI Mờ & Cài đặt)
├── services/
│   ├── ai_api_service.dart      (Fast-Path 0ms, Circuit Breaker 30s, Render Cold-Start)
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── notification_service.dart (Cooldown 60s thông báo đẩy)
│   └── rtdb_service.dart        (Broadcast Stream Cache, Un-awaited Fast Stream)
└── widgets/
    └── plant_preset_dropdown.dart (Menu chuyển cây & giai đoạn sinh trưởng)
```

---

## 📝 Ghi Chú Phát Triển & Debug

- Các hàm và widget công cụ giả lập kiểm thử trong code được đánh dấu với ghi chú `//Debug function`.
- Bộ quy chuẩn cây trồng ngoại tuyến được lưu tại `assets/plant_presets.txt`.