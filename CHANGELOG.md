# 📜 GreenPulse - Nhật ký Thay đổi Phiên bản (Changelog)

Tất cả các thay đổi, nâng cấp và sửa lỗi của dự án **GreenPulse Smart Agriculture** được ghi lại chi tiết trong tài liệu này theo chuẩn [Keep a Changelog](https://keepachangelog.com/vi/1.0.0/) và [Semantic Versioning](https://semver.org/).

---

## [1.1.0] - 2026-09-03

### ✨ Tính năng mới (Added)
- **Hệ thống AutoProvision Đa mạng ESP32 (`8f0aec6`, `967c0ff`):**
  - Hỗ trợ lưu danh sách hàng đợi (Queue) lên tới **10 mạng WiFi** mà không cần phụ thuộc EEPROM.
  - Tự động quét sóng xung quanh và ưu tiên kết nối mạng có cường độ tín hiệu tốt nhất (RSSI cao nhất).
  - Tự động kết nối điểm phát sóng 4G/5G cá nhân (OPPO, iPhone, Android) và các mạng ẩn.
- **Tích hợp Backend Xác thực `greenpulse-auth-web` (`1bfa5c9`):**
  - Gửi email kích hoạt tài khoản và đặt lại mật khẩu với giao diện tùy chỉnh thương hiệu GreenPulse qua Brevo Mailer.
  - Trang Web Action Handler chuyên biệt có đồng hồ đo độ mạnh mật khẩu realtime và deep link `greenpulse://open` quay lại ứng dụng.
  - Cơ chế tự động Fallback về Firebase Auth native khi mất kết nối backend.
- **Bộ Nhận diện Thương hiệu & Icon mới (`00d3fe7`, `5118fa2`):**
  - Cập nhật bộ App Launcher Icon mới đồng bộ với tông màu nông nghiệp hiện đại.

### 🐛 Sửa lỗi (Fixed)
- **Sửa lỗi sập ứng dụng khi mở file APK Release (`b4e55b3`):**
  - Đồng bộ `namespace` (`com.example.greenpulse`) khớp với `MainActivity.kt`, `google-services.json` và `applicationId`.
  - Tắt R8/ProGuard Resource Shrinking gây xóa nhầm các class reflection Firebase.
- **Chống sập nguồn Brownout trên ESP32-S3:**
  - Bổ sung tài liệu và cấu hình hạ công suất phát sóng `WiFi.setTxPower(WIFI_POWER_11dBm)` và cơ chế ngắt cuộn dây động cơ bước ULN2003.

---

## [1.0.0] - 2026-08-30

### ✨ Tính năng mới (Added)
- **Hệ thống Dự báo Thời tiết Nông nghiệp Thông minh (`8278f05`, `8c59fc9`, `7fb60af`):**
  - Tích hợp API Open-Meteo lấy thông số nhiệt độ, độ ẩm, xác suất mưa, chỉ số UV và tốc độ gió.
  - Tìm kiếm địa danh thông minh với từ điển chuẩn hóa tiếng Việt không dấu (Alias).
  - Lưu lịch sử 10 địa điểm chọn gần nhất qua `SharedPreferences`.
- **Bộ suy luận Edge AI Fuzzy Logic Mamdani (`cc423c3`, `57ad61d`, `3ddd932`):**
  - Tích hợp động cơ suy luận mờ $N=200$ luật Mamdani chạy cục bộ 0ms đánh giá nguy cơ dịch bệnh và stress môi trường.
  - Đánh giá đa chiều 5 thông số: Nhiệt độ, Độ ẩm không khí, Độ ẩm đất, Ánh sáng (Lux) và Độ pH.
- **Hệ thống Cảnh báo Đẩy 24/7 (`798a756`, `ee6242c`, `5e99694`):**
  - Tích hợp Firebase Cloud Messaging (FCM) và `flutter_local_notifications`.
  - Hỗ trợ tùy chỉnh tần suất thông báo cảnh báo cảm biến (1 đến 10 phút/lần).
- **Phân tách Kiến trúc Module hóa (`c9f3e64`, `484433e`, `17a5a0c`, `e053652`):**
  - Chia nhỏ các màn hình Dashboard, Farms, Profile, Alerts, Login, Provision thành các widget con độc lập, dễ bảo trì.
- **Bộ Kiểm thử Toàn diện (`fe14378`, `8cd14cc`, `ba6d617`):**
  - Bổ sung Integration Tests cho luồng điều hướng và thời tiết.
  - Bổ sung Unit Tests & Widget Tests cho mô hình AI và các thành phần giao diện cốt lõi.

### 📝 Tài liệu & Quy tắc (Documentation & Rules)
- Xuất tài liệu kiến trúc kỹ thuật hệ thống ra file Word `.docx` (`1895511`, `d508624`).
- Cập nhật bộ quy tắc bảo mật `firestore.rules` và `database.rules.json` (`020fd69`).

---

## [0.2.0] - 2026-07-24

### ⚡ Cải tiến & Tối ưu (Improvements)
- **Tối ưu hóa Luồng Stream Dữ liệu (`8ed20cd`):**
  - Đồng bộ toàn bộ 4 Tab chia sẻ chung duy nhất một Stream kết nối tới Firebase Realtime Database.
- **Fast-path AI & Circuit Breaker (`505480f`, `265dfd5`, `e7f38a8`):**
  - Hỗ trợ phản hồi nhanh 0ms với Cache trong bộ nhớ và cơ chế tự động gửi background wake-up đánh thức server Render.com.
- **Dữ liệu Ngưỡng Động (`757b09e`, `e4174cb`):**
  - Chuyển đổi toàn bộ cấu hình ngưỡng cây trồng từ mã cứng sang file JSON đa giai đoạn `assets/plant_presets.txt`.

---

## [0.1.0] - 2026-07-22

### 🚀 Khởi tạo Dự án (Initial Release)
- **Khởi tạo nền tảng ứng dụng GreenPulse Flutter (`3175785`):**
  - Thiết lập kiến trúc giao diện người dùng Material 3 với bảng màu xanh lá nông nghiệp `#2E7D32`.
- **Hệ thống Xác thực Người dùng (`41e4d71`, `c8a65c1`):**
  - Tính năng Đăng nhập, Đăng ký và Quên mật khẩu qua Firebase Auth.
  - Lắng nghe trạng thái đăng nhập tự động qua Stream `userChanges()`.
- **Quản lý Tài liệu & Giấy phép (`5209fe1`, `8089b21`, `fbe0c59`):**
  - Khởi tạo `README.md` và giấy phép nguồn mở `LICENSE`.
