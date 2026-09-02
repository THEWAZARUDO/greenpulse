#ifndef WIFI_CONFIG_H
#define WIFI_CONFIG_H

#include <Preferences.h>
#include <ArduinoJson.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Ticker.h>

WebServer webServer(80);
Ticker blinker;
Preferences prefs;

#define MAX_SAVED_NETWORKS 5
#define PREF_NAMESPACE "gp_config"

struct WifiCredential {
  String ssid;
  String password;
};

WifiCredential savedNetworks[MAX_SAVED_NETWORKS];
int savedNetworkCount = 0;

String activeSsid = "";
String activeIp = "";
String uid = "";
String farmId = "";
String sensorId = "";

#define ledPin 2
#define btnPin 0
unsigned long lastTimePress = 0;
#define PUSHTIME 5000

int wifiMode = 0; // 0: AP Mode, 1: Connected STA, 2: Scanning/Connecting
volatile bool needReconnect = false;
unsigned long lastReconnectAttempt = 0;
int retryCount = 0;
const int MAX_RETRY = 3;
unsigned long blinkTime = 0;

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
      blinkLed(50);   // AP Mode: Nháy nhanh
    } else if (wifiMode == 1) {
      blinkLed(3000); // Connected: Nháy rất chậm (3s)
    } else if (wifiMode == 2) {
      blinkLed(300);  // Reconnecting/Scanning: Nháy vừa (300ms)
    }
  }
}

// ==========================================
// QUẢN LÝ LƯU TRỮ NHIỀU MẠNG (PREFERENCES / NVS)
// ==========================================
void loadConfigFromNVS() {
  prefs.begin(PREF_NAMESPACE, false);

  uid = prefs.getString("uid", "");
  farmId = prefs.getString("farmId", "");
  sensorId = prefs.getString("sensorId", "");

  uid.trim();
  farmId.trim();
  sensorId.trim();

  String networksJson = prefs.getString("networks", "[]");
  savedNetworkCount = 0;

#if ARDUINOJSON_VERSION_MAJOR >= 7
  JsonDocument doc;
#else
  DynamicJsonDocument doc(1024);
#endif
  DeserializationError error = deserializeJson(doc, networksJson);
  if (!error && doc.is<JsonArray>()) {
    JsonArray arr = doc.as<JsonArray>();
    for (JsonObject obj : arr) {
      if (savedNetworkCount < MAX_SAVED_NETWORKS) {
        String s = obj["ssid"] | "";
        String p = obj["pass"] | "";
        s.trim();
        p.trim();
        if (s.length() > 0) {
          savedNetworks[savedNetworkCount].ssid = s;
          savedNetworks[savedNetworkCount].password = p;
          savedNetworkCount++;
        }
      }
    }
  }

  prefs.end();

  Serial.println("\n--- THONG TIN DA LUU (MULTI-NETWORK) ---");
  Serial.println("UID: " + (uid.length() > 0 ? uid : "[Chua co]"));
  Serial.println("FarmID: " + (farmId.length() > 0 ? farmId : "[Chua co]"));
  Serial.println("SensorID: " + (sensorId.length() > 0 ? sensorId : "[Chua co]"));
  Serial.printf("So mang da luu: %d/%d\n", savedNetworkCount, MAX_SAVED_NETWORKS);
  for (int i = 0; i < savedNetworkCount; i++) {
    Serial.printf("  [%d] SSID: '%s'\n", i + 1, savedNetworks[i].ssid.c_str());
  }
  Serial.println("----------------------------------------");
}

void saveConfigToNVS() {
  prefs.begin(PREF_NAMESPACE, false);
  prefs.putString("uid", uid);
  prefs.putString("farmId", farmId);
  prefs.putString("sensorId", sensorId);

#if ARDUINOJSON_VERSION_MAJOR >= 7
  JsonDocument doc;
#else
  DynamicJsonDocument doc(1024);
#endif
  JsonArray arr = doc.to<JsonArray>();
  for (int i = 0; i < savedNetworkCount; i++) {
    JsonObject obj = arr.add<JsonObject>();
    obj["ssid"] = savedNetworks[i].ssid;
    obj["pass"] = savedNetworks[i].password;
  }

  String jsonStr = "";
  serializeJson(doc, jsonStr);
  prefs.putString("networks", jsonStr);
  prefs.end();

  Serial.printf("[NVS] Da luu %d mang WiFi va thong tin UID/FarmID thanh cong.\n", savedNetworkCount);
}

bool addOrUpdateNetwork(String newSsid, String newPass) {
  newSsid.trim();
  newPass.trim();
  if (newSsid.length() == 0) return false;

  // 1. Nếu SSID đã tồn tại -> Cập nhật mật khẩu
  for (int i = 0; i < savedNetworkCount; i++) {
    if (savedNetworks[i].ssid.equalsIgnoreCase(newSsid)) {
      savedNetworks[i].password = newPass;
      saveConfigToNVS();
      return true;
    }
  }

  // 2. Nếu chưa có và danh sách chưa đầy -> Thêm vào cuối
  if (savedNetworkCount < MAX_SAVED_NETWORKS) {
    savedNetworks[savedNetworkCount].ssid = newSsid;
    savedNetworks[savedNetworkCount].password = newPass;
    savedNetworkCount++;
    saveConfigToNVS();
    return true;
  }

  // 3. Nếu danh sách đã đầy (5/5) -> Ghi đè vào mạng cũ nhất (index 0)
  for (int i = 0; i < MAX_SAVED_NETWORKS - 1; i++) {
    savedNetworks[i] = savedNetworks[i + 1];
  }
  savedNetworks[MAX_SAVED_NETWORKS - 1].ssid = newSsid;
  savedNetworks[MAX_SAVED_NETWORKS - 1].password = newPass;
  saveConfigToNVS();
  return true;
}

bool removeNetwork(String targetSsid) {
  targetSsid.trim();
  int foundIdx = -1;
  for (int i = 0; i < savedNetworkCount; i++) {
    if (savedNetworks[i].ssid.equalsIgnoreCase(targetSsid)) {
      foundIdx = i;
      break;
    }
  }

  if (foundIdx != -1) {
    for (int i = foundIdx; i < savedNetworkCount - 1; i++) {
      savedNetworks[i] = savedNetworks[i + 1];
    }
    savedNetworkCount--;
    saveConfigToNVS();
    return true;
  }
  return false;
}

void clearAllConfig() {
  prefs.begin(PREF_NAMESPACE, false);
  prefs.clear();
  prefs.end();
  savedNetworkCount = 0;
  uid = farmId = sensorId = activeSsid = activeIp = "";
  Serial.println("[NVS] Da xoa sach toan bo cau hinh va danh sach mang!");
}

// ==========================================
// WIFI EVENTS & TỰ ĐỘNG QUÉT KẾT NỐI (AUTOPROVISION)
// ==========================================
void WiFiEvent(WiFiEvent_t event) {
  switch (event) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      activeIp = WiFi.localIP().toString();
      activeSsid = WiFi.SSID();
      Serial.println("\n[WiFi] Da ket noi thanh cong!");
      Serial.printf("[WiFi] Mang dang ket noi: '%s' | IP: %s\n", activeSsid.c_str(), activeIp.c_str());
      wifiMode = 1;
      retryCount = 0;
      needReconnect = false;
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      if (wifiMode != 0) {
        Serial.println("\n[WiFi] Mat ket noi STA.");
        wifiMode = 2;
        needReconnect = true;
      }
      break;
    default:
      break;
  }
}

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

/// Thuật toán AutoProvision: Quét các mạng xung quanh và tự động kết nối vào mạng đã lưu có sóng mạnh nhất
bool autoScanAndConnect() {
  if (savedNetworkCount == 0) {
    Serial.println("[AutoProvision] Chua co mang nao duoc luu -> Mo AP.");
    startAccessPoint();
    return false;
  }

  Serial.println("\n[AutoProvision] Dang quet cac mang Wi-Fi 2.4GHz xung quanh...");
  WiFi.mode(WIFI_STA);
  WiFi.setTxPower(WIFI_POWER_11dBm);
  WiFi.disconnect(true);
  delay(100);

  int n = WiFi.scanNetworks();
  Serial.printf("[AutoProvision] Tim thay %d mang Wi-Fi xung quanh.\n", n);

  int bestSavedIdx = -1;
  int bestRssi = -999;

  // So khớp danh sách quét được với các mạng đã lưu
  for (int i = 0; i < n; ++i) {
    String scannedSsid = WiFi.SSID(i);
    int scannedRssi = WiFi.RSSI(i);

    for (int j = 0; j < savedNetworkCount; ++j) {
      if (savedNetworks[j].ssid == scannedSsid) {
        Serial.printf("  -> Khop mang da luu: '%s' (RSSI: %d dBm)\n", scannedSsid.c_str(), scannedRssi);
        if (scannedRssi > bestRssi) {
          bestRssi = scannedRssi;
          bestSavedIdx = j;
        }
      }
    }
  }

  if (bestSavedIdx != -1) {
    String targetSsid = savedNetworks[bestSavedIdx].ssid;
    String targetPass = savedNetworks[bestSavedIdx].password;
    Serial.printf("[AutoProvision] Ket noi tu dong vao mang tot nhat: '%s' (RSSI: %d dBm)...\n",
                  targetSsid.c_str(), bestRssi);

    WiFi.begin(targetSsid.c_str(), targetPass.c_str());
    wifiMode = 2;
    lastReconnectAttempt = millis();
    return true;
  }

  // Nếu không thấy trong danh sách quét (mạng ẩn hoặc quét sót), thử kết nối lần lượt các mạng đã lưu
  Serial.println("[AutoProvision] Khong tim thay mang nao trong pham vi quet. Thu ket noi mang da luu dau tien...");
  WiFi.begin(savedNetworks[0].ssid.c_str(), savedNetworks[0].password.c_str());
  wifiMode = 2;
  lastReconnectAttempt = millis();
  return true;
}

// ==========================================
// GIAO DIỆN WEB CẤU HÌNH & REST APIS
// ==========================================
String generateHtml() {
  String html = "<!DOCTYPE html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1'>";
  html += "<title>GREENPULSE AUTOPROVISION</title><style>";
  html += "body { font-family: Arial, sans-serif; display: flex; justify-content: center; background-color: #f4f7f6; margin: 0; padding: 15px; }";
  html += ".box { background: white; padding: 20px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); width: 100%; max-width: 360px; }";
  html += "h3 { text-align: center; color: #2E7D32; margin-top: 0; }";
  html += "label { font-weight: bold; font-size: 13px; color: #333; margin-top: 8px; display: block; }";
  html += "input, select { width: 100%; height: 36px; margin: 4px 0 10px 0; border: 1px solid #ccc; border-radius: 6px; box-sizing: border-box; padding: 0 8px; font-size: 14px; }";
  html += "button { width: 48%; height: 38px; border: none; border-radius: 6px; font-weight: bold; cursor: pointer; color: white; margin-top: 8px; }";
  html += ".btn-save { background-color: #2E7D32; float: left; }";
  html += ".btn-reset { background-color: #d32f2f; float: right; }";
  html += ".net-tag { display: inline-block; background: #e8f5e9; color: #2e7d32; padding: 4px 8px; border-radius: 4px; font-size: 12px; margin: 2px 2px 2px 0; border: 1px solid #c8e6c9; }";
  html += "#info { font-size: 12px; text-align: center; color: #666; margin-bottom: 12px; }";
  html += "</style></head><body><div class='box'>";
  html += "<h3>🌱 GREENPULSE SETUP</h3>";
  html += "<p id='info'>Dang quet WiFi xung quanh...</p>";

  // Danh sách các mạng đã lưu
  html += "<label>Mang da luu (" + String(savedNetworkCount) + "/" + String(MAX_SAVED_NETWORKS) + "):</label><div>";
  if (savedNetworkCount == 0) {
    html += "<span style='font-size:12px; color:#888;'>Chua co mang nao</span>";
  } else {
    for (int i = 0; i < savedNetworkCount; i++) {
      html += "<span class='net-tag'>📶 " + savedNetworks[i].ssid + "</span>";
    }
  }
  html += "</div><hr style='border:0; border-top:1px solid #eee; margin:12px 0;'>";

  html += "<label>Chon WiFi:</label><select id='ssid'><option value=''>Dang quet...</option></select>";
  html += "<label>Hoac tu nhap SSID:</label><input id='customSsid' type='text' placeholder='Ten WiFi (neu an)'>";
  html += "<label>Mat khau WiFi:</label><input id='password' type='password' placeholder='Mat khau WiFi'>";
  html += "<hr style='border:0; border-top:1px solid #eee; margin:12px 0;'>";
  html += "<label>Firebase UID:</label><input id='uid' type='text' value='" + uid + "' placeholder='UID chu tai khoan'>";
  html += "<label>Farm ID:</label><input id='farmid' type='text' value='" + farmId + "' placeholder='VD: farm_01'>";
  html += "<label>Sensor ID:</label><input id='sensorid' type='text' value='" + sensorId + "' placeholder='VD: sensor_01'>";
  html += "<div><button class='btn-save' onclick='saveWifi()'>LƯU MẠNG</button>";
  html += "<button class='btn-reset' onclick='reStart()'>KHOI DONG</button></div></div>";

  html += "<script>";
  html += "window.onload = function() { scanWifi(); };";
  html += "var xhttp = new XMLHttpRequest();";
  html += "function scanWifi() {";
  html += "  xhttp.onreadystatechange = function() {";
  html += "    if (this.readyState == 4 && this.status == 200) {";
  html += "      document.getElementById('info').innerHTML = 'Da tim thay cac mang xung quanh!';";
  html += "      var list = JSON.parse(this.responseText);";
  html += "      var select = document.getElementById('ssid'); select.innerHTML = '';";
  html += "      select.options[select.options.length] = new Option('-- Chon mang quet duoc --', '');";
  html += "      for (var i = 0; i < list.length; ++i) { select.options[select.options.length] = new Option(list[i], list[i]); }";
  html += "    }";
  html += "  };";
  html += "  xhttp.open('GET', '/scanWifi', true); xhttp.send();";
  html += "}";
  html += "function saveWifi() {";
  html += "  var sel = document.getElementById('ssid').value;";
  html += "  var cus = document.getElementById('customSsid').value.trim();";
  html += "  var s = cus.length > 0 ? cus : sel;";
  html += "  var p = document.getElementById('password').value;";
  html += "  var u = document.getElementById('uid').value;";
  html += "  var f = document.getElementById('farmid').value;";
  html += "  var sn = document.getElementById('sensorid').value;";
  html += "  if (!s && !u) { alert('Vui long nhap it nhat ten WiFi hoac UID!'); return; }";
  html += "  xhttp.onreadystatechange = function() { if (this.readyState == 4 && this.status == 200) { alert(this.responseText); } };";
  html += "  xhttp.open('GET', '/saveWifi?ssid=' + encodeURIComponent(s) + '&pass=' + encodeURIComponent(p) + '&uid=' + encodeURIComponent(u) + '&farmid=' + encodeURIComponent(f) + '&sensorid=' + encodeURIComponent(sn), true);";
  html += "  xhttp.send();";
  html += "}";
  html += "function reStart() {";
  html += "  xhttp.onreadystatechange = function() { if (this.readyState == 4 && this.status == 200) { alert('ESP32 dang khoi dong lai de ket noi mang...'); } };";
  html += "  xhttp.open('GET', '/reStart', true); xhttp.send();";
  html += "}";
  html += "</script></body></html>";
  return html;
}

void setupWebServer() {
  webServer.on("/", []() {
    webServer.send(200, "text/html", generateHtml());
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

  // API xem danh sách các mạng đã lưu trong bộ nhớ
  webServer.on("/networks", []() {
#if ARDUINOJSON_VERSION_MAJOR >= 7
    JsonDocument doc;
#else
    DynamicJsonDocument doc(1024);
#endif
    doc["activeSsid"] = activeSsid;
    doc["activeIp"] = activeIp;
    doc["uid"] = uid;
    doc["farmId"] = farmId;
    doc["sensorId"] = sensorId;
    doc["wifiMode"] = (wifiMode == 1 ? "CONNECTED" : (wifiMode == 0 ? "AP_MODE" : "CONNECTING"));

    JsonArray arr = doc["savedNetworks"].to<JsonArray>();
    for (int i = 0; i < savedNetworkCount; i++) {
      JsonObject obj = arr.add<JsonObject>();
      obj["ssid"] = savedNetworks[i].ssid;
    }

    String res = "";
    serializeJson(doc, res);
    webServer.send(200, "application/json", res);
  });

  auto handleSave = []() {
    String ssid_temp = "";
    String password_temp = "";
    String uid_temp = "";
    String farmid_temp = "";
    String sensorid_temp = "";

    // 1. Nhận JSON từ App Flutter
    if (webServer.hasArg("plain")) {
#if ARDUINOJSON_VERSION_MAJOR >= 7
      JsonDocument doc;
#else
      DynamicJsonDocument doc(512);
#endif
      DeserializationError err = deserializeJson(doc, webServer.arg("plain"));
      if (!err) {
        const char* val_ssid = doc["wifiSsid"] | doc["ssid"] | "";
        const char* val_pass = doc["wifiPass"] | doc["pass"] | doc["password"] | "";
        const char* val_uid = doc["uid"] | "";
        const char* val_farm = doc["farmId"] | doc["farmid"] | "";
        const char* val_sensor = doc["sensorId"] | doc["sensorid"] | "";

        ssid_temp = String(val_ssid);
        password_temp = String(val_pass);
        uid_temp = String(val_uid);
        farmid_temp = String(val_farm);
        sensorid_temp = String(val_sensor);
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
    uid_temp.trim();
    farmid_temp.trim();
    sensorid_temp.trim();

    if (uid_temp.length() > 0) uid = uid_temp;
    if (farmid_temp.length() > 0) farmId = farmid_temp;
    if (sensorid_temp.length() > 0) sensorId = sensorid_temp;

    if (ssid_temp.length() > 0) {
      addOrUpdateNetwork(ssid_temp, password_temp);
    } else {
      saveConfigToNVS();
    }

    Serial.printf("[WebServer] Da luu mang '%s', UID='%s', FarmID='%s', SensorID='%s'\n",
                  ssid_temp.c_str(), uid.c_str(), farmId.c_str(), sensorId.c_str());

    webServer.send(200, "text/plain", "Da luu thanh cong vao danh sach AutoProvision! ESP32 dang khoi dong lai de tu dong ket noi...");
    delay(1500);
    ESP.restart();
  };

  webServer.on("/saveWifi", handleSave);
  webServer.on("/config", HTTP_POST, handleSave);

  // Xóa 1 mạng cụ thể: /deleteWifi?ssid=TenMang
  webServer.on("/deleteWifi", []() {
    if (webServer.hasArg("ssid")) {
      String delSsid = webServer.arg("ssid");
      if (removeNetwork(delSsid)) {
        webServer.send(200, "text/plain", "Da xoa mang '" + delSsid + "' khoi danh sach AutoProvision.");
        return;
      }
    }
    webServer.send(400, "text/plain", "Khong tim thay mang de xoa.");
  });

  webServer.on("/reStart", []() {
    webServer.send(200, "text/plain", "ESP32 dang khoi dong lai...");
    delay(1000);
    ESP.restart();
  });

  webServer.begin();
}

void checkButton() {
  if (digitalRead(btnPin) == LOW) {
    if (millis() - lastTimePress > PUSHTIME) {
      Serial.println("[Button] Dang xoa sach toan bo cau hinh...");
      clearAllConfig();
      delay(1000);
      ESP.restart();
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

    loadConfigFromNVS();

    WiFi.onEvent(WiFiEvent);
    setupWebServer();

    // Khởi động AutoProvision tự động quét và kết nối
    autoScanAndConnect();
  }

  void run() {
    checkButton();
    webServer.handleClient();

    // Cơ chế tự động thử lại khi mất mạng (Auto-Reconnect fallback)
    if (needReconnect && wifiMode != 0) {
      unsigned long now = millis();
      if (now - lastReconnectAttempt > 10000) {
        lastReconnectAttempt = now;
        retryCount++;
        Serial.printf("[WiFi] Thu quet va ket noi lai lan %d/%d...\n", retryCount, MAX_RETRY);

        if (retryCount >= MAX_RETRY) {
          Serial.println("[WiFi] Ket noi that bai sau nhieu lan thu. Chuyen sang che do AP de cau hinh!");
          needReconnect = false;
          startAccessPoint();
        } else {
          autoScanAndConnect();
        }
      }
    }
  }

  bool isProvisioned() {
    return (uid.length() > 0 && farmId.length() > 0 && sensorId.length() > 0);
  }
} wifiConfig;

#endif