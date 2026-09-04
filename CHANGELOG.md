# 🌿 GreenPulse - Nhật Ký Thay Đổi Phiên Bản (Changelog)

Tất cả các thay đổi quan trọng của dự án **GreenPulse (Hệ sinh thái Nông nghiệp Thông minh IoT & Mobile App)** sẽ được ghi chép chi tiết trong tài liệu này.

Định dạng tài liệu tuân theo chuẩn [Keep a Changelog](https://keepachangelog.com/vi/1.0.0/) và phiên bản áp dụng quy chuẩn [Semantic Versioning](https://semver.org/).

---

## [1.1.0] - 2026-09-03

### 🎨 Ứng dụng Di động (Mobile App)
* **Added:** Tích hợp luồng xác thực tài khoản và đặt lại mật khẩu tùy chỉnh qua Backend trung gian `greenpulse-auth-web` (Brevo SMTP & Vercel Custom UI).
* **Added:** Bổ sung giao diện đặt lại mật khẩu với thước đo độ mạnh mật khẩu theo thời gian thực và hỗ trợ Deep Link (`greenpulse://open`) quay lại ứng dụng.
* **Changed:** Cập nhật bộ nhận diện thương hiệu App Icon mới (`@mipmap/ic_launcher`).
* **Changed:** Nâng cấp số phiên bản ứng dụng lên `1.1.0+2` trong `pubspec.yaml`.
* **Fixed:** Khắc phục triệt để lỗi sập ứng dụng khi vừa mở trên bản APK Release (`ClassNotFoundException`) do lệch `namespace` và cơ chế nén mã nguồn R8.
* **Security:** Bọc cơ chế bảo vệ `try-catch` toàn diện cho các dịch vụ nền khi khởi động ứng dụng trong `main.dart`.

### ⚡ Phần cứng & Firmware (ESP32-S3)
* **Added:** Triển khai cơ chế **AutoProvision đa mạng theo hàng đợi (Queue tối đa 10 mạng)** chạy trên RAM, loại bỏ hoàn toàn sự phức tạp của EEPROM.
* **Added:** Tích hợp thuật toán quét sóng thông minh (Auto-scan RSSI), tự động phát hiện và kết nối với mạng WiFi khả dụng có vạch sóng mạnh nhất.
* **Added:** Hỗ trợ kết nối các điểm phát sóng 4G/5G cá nhân (OPPO, iPhone, Android) và mạng ẩn.
* **Changed:** Tách kiến trúc xử lý sang **Dual-Core FreeRTOS** (Core 1: Cảm biến & OLED chạy tuần tự 100%; Core 0: Mạng WiFi & Firebase).
* **Fixed:** Xử lý triệt để lỗi sụt áp nguồn `E BOD: Brownout detector was triggered` khi phát sóng WiFi; tối ưu chân cuộn dây động cơ bước ULN2003 chống ngậm dòng.

---

## [1.0.0] - 2026-08-30

### 🏗️ Cấu trúc & Tối ưu hóa (Architecture & Refactoring)
* **Refactor:** Phân tách và module hóa toàn bộ các màn hình chính thành các Widget độc lập:
  * `DashboardTab`: Header, Farm Card, Sensor Metrics View, Status Badge.
  * `FarmsTab`: Farm Dialogs, Management Card, Sensor Row.
  * `ProfileTab`: Profile Header, Threshold Settings, Reference Card.
  * `AlertsTab`: Alert Card, Empty View.
  * `LoginScreen`, `RegisterScreen`, `VerifyEmailScreen`.
* **Refactor:** Tách nhỏ bộ Widget dự báo thời tiết và Dialog tìm kiếm địa danh thông minh.
* **Added:** Cập nhật bộ cấu hình ngưỡng an toàn sinh trưởng cây trồng đa giai đoạn (`plant_presets.txt`).
* **Security:** Cập nhật bộ quy tắc bảo mật (Security Rules) cho Firebase Firestore và Realtime Database.
* **Test:** Bổ sung bộ kiểm thử tự động Integration Tests (điều hướng & luồng thời tiết) và Widget Tests cho các thành phần giao diện cốt lõi.

---

## [0.9.0] - 2026-08-28

### 🧠 Edge AI & Dịch vụ Thời tiết (Weather & Fuzzy Logic)
* **Added:** Tích hợp API dự báo thời tiết Open-Meteo và tính toán chỉ số bức xạ UV Index tức thời.
* **Added:** Tính năng tìm kiếm địa danh nông nghiệp thông minh, tự động chuẩn hóa tiếng Việt không dấu và lưu lịch sử 10 địa điểm gần nhất qua `SharedPreferences`.
* **Fixed:** Hiệu chỉnh các hàm liên thuộc (Membership Functions) của bộ suy luận mờ Mamdani, xóa bỏ vùng chết (Dead Zones) và chuẩn hóa biên độ lệch về $[0.0, 1.0]$.
* **Docs:** Xuất tài liệu kiến trúc hệ thống và giải thích logic mờ chi tiết sang định dạng Word (`.docx`).
* **Test:** Xây dựng bộ Unit Test chuyên sâu cho Edge AI Fuzzy Engine và các mô hình dữ liệu.

---

## [0.5.0] - 2026-08-19

### 🔔 Thông báo & Nền tảng (Push Notifications & Platform)
* **Added:** Tích hợp Firebase Cloud Messaging (FCM) & `flutter_local_notifications` cảnh báo vượt ngưỡng môi trường 24/7.
* **Added:** Tùy chỉnh tần suất gửi cảnh báo linh hoạt (1 đến 10 phút/lần) trong Cài đặt.
* **Changed:** Nâng cấp thư viện Java Desugaring (`desugar_jdk_libs: 2.1.4`), Android Gradle Plugin (AGP 9.0.1) và Kotlin 2.3.20.
* **Added:** Cấu hình định danh `.firebaserc` và chuẩn hóa quyền thông báo trên Android 13+ (TIRAMISU).

---

## [0.1.0] - 2026-07-24

### 🚀 Khởi tạo Dự án (Initial Release)
* **Added:** Khởi tạo kiến trúc nền tảng GreenPulse IoT & Mobile Application.
* **Added:** Thiết lập kết nối thời gian thực Firebase Realtime Database đồng bộ dữ liệu cảm biến (Nhiệt độ, Độ ẩm không khí, Độ ẩm đất, Ánh sáng, Độ pH, Mưa).
* **Added:** Tích hợp bộ giải thuật đánh giá nhanh Fast-path 0ms và kết nối dịch vụ AI phân tích sức khỏe cây trồng.
