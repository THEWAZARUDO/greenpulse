const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function Trigger 24/7:
 * Tự động kích hoạt khi có bản ghi cảm biến mới được đẩy lên Firebase Realtime Database
 * Đường dẫn: /sensors/{uid}/{farmId}/{sensorId}
 */
exports.onSensorDataUpdated = functions.database
  .ref("/sensors/{uid}/{farmId}/{sensorId}")
  .onWrite(async (change, context) => {
    // 1. Kiểm tra nếu dữ liệu bị xoá (Delete event) thì bỏ qua
    if (!change.after.exists()) {
      return null;
    }

    const { uid, farmId, sensorId } = context.params;
    const sensorData = change.after.val();

    if (!sensorData) return null;

    const temp = parseFloat(sensorData.temperature ?? sensorData.temp ?? 0);
    const humidity = parseFloat(sensorData.humidity ?? 0);
    const soil = parseFloat(sensorData.soil ?? 0);
    const light = parseFloat(sensorData.light ?? 0);
    const ph = parseFloat(sensorData.ph ?? 7.0);

    // 2. Đánh giá ngưỡng nguy hiểm 24/7
    const dangerReasons = [];
    if (temp > 38.0) {
      dangerReasons.push(`Nhiệt độ quá cao (${temp.toFixed(1)}°C > 38°C)`);
    } else if (temp < 12.0 && temp > 0) {
      dangerReasons.push(`Nhiệt độ quá lạnh (${temp.toFixed(1)}°C < 12°C)`);
    }

    if (soil < 20.0) {
      dangerReasons.push(`Đất quá khô (${soil.toFixed(1)}% < 20%). Cần tưới ngay!`);
    } else if (soil > 92.0) {
      dangerReasons.push(`Đất bị ngập úng (${soil.toFixed(1)}% > 92%)`);
    }

    if (humidity < 25.0) {
      dangerReasons.push(`Ẩm độ không khí khô (${humidity.toFixed(1)}%)`);
    } else if (humidity > 95.0) {
      dangerReasons.push(`Độ ẩm quá cao (${humidity.toFixed(1)}%), nguy cơ nấm bệnh`);
    }

    if (ph < 4.5) {
      dangerReasons.push(`Đất bị chua nặng (pH ${ph.toFixed(1)} < 4.5)`);
    } else if (ph > 8.5) {
      dangerReasons.push(`Đất bị kiềm hóa (pH ${ph.toFixed(1)} > 8.5)`);
    }

    // Nếu các chỉ số đều an toàn -> không cần gửi thông báo
    if (dangerReasons.length === 0) {
      return null;
    }

    // 3. Lấy FCM Token của người dùng từ Firestore (/users/{uid})
    const userDoc = await admin.firestore().collection("users").doc(uid).get();
    if (!userDoc.exists) {
      console.log(`[FCM] Không tìm thấy user document cho UID: ${uid}`);
      return null;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`[FCM] User ${uid} chưa đăng ký FCM Token trên thiết bị.`);
      return null;
    }

    // 4. Kiểm tra Cooldown tránh spam thông báo liên tục (giãn cách tối thiểu 3 phút)
    const lastAlertTime = userData?.lastFcmAlertTime?.toMillis?.() || 0;
    const now = Date.now();
    if (now - lastAlertTime < 3 * 60 * 1000) {
      console.log(`[FCM] Cooldown: Vừa gửi thông báo cách đây chưa đầy 3 phút. Bỏ qua.`);
      return null;
    }

    // 5. Soạn tin nhắn Push Notification
    const title = `🚨 [CẢNH BÁO NGUY HIỂM] Mạch ${sensorId}`;
    const body = dangerReasons.join(". ");

    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        farmId: farmId,
        sensorId: sensorId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "greenpulse_alerts_channel",
          sound: "default",
          priority: "max",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    // 6. Gửi thông báo đẩy qua Firebase Cloud Messaging và cập nhật mốc thời gian
    try {
      const response = await admin.messaging().send(message);
      console.log(`[FCM] Gửi thành công tới user ${uid}: ${response}`);

      await admin.firestore().collection("users").doc(uid).set(
        {
          lastFcmAlertTime: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    } catch (error) {
      console.error(`[FCM Error] Lỗi khi gửi thông báo:`, error);
    }

    return null;
  });
