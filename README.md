# GreenPulse

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20RTDB%20%7C%20FCM-FFCA28?logo=firebase)](https://firebase.google.com)
[![Open-Meteo](https://img.shields.io/badge/Weather-Open--Meteo%20API-00B0FF)](https://open-meteo.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Hệ thống giám sát nông nghiệp thông minh IoT kết hợp **Bộ suy diễn Mờ (Fuzzy Logic Edge AI)** và **Dự báo Thời tiết Nông học** đa nền tảng (Android / iOS / Cloud 24/7).

---

## 1. Kiến trúc Hệ thống (System Architecture)
GreenPulse vận hành theo mô hình **Dual-Engine Architecture**:

```
 ┌──────────────────────┐         ┌───────────────────────────┐         ┌───────────────────────────┐
 │    ESP32 / Sensors   │───────▶│  Firebase Realtime DB     │───────▶│    Flutter Mobile App     │
 │  (Temp, Hum, Soil,   │  WiFi   │  (users/{uid}/farms/...)  │  Stream │  - Edge AI Mamdani (0ms)  │
 │   Light, pH)         │         └─────────────┬─────────────┘         │  - Open-Meteo Forecast    │
 └──────────────────────┘                       │                       │  - Farm & Sensor Controls │
                                                │ Trigger               └─────────────┬─────────────┘
                                                ▼                                     │
                                    ┌───────────────────────┐                         ▼
                                    │ Firebase Cloud Func   │───────────────▶ Cloud Firestore
                                    │ (Node.js Serverless)  │  FCM Tokens    (Farms, Users, Config)
                                    └───────────┬───────────┘
                                                │ Push 24/7
                                                ▼
                                    ┌───────────────────────┐
                                    │ Google FCM / APNs     │───────────────▶ Màn hình khóa thiết bị
                                    └───────────────────────┘
```

### Công nghệ sử dụng:
- **Mobile Client**: Flutter 3.x, Dart 3.x (Clean Component Architecture).
- **Edge AI**: Dart Native Mamdani Fuzzy Inference Engine (thời gian tính toán < 1ms, chạy offline).
- **Dự báo Thời tiết**: Open-Meteo Forecast & Geocoding REST API (Cache TTL 15m, không phụ thuộc API key).
- **Backend & Realtime**: Firebase Realtime Database, Cloud Firestore, Cloud Functions (Node.js 18+), Firebase Cloud Messaging.
- **Hardware Layer**: ESP32 SoC, Wi-Fi SoftAP Provisioning.

---

## 2. Các Module Tính Năng Chính

### 2.1. Bộ máy suy diễn Mờ (Fuzzy Logic Edge AI)
- **Đầu vào (5 tham số):** Nhiệt độ không khí, Độ ẩm không khí, Độ ẩm đất, Cường độ ánh sáng (lux), Độ pH đất.
- **Cơ sở tri thức động (`assets/plant_presets.txt`):** Hỗ trợ quy chuẩn đa giai đoạn cho các loại cây chủ lực (Cà phê Robusta, Hồ tiêu, Sầu riêng, Điều...).
- **Quy trình:** Fuzzification (Hàm thuộc tam giác & hình thang) $\rightarrow$ Trọng số nông học $\rightarrow$ Suy diễn Mamdani $\rightarrow$ Defuzzification Trọng tâm (Centroid) $\rightarrow$ Điểm nguy cơ (**Risk Score 0–100**).

| Mức độ | Risk Score | Hành vi hệ thống |
| :--- | :---: | :--- |
| **Normal (An toàn)** | 0 – 24.9 | Trạng thái bình thường |
| **Warning (Cảnh báo)** | 25.0 – 49.9 | Cảnh báo giao diện, gợi ý điều chỉnh vi khí hậu |
| **Danger (Nguy hiểm)** | 50.0 – 100.0 | Kích hoạt Red Alert Mode trên App & Push Notification 24/7 |

### 2.2. Tích hợp Dự báo Thời tiết Nông học (`WeatherService` & `AgriWeatherAdvisor`)
- **API Nguồn:** Open-Meteo REST API (miễn phí, dữ liệu cập nhật theo tọa độ địa lý).
- **Khả năng cung cấp:**
  - Thời tiết hiện tại: Nhiệt độ, độ ẩm, tốc độ gió, chỉ số UV, lượng mưa, WMO Weather Code.
  - Dự báo 24 giờ tới (Hourly Timeline) & 7 ngày tới (Daily Range).
- **AgriWeatherAdvisor:** Phân tích vi khí hậu và tự động đưa ra khuyến nghị tác vụ canh tác (hoãn tưới/phun thuốc khi sắp mưa, tăng độ che phủ khi UV cao, phòng trừ nấm bệnh khi độ ẩm vượt 88%).
- **Geocoding & Farm Mapping:** Hỗ trợ tìm kiếm địa điểm và gán vị trí địa lý riêng cho từng nông trại.

### 2.3. Cảnh báo Đám mây 24/7 (Serverless Background Alert)
- Cloud Function giám sát liên tục luồng dữ liệu RTDB khi người dùng tắt app hoặc khóa màn hình.
- Cơ chế Cooldown 3 phút chống spam thông báo khi cảm biến liên tục ở ngưỡng dao động nguy hiểm.

### 2.4. ESP32 Wi-Fi Provisioning
- Ghép nối thiết bị không cần nạp lại firmware: ESP32 phát SoftAP $\rightarrow$ App gửi cấu hình Wi-Fi + UID + Farm ID qua HTTP POST `192.168.4.1/config`.

---

## 3. Cấu trúc Thư mục Dự án

```
greenpulse/
├── functions/                         # Firebase Cloud Functions (Node.js)
│   ├── index.js                       # RTDB Trigger & FCM Push Handler 24/7
│   └── package.json
│
├── lib/                               # Flutter Application Source
│   ├── main.dart                      # App Entrypoint, Crashlytics & Background Setup
│   ├── firebase_options.dart          # Firebase Multi-platform Config
│   │
│   ├── models/                        # Data & AI Models
│   │   ├── ai_evaluation_model.dart   # Model kết quả đánh giá AI
│   │   ├── crop_preset_model.dart     # Model cấu hình cây trồng theo giai đoạn
│   │   ├── farm_model.dart            # Model Nông trại (tọa độ, sensors)
│   │   ├── fuzzy_logic_engine.dart    # Mamdani Fuzzy Engine Native Dart (0ms)
│   │   ├── plant_preset_manager.dart  # Quản lý nạp bộ quy chuẩn JSON
│   │   ├── user_model.dart            # Model người dùng & profile
│   │   └── weather_model.dart         # Model dự báo thời tiết, WMO & AgriAdvisor
│   │
│   ├── services/                      # Service Layer
│   │   ├── ai_api_service.dart        # Hybrid Edge-Cloud AI Service
│   │   ├── auth_service.dart          # Firebase Authentication
│   │   ├── firestore_service.dart     # Firestore CRUD (Farms, Users, FCM Tokens)
│   │   ├── notification_service.dart  # Local Notification & FCM Receiver
│   │   ├── rtdb_service.dart          # Realtime Database Sensor Streams
│   │   └── weather_service.dart       # Open-Meteo Client & Geocoding
│   │
│   ├── screens/                       # Presentation Layer (UI)
│   │   ├── login_screen.dart          # Đăng nhập
│   │   ├── register_screen.dart       # Đăng ký
│   │   ├── verify_email_screen.dart   # Xác thực email
│   │   ├── main_tab_screen.dart       # Thanh điều hướng chính & Red Alert Banner
│   │   ├── provision_screen.dart      # Cấu hình SoftAP ESP32
│   │   └── tabs/
│   │       ├── dashboard_tab.dart     # Dashboard tổng quan + WeatherCard
│   │       ├── farms_tab.dart         # Quản lý Nông trại & gán vị trí địa lý
│   │       ├── alerts_tab.dart        # Nhật ký & chi tiết khuyến nghị AI
│   │       └── profile_tab.dart       # Cài đặt người dùng & tần suất cảnh báo
│   │
│   └── widgets/                       # Reusable Widgets
│       ├── location_picker_dialog.dart# Modal chọn địa điểm & vùng nông nghiệp
│       ├── plant_preset_dropdown.dart # Dropdown chọn cây trồng & giai đoạn
│       └── weather_card.dart          # Thẻ dự báo thời tiết nông nghiệp
│
├── assets/
│   └── plant_presets.txt              # Dataset quy chuẩn nông học (JSON)
│
└── test/
    ├── weather_test.dart              # Unit test Weather Model & Agri Advisor
    └── widget_test.dart               # UI initialization test
```

---

## 4. Đặc tả Dữ liệu Realtime Database (RTDB Schema)

```json
{
  "users": {
    "<UID>": {
      "farms": {
        "<FARM_ID>": {
          "sensors": {
            "<SENSOR_ID>": {
              "id": "sensor_1",
              "cropId": "robusta_coffee",
              "stageId": 1,
              "temperature": 27.5,
              "humidity": 78.0,
              "soil": 65.0,
              "light": 12500,
              "ph": 6.2,
              "timestamp": 1724578900000
            }
          }
        }
      }
    }
  }
}
```

---

## 5. Hướng dẫn Cài đặt & Triển khai

### 5.1. Yêu cầu môi trường
- **Flutter SDK**: `>= 3.12.0`
- **Dart SDK**: `>= 3.0.0`
- **Node.js**: `>= 18.x` & `firebase-tools` CLI
- **Thiết bị**: Android (minSdk 21) / iOS (13.0+)

### 5.2. Chạy Ứng dụng Flutter
```bash
# 1. Clone repo
git clone https://github.com/THEWAZARUDO/greenpulse.git
cd greenpulse

# 2. Cài đặt dependencies
flutter pub get

# 3. Kiểm tra mã nguồn
flutter analyze

# 4. Chạy kiểm thử tự động
flutter test

# 5. Khởi chạy ứng dụng
flutter run
```

### 5.3. Triển khai Firebase Cloud Functions
```bash
cd functions
npm install
firebase login
firebase deploy --only functions
```

---

## 6. Kiểm thử (Testing)

Dự án bao gồm bộ kiểm thử đơn vị tự động bao phủ logic suy diễn mờ và bộ phân tích thời tiết:

```bash
# Chạy toàn bộ test suite
flutter test

# Chạy riêng bộ test thời tiết & khuyến nghị nông học
flutter test test/weather_test.dart
```

---

## 7. Giấy phép (License)

Phát hành theo giấy phép [MIT](LICENSE).