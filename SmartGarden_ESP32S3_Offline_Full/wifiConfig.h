#ifndef WIFI_CONFIG_H
#define WIFI_CONFIG_H

#include <ArduinoJson.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Ticker.h>

#define MAX_WIFI_QUEUE 10

struct WiFiCredential {
  String ssid;
  String password;
};

WebServer webServer(80);
Ticker blinker;

// Thông tin mặc định định danh người dùng / thiết bị
String uid = "user_default";
String farmId = "farm_01";
String sensorId = "sensor_01";

#define ledPin 2
#define btnPin 0
unsigned long lastTimePress = 0;
#define PUSHTIME 5000

int wifiMode = 0; // 0: AP Config, 1: Connected, 2: Auto-Scanning/Reconnecting
volatile bool needReconnect = false;
unsigned long lastReconnectAttempt = 0;
int retryCount = 0;
const int MAX_RETRY_PER_NET = 3;
unsigned long blinkTime = 0;

const char html[] PROGMEM = R"html(
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GREENPULSE AUTO PROVISION</title>
    <style>
      body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; background-color: #f4f7f6; margin: 0; padding: 20px; }
      .box { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); width: 100%; max-width: 350px; }
      h3 { text-align: center; color: #2E7D32; margin-top: 0; }
      label { font-weight: bold; font-size: 13px; color: #333; }
      input, select { width: 100%; height: 36px; margin: 5px 0 12px 0; border: 1px solid #ccc; border-radius: 5px; box-sizing: border-box; padding: 0 8px; font-size: 14px; }
      button { width: 48%; height: 40px; border: none; border-radius: 5px; font-weight: bold; cursor: pointer; color: white; margin-top: 5px; }
      .btn-save { background-color: #2E7D32; float: left; }
      .btn-reset { background-color: #d32f2f; float: right; }
      #info { font-size: 12px; text-align: center; color: #666; margin-bottom: 12px; }
      .queue-box { background: #e8f5e9; border: 1px solid #c8e6c9; border-radius: 6px; padding: 8px; margin-bottom: 12px; font-size: 12px; max-height: 120px; overflow-y: auto; }
      .queue-item { margin: 3px 0; padding-bottom: 3px; border-bottom: 1px dashed #a5d6a7; }
    </style>
</head>
<body>
  <div class="box">
    <h3>🌱 GREENPULSE AUTO-PROVISION</h3>
    <div id="queue-display" class="queue-box">
      <strong>Danh sách mạng trong Queue (Tối đa 10):</strong>
      <div id="queue-list">Đang tải...</div>
    </div>
    <p id="info">Đang quét WiFi gần bạn...</p>
    <label>Thêm WiFi mới vào Queue:</label>
    <select id="ssid" onchange="checkCustomSSID()"><option value="">Đang quét...</option></select>
    <input id="custom_ssid" type="text" placeholder="Hoặc nhập tên SSID thủ công..." style="display:none;">
    <label>Mật khẩu WiFi:</label>
    <input id="password" type="password" placeholder="Mật khẩu WiFi">
    <hr style="border: 0; border-top: 1px solid #eee; margin: 10px 0;">
    <label>Firebase UID:</label>
    <input id="uid" type="text" placeholder="UID chủ tài khoản">
    <label>Farm ID:</label>
    <input id="farmid" type="text" placeholder="VD: farm_01">
    <label>Sensor ID:</label>
    <input id="sensorid" type="text" placeholder="VD: sensor_01">
    <div>
      <button class="btn-save" onclick="saveWifi()">THÊM VÀO QUEUE</button>
      <button class="btn-reset" onclick="reConnect()">KẾT NỐI NGAY</button>
    </div>
  </div>
  <script>
    window.onload = function() { scanWifi(); loadQueue(); }
    var xhttp = new XMLHttpRequest();
    function scanWifi() {
      xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
          document.getElementById("info").innerHTML = "Đã quét xong danh sách WiFi!";
          var obj = JSON.parse(this.responseText);
          var select = document.getElementById("ssid");
          select.innerHTML = "<option value='--custom--'>-- Nhập tên khác (Điểm phát 4G/Ẩn) --</option>";
          for(var i=0; i<obj.length; ++i) {
            select.options[select.options.length] = new Option(obj[i], obj[i]);
          }
        }
      };
      xhttp.open("GET", "/scanWifi", true);
      xhttp.send();
    }
    function checkCustomSSID() {
      var select = document.getElementById("ssid");
      var customInput = document.getElementById("custom_ssid");
      if (select.value === "--custom--") {
        customInput.style.display = "block";
      } else {
        customInput.style.display = "none";
      }
    }
    function loadQueue() {
      var qHttp = new XMLHttpRequest();
      qHttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
          var list = JSON.parse(this.responseText);
          var div = document.getElementById("queue-list");
          if (list.length === 0) {
            div.innerHTML = "Chưa có mạng nào.";
          } else {
            var html = "";
            for (var i = 0; i < list.length; i++) {
              html += "<div class='queue-item'>[" + (i+1) + "] <b>" + list[i].ssid + "</b></div>";
            }
            div.innerHTML = html;
          }
        }
      };
      qHttp.open("GET", "/getQueue", true);
      qHttp.send();
    }
    function saveWifi() {
      var select = document.getElementById("ssid");
      var s = select.value === "--custom--" ? document.getElementById("custom_ssid").value : select.value;
      var p = document.getElementById("password").value;
      var u = document.getElementById("uid").value;
      var f = document.getElementById("farmid").value;
      var sn = document.getElementById("sensorid").value;
      xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
          alert(this.responseText);
          loadQueue();
        }
      };
      xhttp.open("GET", "/saveWifi?ssid=" + encodeURIComponent(s) + "&pass=" + encodeURIComponent(p) + "&uid=" + encodeURIComponent(u) + "&farmid=" + encodeURIComponent(f) + "&sensorid=" + encodeURIComponent(sn), true);
      xhttp.send();
    }
    function reConnect() {
      xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
          alert("ESP32 đang tự động quét và kết nối...");
        }
      };
      xhttp.open("GET", "/autoConnect", true);
      xhttp.send();
    }
  </script>
</body>
</html>
)html";

void blinkLed(uint32_t t) {
  if (millis() - blinkTime > t) {
    digitalWrite(ledPin, !digitalRead(ledPin));
    blinkTime = millis();
  }
}

void ledControl() {
  if (digitalRead(btnPin) == LOW) {
    if (millis() - lastTimePress < PUSHTIME) {
      blinkLed(1000);
    } else {
      blinkLed(50);
    }
  } else {
    if (wifiMode == 0) {
      blinkLed(50); // AP Mode
    } else if (wifiMode == 1) {
      blinkLed(3000); // Online
    } else if (wifiMode == 2) {
      blinkLed(300); // Reconnecting / Scanning
    }
  }
}

void WiFiEvent(WiFiEvent_t event) {
  switch (event) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.println("\n[WiFi AutoProvision] DA KET NOI THANH CONG!");
      Serial.print("[WiFi] IP ESP32: ");
      Serial.println(WiFi.localIP());
      Serial.print("[WiFi] Dang ket noi toi SSID: ");
      Serial.println(WiFi.SSID());
      wifiMode = 1;
      retryCount = 0;
      needReconnect = false;
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      if (wifiMode != 0) {
        Serial.println("\n[WiFi] Mat ket noi. Chuan bi Auto-Provision lai...");
        wifiMode = 2;
        needReconnect = true;
      }
      break;
    default:
      break;
  }
}

class AutoProvisionManager {
private:
  WiFiCredential wifiQueue[MAX_WIFI_QUEUE];
  int queueCount = 0;
  int currentQueueIndex = 0;

public:
  AutoProvisionManager() {}

  /// Thêm một mạng mới vào Queue (tối đa 10 mạng).
  /// Nếu mạng đã tồn tại thì cập nhật mật khẩu, nếu đầy 10 mạng thì ghi đè mạng cũ nhất (FIFO).
  bool addNetwork(String ssidIn, String passIn) {
    ssidIn.trim();
    passIn.trim();
    if (ssidIn.length() == 0) return false;

    // 1. Nếu SSID đã có trong Queue, cập nhật lại mật khẩu
    for (int i = 0; i < queueCount; i++) {
      if (wifiQueue[i].ssid.equalsIgnoreCase(ssidIn)) {
        wifiQueue[i].password = passIn;
        Serial.printf("[AutoProvision] Cap nhat mat khau cho: %s\n", ssidIn.c_str());
        return true;
      }
    }

    // 2. Nếu Queue chưa đầy, thêm vào cuối
    if (queueCount < MAX_WIFI_QUEUE) {
      wifiQueue[queueCount].ssid = ssidIn;
      wifiQueue[queueCount].password = passIn;
      queueCount++;
      Serial.printf("[AutoProvision] Da them vao Queue [%d/%d]: %s\n", queueCount, MAX_WIFI_QUEUE, ssidIn.c_str());
      return true;
    }

    // 3. Nếu Queue đã đầy 10 mạng, đẩy mạng cũ nhất ra (FIFO) và chèn vào cuối
    for (int i = 0; i < MAX_WIFI_QUEUE - 1; i++) {
      wifiQueue[i] = wifiQueue[i + 1];
    }
    wifiQueue[MAX_WIFI_QUEUE - 1].ssid = ssidIn;
    wifiQueue[MAX_WIFI_QUEUE - 1].password = passIn;
    Serial.printf("[AutoProvision] Queue day (10) -> Day mang cu ra, them mang moi: %s\n", ssidIn.c_str());
    return true;
  }

  int getCount() const { return queueCount; }

  WiFiCredential getNetwork(int index) const {
    if (index >= 0 && index < queueCount) return wifiQueue[index];
    return {"", ""};
  }

  void clearQueue() {
    queueCount = 0;
    currentQueueIndex = 0;
    Serial.println("[AutoProvision] Da xoa toan bo Queue WiFi!");
  }

  /// Tự động quét các sóng WiFi xung quanh và đối chiếu với 10 mạng trong Queue.
  /// Mạng nào có trong Queue và sóng mạnh nhất sẽ được ưu tiên kết nối trước!
  bool autoScanAndConnect() {
    if (queueCount == 0) {
      Serial.println("[AutoProvision] Queue rong, khong co mang nao de ket noi!");
      return false;
    }

    Serial.println("\n[AutoProvision] Dang quet cac song WiFi xung quanh de tim mang phu hop...");
    WiFi.mode(WIFI_STA);
    WiFi.disconnect(true);
    delay(100);

    int n = WiFi.scanNetworks();
    Serial.printf("[AutoProvision] Tim thay %d song WiFi xung quanh.\n", n);

    int bestMatchQueueIdx = -1;
    int bestRSSI = -999;

    for (int i = 0; i < n; ++i) {
      String scannedSSID = WiFi.SSID(i);
      int scannedRSSI = WiFi.RSSI(i);

      for (int q = 0; q < queueCount; q++) {
        if (scannedSSID.equalsIgnoreCase(wifiQueue[q].ssid)) {
          Serial.printf("  -> Khop mang trong Queue: '%s' (RSSI: %d dBm)\n", scannedSSID.c_str(), scannedRSSI);
          if (scannedRSSI > bestRSSI) {
            bestRSSI = scannedRSSI;
            bestMatchQueueIdx = q;
          }
        }
      }
    }

    if (bestMatchQueueIdx != -1) {
      WiFiCredential target = wifiQueue[bestMatchQueueIdx];
      Serial.printf("[AutoProvision] -> Chon mang tot nhat: '%s'\n", target.ssid.c_str());
      connectTo(target.ssid, target.password);
      return true;
    }

    // Nếu scan không thấy (hoặc là điểm phát sóng di động ẩn như 4G OPPO), thử lần lượt từng mạng trong Queue
    Serial.println("[AutoProvision] Khong thay mang khop khi scan -> Thu ket noi tuan tu trong Queue...");
    return tryNextInQueue();
  }

  bool tryNextInQueue() {
    if (queueCount == 0) return false;
    WiFiCredential target = wifiQueue[currentQueueIndex];
    currentQueueIndex = (currentQueueIndex + 1) % queueCount;

    Serial.printf("[AutoProvision] Thu ket noi mang trong Queue: '%s'...\n", target.ssid.c_str());
    connectTo(target.ssid, target.password);
    return true;
  }

  void connectTo(String s, String p) {
    WiFi.mode(WIFI_STA);
    WiFi.setTxPower(WIFI_POWER_11dBm); // Chống sụt áp
    WiFi.begin(s.c_str(), p.c_str());
    wifiMode = 2; // Reconnecting
    lastReconnectAttempt = millis();
  }
} autoProvision;

void startAccessPoint() {
  Serial.println("\n[WiFi] Dang mo Access Point de cau hinh...");
  WiFi.disconnect(true);
  delay(100);
  WiFi.mode(WIFI_AP);
  WiFi.setTxPower(WIFI_POWER_11dBm);
  
  uint8_t macAddr[6];
  WiFi.softAPmacAddress(macAddr);
  String ssid_ap = "GreenPulse_Setup_" + String(macAddr[4], HEX) + String(macAddr[5], HEX);
  ssid_ap.toUpperCase();
  
  WiFi.softAP(ssid_ap.c_str());
  Serial.println("[WiFi] Ten AP: " + ssid_ap);
  Serial.println("[WiFi] IP trang cau hinh: " + WiFi.softAPIP().toString());
  wifiMode = 0;
}

void setupWebServer() {
  webServer.on("/", []() {
    webServer.send(200, "text/html", html);
  });

  webServer.on("/scanWifi", []() {
    int wifi_nets = WiFi.scanNetworks();
#if ARDUINOJSON_VERSION_MAJOR >= 7
    JsonDocument doc;
#else
    DynamicJsonDocument doc(512);
#endif
    for (int i = 0; i < wifi_nets; ++i) {
      doc.add(WiFi.SSID(i));
    }
    String wifiList = "";
    serializeJson(doc, wifiList);
    webServer.send(200, "application/json", wifiList);
  });

  webServer.on("/getQueue", []() {
#if ARDUINOJSON_VERSION_MAJOR >= 7
    JsonDocument doc;
#else
    DynamicJsonDocument doc(512);
#endif
    for (int i = 0; i < autoProvision.getCount(); i++) {
      JsonObject item = doc.add<JsonObject>();
      item["ssid"] = autoProvision.getNetwork(i).ssid;
    }
    String listStr = "";
    serializeJson(doc, listStr);
    webServer.send(200, "application/json", listStr);
  });

  auto handleSave = []() {
    String ssid_temp = "";
    String password_temp = "";
    String uid_temp = "";
    String farmid_temp = "";
    String sensorid_temp = "";

    // 1. Nhận JSON từ App Mobile
    if (webServer.hasArg("plain")) {
#if ARDUINOJSON_VERSION_MAJOR >= 7
      JsonDocument doc;
#else
      DynamicJsonDocument doc(512);
#endif
      DeserializationError err = deserializeJson(doc, webServer.arg("plain"));
      if (!err) {
        ssid_temp = (const char*)(doc["wifiSsid"] | doc["ssid"] | "");
        password_temp = (const char*)(doc["wifiPass"] | doc["pass"] | doc["password"] | "");
        uid_temp = (const char*)(doc["uid"] | "");
        farmid_temp = (const char*)(doc["farmId"] | doc["farmid"] | "");
        sensorid_temp = (const char*)(doc["sensorId"] | doc["sensorid"] | "");
      }
    }

    // 2. Nhận từ Web Browser thông thường
    if (ssid_temp.length() == 0 && webServer.hasArg("ssid")) {
      ssid_temp = webServer.arg("ssid");
      password_temp = webServer.hasArg("pass") ? webServer.arg("pass") : webServer.arg("password");
      uid_temp = webServer.arg("uid");
      farmid_temp = webServer.hasArg("farmid") ? webServer.arg("farmid") : webServer.arg("farmId");
      sensorid_temp = webServer.hasArg("sensorid") ? webServer.arg("sensorid") : webServer.arg("sensorId");
    }

    ssid_temp.trim();
    password_temp.trim();
    if (uid_temp.length() > 0) uid = uid_temp;
    if (farmid_temp.length() > 0) farmId = farmid_temp;
    if (sensorid_temp.length() > 0) sensorId = sensorid_temp;

    if (ssid_temp.length() > 0) {
      autoProvision.addNetwork(ssid_temp, password_temp);
      webServer.send(200, "text/plain", "Da them mang vao Queue thanh cong!");
    } else {
      webServer.send(400, "text/plain", "SSID khong duoc de trong!");
    }
  };

  webServer.on("/saveWifi", handleSave);
  webServer.on("/config", HTTP_POST, handleSave);

  webServer.on("/autoConnect", []() {
    webServer.send(200, "text/plain", "Dang bat dau Auto-Provision...");
    autoProvision.autoScanAndConnect();
  });

  webServer.begin();
}

void checkButton() {
  if (digitalRead(btnPin) == LOW) {
    if (millis() - lastTimePress > PUSHTIME) {
      Serial.println("[Button] Xoa toan bo Queue va khoi dong lai...");
      autoProvision.clearQueue();
      startAccessPoint();
      delay(1000);
    }
  } else {
    lastTimePress = millis();
  }
}

class Config {
public:
  void begin() {
    pinMode(ledPin, OUTPUT);
    pinMode(btnPin, INPUT_PULLUP);
    blinker.attach_ms(50, ledControl);

    // =========================================================================
    // KHỞI TẠO CÁC MẠNG SẴN TRONG QUEUE (Tối đa 10 mạng, không cần EEPROM)
    // Bạn có thể thêm sẵn điểm phát sóng 4G OPPO, WiFi nhà, WiFi nông trại ở đây:
    // =========================================================================
    autoProvision.addNetwork("OPPO", "12345678");               // 1. Điểm phát 4G điện thoại OPPO
    autoProvision.addNetwork("GreenPulse_Home", "123456789");   // 2. WiFi nhà
    autoProvision.addNetwork("GreenPulse_Farm", "greenpulse88");// 3. WiFi nông trại
    // Thêm các mạng khác nếu muốn (tối đa 10)...

    WiFi.onEvent(WiFiEvent);
    setupWebServer();

    // Bắt đầu tự động quét và kết nối mạng khả dụng
    if (!autoProvision.autoScanAndConnect()) {
      startAccessPoint();
    }
  }

  void addNetwork(String s, String p) {
    autoProvision.addNetwork(s, p);
  }

  void run() {
    checkButton();
    webServer.handleClient();

    if (needReconnect && wifiMode != 0) {
      unsigned long now = millis();
      if (now - lastReconnectAttempt > 8000) {
        lastReconnectAttempt = now;
        retryCount++;
        Serial.printf("[AutoProvision] Thu ket noi lai lan %d/%d...\n", retryCount, MAX_RETRY_PER_NET * autoProvision.getCount());

        if (retryCount >= MAX_RETRY_PER_NET * autoProvision.getCount()) {
          Serial.println("[WiFi] Thu tat ca cac mang trong Queue deu khong duoc. Chuyen ve AP!");
          needReconnect = false;
          startAccessPoint();
        } else {
          autoProvision.tryNextInQueue();
        }
      }
    }
  }

  bool isProvisioned() {
    return (uid.length() > 0 && farmId.length() > 0 && sensorId.length() > 0);
  }
} wifiConfig;

#endif