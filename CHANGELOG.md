# GreenPulse - Nhật Ký Thay Đổi Phiên Bản (Changelog)

Tài liệu này ghi lại toàn bộ lịch sử phát triển, nâng cấp kiến trúc, tối ưu thuật toán và sửa lỗi của hệ sinh thái GreenPulse (Hệ thống Giám sát & Điều khiển Nông nghiệp Thông minh IoT - Mobile App - Edge AI).

---

## [1.2.1] - 2026-09-06

### Ứng dụng di động
* **Added:** Thêm responsive layout để hỗ trợ cho tablet.
* **Refactored:** Chuẩn hóa trợ năng theo chuẩn A11y.
* **Changed:** Đổi font chữ mặc định thành font Be Vietnam Pro.

---

## [1.1.1] - 2026-09-05

### Ứng Dụng Di Động
* **Changed:** Sửa lỗi typo trong `plant_presets`.

---

## [1.1.0] - 2026-09-03

### Phần Cứng & Vi Điều Khiển
* **Added (Giao Diện Cấu Hình Web AP Trực Quan):** Cập nhật trang quản trị SoftAP `192.168.4.1` hiển thị danh sách các mạng đang có trong Queue, cho phép thêm mạng mới và kích hoạt nút "KẾT NỐI NGAY" mà không cần khởi động lại chip.
* **Changed (Dual-Core FreeRTOS Architecture):** Phân chia tác vụ độc lập giữa 2 lõi:
  * **Core 1:** Chuyên trách 100% phần cứng (Đọc tuần tự I2C DHT22, ADS1115, BH1750, Cảm biến Mưa, hiển thị OLED 3 trang và điều khiển 4 Relay/Động cơ rèm).
  * **Core 0:** Chuyên trách kết nối mạng, chạy WebServer cấu hình và đẩy dữ liệu lên Firebase Realtime Database qua HTTPS `PATCH`.
* **Fixed (Khắc Phục Sụt Áp Brownout):** Xử lý triệt để lỗi `E BOD: Brownout detector was triggered` khi truyền sóng WiFi bằng cách giảm công suất phát TX Power (`WIFI_POWER_11dBm`) và ngắt điện 4 cuộn dây động cơ bước ULN2003 (`releaseStepperPins()`) sau khi kéo rèm để chống ngậm dòng.

### Ứng Dụng Di Động
* **Added:** Tích hợp ứng dụng với backend trung gian `greenpulse-auth-web` qua các endpoint `POST /api/auth/send-verification-email` và `POST /api/auth/send-password-reset-email`.
* **Added:** Gửi email kích hoạt tài khoản và đặt lại mật khẩu với giao diện HTML màu xanh lá nông nghiệp `#1B5E20` thông qua Gmail với giao thức bảo mật là Google App Password.
* **Added:** Trang web Custom Email Handler có sẵn thước đo độ mạnh mật khẩu theo thời gian thực (4 cấp độ), nút ẩn/hiện mật khẩu và Deep Link (`greenpulse://open`) tự động quay lại App sau khi hoàn tất.
* **Changed:** Thay đổi toàn bộ bộ icon ứng dụng mới (`@mipmap/ic_launcher`).
* **Fixed:** Sửa lỗi crash tức thì khi khởi chạy file APK Release (`ClassNotFoundException`) do lệch cấu hình `namespace = "com.example.greenpulse"` giữa Gradle và `MainActivity.kt`, đồng thời cấu hình an toàn cho R8 ProGuard.
* **Fixed:** Bọc toàn bộ các hàm bất đồng bộ khởi động dịch vụ (`Firebase.initializeApp`, `NotificationService.init`, `WeatherService.init`, `PlantPresetManager.loadPresets`) trong khối `try-catch` để đảm bảo `runApp()` luôn dựng UI thành công trong mọi điều kiện mạng.

---

## [1.0.0] - 2026-08-30

### Kiến Trúc & Tái Cấu Trúc
* **Refactor:** Chia nhỏ các file giao diện lớn thành kiến trúc thư mục con rõ ràng, áp dụng Clean Code và Design System nhất quán:
  * `lib/screens/tabs/dashboard_tab/`: `DashboardHeader`, `DashboardFarmCard`, `DashboardMetricsView`, `DashboardStatusBadge`.
  * `lib/screens/tabs/farms_tab/`: `FarmCard`, `FarmDialogs`, `SensorRowItem`.
  * `lib/screens/tabs/profile_tab/`: `ProfileHeader`, `ThresholdSettingsCard`, `CropReferenceCard`.
  * `lib/screens/tabs/alerts_tab/`: `AlertItemCard`, `AlertEmptyView`.
  * `lib/screens/login_screen/`: `LoginForm`, `ForgotPasswordDialog`.
  * `lib/screens/verify_email_screen/`: `VerifyEmailHeader`, `VerifyEmailActions`.
* **Refactor:** Tách `WeatherCard` và `LocationPickerDialog` thành các component tái sử dụng độc lập trong thư mục `lib/widgets/weather/`.
* **Refactor:** Tách `weather_model.dart` và `weather_service.dart` thành các submodule: `weather_cache.dart`, `weather_location_presets.dart`, `weather_string_utils.dart`.

### Cơ Sở Dữ Liệu & Bảo Mật
* **Added:** Đưa toàn bộ file quy tắc bảo mật chuẩn vào mã nguồn:
  * `database.rules.json`: Ràng buộc quyền đọc/ghi dữ liệu cảm biến Realtime Database theo đúng định danh `auth.uid == $uid`.
  * `firestore.rules`: Phân quyền quản lý danh sách trang trại (`farms`), thông tin người dùng (`users`) và nhật ký thông báo.
* **Added:** Chuẩn hóa file cơ sở dữ liệu ngưỡng sinh trưởng `plant_presets.txt` cho các cây trồng chủ lực Tây Nguyên (Cà phê Robusta, Sầu riêng, Hồ tiêu, Bơ, Cây ăn trái) qua từng giai đoạn phát triển: Cây con, Phát triển thân lá, Ra hoa, Nuôi quả, Thu hoạch.

---

## [0.9.0] - 2026-08-29

### Ứng Dụng Di Động
* **Fixed:** Hiệu chỉnh toàn bộ các hàm liên thuộc hình tam giác và hình thang (Triangular & Trapezoidal Membership Functions) của 5 thông số môi trường (Nhiệt độ, Độ ẩm không khí, Độ ẩm đất, Ánh sáng, Độ pH) đảm bảo mức độ giao nhau (Overlap) luôn >= 0.5, triệt tiêu hoàn toàn trường hợp không có luật mờ nào kích hoạt.
* **Changed:** Chuẩn hóa độ lệch giá trị đầu ra của bộ suy luận mờ Mamdani từ dải cũ [0.0, 2.0] về dải chuẩn tuyệt đối [0.0, 1.0].
* **Docs:** Xuất tài liệu chuyên sâu giải thích toán học logic mờ Mamdani, ma trận 243 luật mờ và kết quả Benchmark N=200 tập dữ liệu kiểm thử sang file tài liệu Word (.docx).
* **Added:** Tích hợp API thời tiết vệ tinh Open-Meteo cung cấp dữ liệu thời tiết hiện tại, dự báo 24 giờ và xu hướng 7 ngày tới.
* **Added:** Xây dựng bộ suy diễn nông học tự động phân tích thời tiết: cảnh báo sương muối, nắng gắt bốc hơi cao, nguy cơ ngập úng rễ khi mưa lớn và khuyến nghị thời điểm bón phân/tưới tiêu lý tưởng.
* **Added:** Hỗ trợ tìm kiếm địa danh tỉnh thành Việt Nam thông minh, tự động loại bỏ dấu tiếng Việt (`removeDiacritics`) và lưu 10 vị trí gần nhất vào `SharedPreferences`.
* **Fixed:** Bóc tách và hiển thị chuẩn xác chỉ số bức xạ tia cực tím UV Index theo thời gian thực.
* **Changed:** Bổ sung các trường `locationName`, `latitude`, `longitude` vào `FarmModel` để mỗi trang trại có thể theo dõi thời tiết cục bộ riêng biệt.

### Kiểm Thử Tự Động
* **Test:** Viết bộ kiểm thử chuyên sâu cho thuật toán mờ `FuzzyLogicEngine`, đảm bảo tính toán chính xác điểm sức khỏe cây trồng và hành động khuyến nghị.
* **Test:** Viết bộ kiểm thử giao diện cho các màn hình Tab chính, Form đăng nhập/đăng ký và Card đo lường cảm biến.
* **Test:** Xây dựng bộ kiểm thử tích hợp tự động kiểm tra luồng chuyển Tab, mở Dialog chọn địa điểm thời tiết và đổi trang trại.

---

## [0.5.0] - 2026-08-26

### Ứng Dụng Di Động
* **Added:** Tích hợp FCM và Cloud Functions tự động quét dữ liệu cảm biến và gửi Push Notification khẩn cấp khi các chỉ số môi trường vượt ngưỡng nguy hiểm.
* **Added:** Cấu hình `flutter_local_notifications` hiển thị thông báo trên thanh trạng thái điện thoại ngay cả khi ứng dụng đang chạy nền hoặc đã tắt.
* **Added:** Bổ sung tùy chọn điều chỉnh tần suất lặp lại thông báo (1, 2, 5, 10 phút/lần) trong màn hình Cài đặt người dùng, mặc định tối ưu là 5 phút/lần để tránh spam.
* **Changed:**
  * Nâng cấp thư viện Java Desugaring `desugar_jdk_libs: 2.1.4`.
  * Nâng cấp Android Gradle Plugin lên `9.0.1` và Kotlin Compiler lên `2.3.20`.
  * Thêm file `.firebaserc` định danh dự án `greenpulse-daklak`.
  * Tắt chế độ `kotlin.incremental` trong `gradle.properties` để triệt tiêu lỗi khóa cache file giữa các ổ đĩa trên Windows.

---

## [0.3.0] - 2026-08-18

### Ứng Dụng Di Động
* **Added:** Đưa toàn bộ thuật toán đánh giá cây trồng bằng Logic Mờ (Mamdani Fuzzy System) vào chạy trực tiếp trên thiết bị di động (Client-side Dart). Ứng dụng có khả năng đánh giá sức khỏe cây trồng tức thì với độ trễ 0ms, hoạt động trơn tru ngay cả khi mất kết nối Internet.
* **Removed:** Loại bỏ sự phụ thuộc vào các API AI bên ngoài, đưa các file liên quan vào `.gitignore` để tối ưu kích thước ứng dụng và bảo mật thuật toán cốt lõi.
* **Changed:** Bổ sung đầy đủ quyền khai báo truy cập mạng nội bộ và cấp quyền thông báo trong `ios/Runner/Info.plist`.

---

## [0.2.0] - 2026-07-24

### Cơ Sở Dữ Liệu & Bảo Mật
* **Changed:** Tối ưu hóa việc chia sẻ tài nguyên mạng - Cả 4 Tab màn hình chuyển sang dùng chung một Stream duy nhất kết nối tới Firebase Realtime Database, giảm 75% băng thông mạng và loại bỏ hoàn toàn hiện tượng nghẽn kết nối.
* **Added:** Cơ chế tự động làm giàu gói tin cảm biến thô từ RTDB với các kết quả đánh giá mờ và ngưỡng cây trồng trước khi phân phối tới giao diện.
* **Added:** Thêm huy hiệu trạng thái AI động trên Header màn hình Dashboard, hiển thị trạng thái phân tích (Sẵn sàng / Đang kết nối / Offline).
* **Added:** Thêm công cụ tinh chỉnh và giả lập dữ liệu cảm biến ESP32 phục vụ kiểm thử nhanh các kịch bản môi trường khắc nghiệt.

---

## [0.1.0] - 2026-07-24

### Khởi Tạo Dự Án
* **Added:** Khởi tạo khung ứng dụng GreenPulse đa nền tảng bằng Flutter SDK.
* **Added:** Xây dựng luồng đăng nhập, đăng ký tài khoản với Firebase Auth và lưu trữ thông tin chủ vườn vào Firestore `users/{uid}`.
* **Added:** Cơ chế kiểm tra trạng thái kích hoạt tài khoản qua chu kỳ quét tự động mỗi 3 giây `userChanges()`.
* **Added:** Loại bỏ cấu hình cứng `sensor_threshold_config`, chuyển sang cơ chế tải động ngưỡng an toàn môi trường từ file JSON và lưu trữ vào trạng thái ứng dụng.
* **Added:** Thiết kế giao diện Dashboard theo phong cách hiện đại với màu xanh nông nghiệp chủ đạo, thẻ cảm biến trực quan và biểu đồ theo dõi realtime.
* **Added:** Bổ sung giấy phép phần mềm mã nguồn mở MIT License.