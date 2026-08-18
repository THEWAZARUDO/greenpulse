# GreenPulse – Hệ Thống Giám Sát và Phân Tích Nông Nghiệp Thông Minh Ứng Dụng Logic Mờ Trên Nền Tảng IoT

## Tóm tắt

**GreenPulse** là hệ thống giám sát nông nghiệp thông minh tích hợp công nghệ Internet of Things (IoT) và trí tuệ nhân tạo dựa trên Logic Mờ (Fuzzy Logic). Hệ thống thu thập dữ liệu môi trường từ cảm biến vi điều khiển ESP32/ESP8266 theo thời gian thực, thực hiện phân tích đa tham số bằng bộ máy suy diễn mờ Mamdani viết thuần bằng ngôn ngữ Dart (Native Edge AI), và đưa ra cảnh báo cùng khuyến nghị nông học phù hợp với từng loại cây trồng theo từng giai đoạn sinh trưởng.

Ứng dụng di động được phát triển trên framework Flutter, sử dụng hệ sinh thái Firebase làm hạ tầng đám mây (Cloud Firestore và Realtime Database), đảm bảo khả năng đồng bộ dữ liệu thời gian thực và hoạt động ổn định trên cả nền tảng Android và iOS.

---

## 1. Giới thiệu

### 1.1. Đặt vấn đề

Trong sản xuất nông nghiệp hiện đại, việc giám sát và kiểm soát các yếu tố môi trường (nhiệt độ, độ ẩm, ánh sáng, pH đất) đóng vai trò then chốt trong việc tối ưu hóa năng suất và chất lượng cây trồng. Tuy nhiên, phần lớn nông dân Việt Nam vẫn dựa vào kinh nghiệm chủ quan, dẫn đến khó khăn trong việc phát hiện kịp thời các bất thường và đưa ra quyết định canh tác phù hợp.

### 1.2. Mục tiêu đề tài

- Xây dựng hệ thống IoT thu thập dữ liệu cảm biến môi trường theo thời gian thực từ vi điều khiển ESP32/ESP8266.
- Phát triển bộ máy suy diễn mờ Mamdani (Fuzzy Logic Engine) chạy trực tiếp trên thiết bị di động (Edge AI), không phụ thuộc kết nối Internet.
- Thiết kế ứng dụng di động đa nền tảng hiển thị trực quan 5 chỉ số môi trường, đánh giá mức độ rủi ro và sinh lời khuyên nông học tự động theo từng giai đoạn sinh trưởng của cây trồng.
- Tích hợp hệ thống cảnh báo đẩy (Push Notification) khi phát hiện chỉ số vượt ngưỡng nguy hiểm.

### 1.3. Phạm vi nghiên cứu

Hệ thống hiện hỗ trợ 4 loại cây trồng chủ lực vùng Tây Nguyên và Đông Nam Bộ:

| STT | Cây trồng | Số giai đoạn sinh trưởng |
| :-: | :--- | :-: |
| 1 | Cà phê vối (Robusta) | 3 |
| 2 | Hồ tiêu | 3 |
| 3 | Sầu riêng | 5 |
| 4 | Điều | 3 |

---

## 2. Cơ sở lý thuyết

### 2.1. Logic Mờ (Fuzzy Logic)

Logic Mờ là một phương pháp toán học cho phép xử lý thông tin mang tính không chắc chắn, mô phỏng quá trình suy luận của con người thông qua các tập mờ (Fuzzy Sets) và luật suy diễn mờ (Fuzzy Rules). Khác với logic nhị phân (đúng/sai), logic mờ cho phép một phần tử thuộc về một tập hợp với một "độ thuộc" (membership degree) nằm trong khoảng [0, 1].

### 2.2. Hệ suy diễn mờ Mamdani

Hệ thống GreenPulse sử dụng mô hình suy diễn Mamdani gồm 4 giai đoạn:

1. **Mờ hóa (Fuzzification):** Chuyển đổi giá trị đầu vào crisp sang độ thuộc tập mờ thông qua hàm thuộc.
2. **Cơ sở luật (Rule Base):** Tập hợp các luật IF-THEN dạng: "Nếu Nhiệt độ là *Cao* VÀ Độ ẩm đất là *Thấp* THÌ Nguy cơ là *Cao*".
3. **Suy diễn (Inference):** Áp dụng phép toán Min (T-norm) cho mệnh đề tiền đề và cắt hàm thuộc đầu ra.
4. **Giải mờ (Defuzzification):** Chuyển đổi tập mờ đầu ra thành giá trị crisp bằng phương pháp Trọng tâm (Centroid).

### 2.3. Các hàm thuộc sử dụng

Hệ thống sử dụng hai loại hàm thuộc:

**Hàm thuộc Tam giác (Triangular):**

$$\mu(x; a, b, c) = \max\left(\min\left(\frac{x - a}{b - a},\ \frac{c - x}{c - b}\right),\ 0\right)$$

**Hàm thuộc Hình thang (Trapezoidal):**

$$\mu(x; a, b, c, d) = \max\left(\min\left(\frac{x - a}{b - a},\ 1,\ \frac{d - x}{d - c}\right),\ 0\right)$$

### 2.4. Phương pháp Giải mờ Trọng tâm (Centroid Defuzzification)

Điểm nguy cơ đầu ra được tính theo công thức trọng tâm trên lưới rời rạc 200 điểm:

$$z^* = \frac{\sum_{i=1}^{N} z_i \cdot \mu(z_i)}{\sum_{i=1}^{N} \mu(z_i)}, \quad N = 200, \quad z_i \in [0, 100]$$

Trong đó $z^*$ là điểm nguy cơ đầu ra (Risk Score), $z_i$ là giá trị trên lưới rời rạc, và $\mu(z_i)$ là độ thuộc tổng hợp tại điểm $z_i$.

---

## 3. Kiến trúc hệ thống

### 3.1. Sơ đồ tổng quan (Dual-Engine Architecture)

Hệ thống hoạt động theo kiến trúc kết hợp **Edge AI 0ms (khi mở app)** và **Cloud Functions 24/7 (khi đóng app)**:

```
┌─────────────────┐         ┌────────────────────────┐         ┌────────────────────────┐
│   ESP32/ESP8266  │────────▶│  Firebase Realtime DB  │────────▶│  Flutter Mobile App    │
│   (Cảm biến)    │  WiFi   │  (Đồng bộ realtime)    │  Stream │  (Android & iOS)       │
└─────────────────┘         └───────────┬────────────┘         └───────────┬────────────┘
                                        │                                  │
                                        │ Database Trigger                 │ Quản lý dữ liệu & Token
                                        ▼                                  ▼
                            ┌────────────────────────┐         ┌────────────────────────┐
                            │ Firebase Cloud Function│────────▶│  Cloud Firestore       │
                            │ (Backend Serverless)   │  Đọc    │  (Nông trại, Users,    │
                            └───────────┬────────────┘  Token  │   FCM Device Tokens)   │
                                        │                      └────────────────────────┘
                                        ▼ Push 24/7
                            ┌────────────────────────┐
                            │ Google FCM / Apple APNs│────────▶ Màn hình khóa điện thoại
                            │ (Thông báo khi tắt app)│
                            └────────────────────────┘
```

### 3.2. Các thành phần chính

| Thành phần | Công nghệ | Vai trò |
| :--- | :--- | :--- |
| Ứng dụng di động | Flutter 3.x / Dart 3.x | Giao diện người dùng đa nền tảng (Android / iOS) |
| Bộ máy Edge AI | Dart Native (`FuzzyLogicEngine`) | Suy diễn mờ Mamdani cục bộ, phản hồi 0ms khi mở app |
| Đám mây Serverless 24/7 | Firebase Cloud Functions (Node.js) | Lắng nghe thay đổi Realtime DB, phân tích ngưỡng nguy hiểm 24/7 |
| Thông báo đẩy từ xa | Firebase Cloud Messaging (FCM) | Bắn thông báo đẩy về màn hình khóa ngay cả khi đóng app |
| Cơ sở dữ liệu thời gian thực | Firebase Realtime Database | Nhận và phát luồng dữ liệu cảm biến |
| Cơ sở dữ liệu đám mây | Cloud Firestore | Lưu trữ thông tin nông trại, người dùng và FCM Tokens |
| Xác thực | Firebase Authentication | Đăng ký, đăng nhập và bảo mật người dùng |
| Phần cứng IoT | ESP32 / ESP8266 | Thu thập dữ liệu 5 thông số cảm biến môi trường |

### 3.3. Luồng xử lý dữ liệu

- **Trường hợp 1 (Người dùng ĐANG MỞ app):**
  $$\text{ESP32} \xrightarrow{\text{WiFi}} \text{Firebase RTDB} \xrightarrow{\text{Stream}} \text{Flutter App} \xrightarrow{\text{Edge AI}} \text{FuzzyLogicEngine} \xrightarrow{\text{0ms}} \text{Dashboard \& Alerts UI}$$
- **Trường hợp 2 (Ứng dụng ĐANG ĐÓNG / Khóa màn hình):**
  $$\text{ESP32} \xrightarrow{\text{WiFi}} \text{Firebase RTDB} \xrightarrow{\text{Trigger}} \text{Cloud Function} \xrightarrow{\text{Nguy hiểm}} \text{FCM Push} \xrightarrow{\text{24/7}} \text{Màn hình khóa Android/iOS}$$

---

## 4. Thiết kế và cài đặt

### 4.1. Cấu trúc mã nguồn

```
greenpulse/
├── functions/                         # Tầng Đám mây 24/7 (Firebase Cloud Functions)
│   ├── index.js                       # Logic trigger RTDB & gửi push FCM tự động 24/7
│   └── package.json                   # Cấu hình Node.js
│
├── lib/                               # Tầng Ứng dụng Di động (Flutter Client)
│   ├── main.dart                      # Khởi chạy app, Crashlytics & FCM Background Handler
│   ├── firebase_options.dart          # Cấu hình Firebase đa nền tảng
│   │
│   ├── models/                        # Tầng dữ liệu & AI (Data & AI Layer)
│   │   ├── fuzzy_logic_engine.dart    # Bộ máy suy diễn mờ Mamdani Native Dart (0ms)
│   │   ├── ai_evaluation_model.dart   # Mô hình kết quả đánh giá AI
│   │   ├── crop_preset_model.dart     # Mô hình cây trồng & giai đoạn sinh trưởng
│   │   ├── farm_model.dart            # Mô hình nông trại & dữ liệu cảm biến
│   │   ├── plant_preset_manager.dart  # Quản lý bộ quy chuẩn cây trồng
│   │   └── user_model.dart            # Mô hình thông tin người dùng
│   │
│   ├── services/                      # Tầng dịch vụ (Service Layer)
│   │   ├── rtdb_service.dart          # Dịch vụ luồng dữ liệu Realtime Database
│   │   ├── firestore_service.dart     # Quản lý Firestore & FCM Device Tokens
│   │   ├── auth_service.dart          # Xác thực & xoá tài khoản Firebase Auth
│   │   └── notification_service.dart  # Quản lý thông báo cục bộ & thiết lập FCM
│   │
│   ├── screens/                       # Tầng giao diện (Presentation Layer)
│   │   ├── login_screen.dart          # Màn hình đăng nhập
│   │   ├── register_screen.dart       # Màn hình đăng ký
│   │   ├── verify_email_screen.dart   # Màn hình xác thực email
│   │   ├── main_tab_screen.dart       # Thanh điều hướng chính (4 tab)
│   │   ├── provision_screen.dart      # Cấu hình Wi-Fi cho ESP32 qua Access Point
│   │   └── tabs/
│   │       ├── dashboard_tab.dart     # Bảng điều khiển tổng quan
│   │       ├── farms_tab.dart         # Quản lý nông trại & cảm biến
│   │       ├── alerts_tab.dart        # Nhật ký cảnh báo & phân tích chuyên sâu
│   │       └── profile_tab.dart       # Hồ sơ cá nhân, đổi tần suất cảnh báo
│   │
│   └── widgets/                       # Thành phần giao diện tái sử dụng
│       └── plant_preset_dropdown.dart # Menu chọn cây trồng & giai đoạn sinh trưởng
```

### 4.2. Bộ máy suy diễn mờ (`FuzzyLogicEngine`)

Đây là thành phần cốt lõi của hệ thống, được cài đặt hoàn toàn bằng Dart và chạy trực tiếp trên thiết bị di động (Edge Computing) với thời gian thực thi xấp xỉ 0ms.

**Quy trình xử lý gồm 6 bước:**

| Bước | Tên gọi | Mô tả |
| :-: | :--- | :--- |
| 1 | Truy xuất quy chuẩn | Nạp khoảng tối ưu (min, max) của 5 tham số từ bộ preset cây trồng |
| 2 | Tính độ lệch | So sánh giá trị cảm biến thực tế với khoảng tối ưu, sinh hệ số lệch |
| 3 | Mờ hóa (Fuzzification) | Ánh xạ độ lệch vào 3 tập mờ: *Bình thường*, *Cảnh báo*, *Nguy hiểm* |
| 4 | Suy diễn Mamdani | Phép cắt Min có trọng số nông học cho 5 tham số |
| 5 | Hợp thành (Aggregation) | Phép hợp Max trên lưới nguy cơ 200 điểm |
| 6 | Giải mờ (Defuzzification) | Tính Risk Score bằng phương pháp Centroid |

**Trọng số nông học** được gán cho 5 tham số đầu vào:

| Tham số | Trọng số |
| :--- | :-: |
| Độ ẩm đất (Soil Moisture) | 0.25 |
| Nhiệt độ (Temperature) | 0.25 |
| Độ ẩm không khí (Humidity) | 0.20 |
| Độ pH đất (Soil pH) | 0.15 |
| Cường độ ánh sáng (Light/Lux) | 0.15 |

**Phân loại đầu ra:**

| Điểm nguy cơ (Risk Score) | Trạng thái | Kích hoạt cảnh báo |
| :-: | :--- | :-: |
| 0 – 24.9 | An toàn (Normal) | Không |
| 25.0 – 49.9 | Cảnh báo (Warning) | Có |
| 50.0 – 100.0 | Nguy hiểm (Danger) | Có |

### 4.3. Cơ chế ghép nối ESP32 (Wi-Fi Provisioning)

Luồng ghép nối thiết bị IoT:

1. ESP32 phát điểm truy cập Wi-Fi nội bộ (AP) có tên `GreenPulse_Setup_XXXX`.
2. Người dùng kết nối điện thoại vào AP và mở màn hình Provisioning trên ứng dụng.
3. Ứng dụng gửi yêu cầu HTTP POST tới `192.168.4.1/config` chứa thông tin Wi-Fi nhà, UID người dùng, Farm ID và Sensor ID.
4. ESP32 lưu cấu hình vào bộ nhớ NVS, khởi động lại và kết nối Wi-Fi nhà.
5. Từ đó ESP32 tự động gửi dữ liệu cảm biến về Firebase Realtime Database theo đúng đường dẫn `users/{uid}/farms/{farmId}/sensors/{sensorId}`.

### 4.4. Bộ quy chuẩn cây trồng (Plant Presets)

Dữ liệu quy chuẩn được lưu tại `assets/plant_presets.txt` dưới định dạng JSON, bao gồm:

- **Thông tin cây trồng:** Mã cây, tên cây, khoảng pH đất tối ưu.
- **Giai đoạn sinh trưởng:** Mỗi giai đoạn gồm khoảng tối ưu của nhiệt độ, độ ẩm đất, độ ẩm không khí, cường độ ánh sáng (lux), và ghi chú nông học chuyên sâu.

### 4.5. Cơ chế Cảnh báo Đám mây 24/7 (Firebase Cloud Functions & FCM)

Để khắc phục hạn chế hệ điều hành di động (Android / iOS) tạm dừng app khi tắt màn hình, hệ thống trang bị bộ xử lý serverless 24/7:

1. **Trigger tự động:** Cloud Function lắng nghe đường dẫn `/sensors/{uid}/{farmId}/{sensorId}` trên Firebase Realtime Database.
2. **Phân tích ngưỡng:** Đánh giá ngay lập tức các chỉ số môi trường (Nhiệt độ, Độ ẩm đất/KK, pH, Ánh sáng) khi có dữ liệu mới.
3. **Chống lặp (Cooldown):** Kiểm tra thời điểm gửi thông báo gần nhất để tránh spam thông báo liên tục (giãn cách tối thiểu 3 phút).
4. **Push Notification:** Gửi tin nhắn cảnh báo qua **Firebase Cloud Messaging (FCM)** trực tiếp đến `fcmToken` của thiết bị người dùng.

---

## 5. Hướng dẫn cài đặt và vận hành

### 5.1. Yêu cầu hệ thống

- Flutter SDK phiên bản 3.12.0 trở lên
- Dart SDK phiên bản 3.0.0 trở lên
- Node.js phiên bản 18+ (phục vụ Firebase Cloud Functions)
- Firebase CLI (`npm install -g firebase-tools`)
- Android Studio hoặc Visual Studio Code
- Thiết bị di động thực hoặc trình giả lập (Android Emulator / iOS Simulator)

### 5.2. Các bước triển khai

#### 1. Triển khai Ứng dụng Di động (Flutter App):
```bash
# 1. Clone mã nguồn
git clone https://github.com/THEWAZARUDO/greenpulse.git
cd greenpulse

# 2. Cài đặt các gói phụ thuộc
flutter pub get

# 3. Kiểm tra tính đúng đắn của mã nguồn
flutter analyze

# 4. Chạy ứng dụng trên thiết bị Android / Giả lập
flutter run
```

#### 2. Triển khai Đám mây 24/7 (Firebase Cloud Functions):
```bash
# 1. Đăng nhập Firebase
firebase login

# 2. Triển khai Cloud Function lên dự án Firebase
firebase deploy --only functions
```


### 5.3. Kiểm thử không cần phần cứng

Ứng dụng tích hợp bộ công cụ giả lập cảm biến (đánh dấu bằng chú thích `//Debug function` trong mã nguồn). Người dùng có thể nhấn nút giả lập trên giao diện Dashboard để thay đổi dữ liệu cảm biến và quan sát phản hồi tức thì của bộ máy AI Mờ mà không cần kết nối thiết bị ESP32 thật.

---

## 6. Kết luận

Hệ thống GreenPulse đã đạt được các mục tiêu đề ra:

- **Giám sát thời gian thực:** Thu thập và hiển thị dữ liệu 5 chỉ số môi trường từ cảm biến ESP32 thông qua Firebase Realtime Database.
- **Phân tích AI cục bộ:** Bộ máy suy diễn mờ Mamdani chạy hoàn toàn trên thiết bị di động với thời gian xử lý xấp xỉ 0ms, không phụ thuộc kết nối Internet.
- **Khuyến nghị nông học tự động:** Hệ thống tự động sinh lời khuyên chuyên sâu theo từng loại cây trồng và giai đoạn sinh trưởng.
- **Cảnh báo kịp thời:** Phát thông báo đẩy tự động khi phát hiện chỉ số vượt ngưỡng nguy hiểm.

---

## Giấy phép

Dự án được phân phối dưới giấy phép MIT. Xem file [LICENSE](LICENSE) để biết thêm chi tiết.