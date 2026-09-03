#ifndef WIFI_CONFIG_H
#define WIFI_CONFIG_H

#include <EEPROM.h>
#include <ArduinoJson.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Ticker.h>

WebServer webServer(80);
Ticker blinker;

String ssid = "";
String password = "";
String uid = "";
String farmId = "";
String sensorId = "";

#define ledPin 2
#define btnPin 0
unsigned long lastTimePress = 0;
#define PUSHTIME 5000

int wifiMode = 0; // 0: AP Config, 1: Connected, 2: Reconnecting
volatile bool needReconnect = false;
unsigned long lastReconnectAttempt = 0;
int retryCount = 0;
const int MAX_RETRY = 5;
unsigned long blinkTime = 0;

#define EEPROM_SIZE      220
#define ADDR_SSID        0
#define ADDR_PASSWORD    32
#define ADDR_UID         96
#define ADDR_FARMID      136
#define ADDR_SENSORID    168

const char html[] PROGMEM = R"html(
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>GREENPULSE SETUP</title>
    <style>
      body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; background-color: #f4f7f6; margin: 0; padding: 20px; }
      .box { background: white; padding: 25px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); width: 100%; max-width: 320px; }
      h3 { text-align: center; color: #2E7D32; margin-top: 0; }
      label { font-weight: bold; font-size: 14px; color: #333; }
      input, select { width: 100%; height: 36px; margin: 6px 0 14px 0; border: 1px solid #ccc; border-radius: 5px; box-sizing: border-box; padding: 0 8px; font-size: 14px; }
      button { width: 48%; height: 40px; border: none; border-radius: 5px; font-weight: bold; cursor: pointer; color: white; margin-top: 5px; }
      .btn-save { background-color: #2E7D32; float: left; }
      .btn-reset { background-color: #d32f2f; float: right; }
      #info { font-size: 12px; text-align: center; color: #666; margin-bottom: 15px; }
    </style>
</head>
<body>
  <div class="box">
    <h3>🌱 GREENPULSE SETUP</h3>
    <p id="info">Dang quet WiFi...</p>
    <label>WiFi Name:</label>
    <select id="ssid"><option value="">Dang quet...</option></select>
    <label>Password:</label>
    <input id="password" type="password" placeholder="Mat khau WiFi">
    <hr style="border: 0; border-top: 1px solid #eee; margin: 15px 0;">
    <label>Firebase UID:</label>
    <input id="uid" type="text" placeholder="UID chu tai khoan">
    <label>Farm ID:</label>
    <input id="farmid" type="text" placeholder="VD: farm_01">
    <label>Sensor ID:</label>
    <input id="sensorid" type="text" placeholder="VD: sensor_01">
    <div>
      <button class="btn-save" onclick="saveWifi()">LƯU</button>
      <button class="btn-reset" onclick="reStart()">KHOI DONG</button>
    </div>
  </div>
  <script>
    window.onload = function() { scanWifi(); }
    var xhttp = new XMLHttpRequest();
    function scanWifi() {
      xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
          document.getElementById("info").innerHTML = "Da quet xong danh sach WiFi!";
          var obj = JSON.parse(this.responseText);
          var select = document.getElementById("ssid");
          select.innerHTML = "";
          for(var i=0; i<obj.length; ++i) {
            select.options[select.options.length] = new Option(obj[i], obj[i]);
          }
        }
      };
      xhttp.open("GET", "/scanWifi", true);
      xhttp.send();
    }
    function saveWifi() {
      var s = document.getElementById("ssid").value;
      var p = document.getElementById("password").value;
      var u = document.getElementById("uid").value;
      var f = document.getElementById("farmid").value;
      var sn = document.getElementById("sensorid").value;
      xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
          alert(this.responseText);
        }
      };
      xhttp.open("GET", "/saveWifi?ssid=" + encodeURIComponent(s) + "&pass=" + encodeURIComponent(p) + "&uid=" + encodeURIComponent(u) + "&farmid=" + encodeURIComponent(f) + "&sensorid=" + encodeURIComponent(sn), true);
      xhttp.send();
    }
    function reStart() {
      xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
          alert("ESP32 dang khoi dong lai...");
        }
      };
      xhttp.open("GET", "/reStart", true);
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
      blinkLed(50);
    } else if (wifiMode == 1) {
      blinkLed(3000);
    } else if (wifiMode == 2) {
      blinkLed(300);
    }
  }
}

void WiFiEvent(WiFiEvent_t event) {
  switch (event) {
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.println("\n[WiFi] Da ket noi thanh cong!");
      Serial.print("[WiFi] Dia chi IP ESP32: ");
      Serial.println(WiFi.localIP());
      wifiMode = 1;
      retryCount = 0;
      needReconnect = false;
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      if (wifiMode != 0) {
        Serial.println("\n[WiFi] Mat ket noi WiFi.");
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
  
  uint8_t macAddr[6];
  WiFi.softAPmacAddress(macAddr);
  String ssid_ap = "GreenPulse_Setup_" + String(macAddr[4], HEX) + String(macAddr[5], HEX);
  ssid_ap.toUpperCase();
  
  WiFi.softAP(ssid_ap.c_str());
  Serial.println("[WiFi] Ten AP: " + ssid_ap);
  Serial.println("[WiFi] IP trang cau hinh: " + WiFi.softAPIP().toString());
  wifiMode = 0;
}

void setupWifi() {
  WiFi.onEvent(WiFiEvent);

  if (ssid.length() > 0 && ssid != "null") {
    Serial.println("\n[WiFi] Dang ket noi toi: " + ssid);
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid.c_str(), password.c_str());
    wifiMode = 2;
    lastReconnectAttempt = millis();
  } else {
    startAccessPoint();
  }
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

  auto handleSave = []() {
    String ssid_temp = "";
    String password_temp = "";
    String uid_temp = "";
    String farmid_temp = "";
    String sensorid_temp = "";

    // 1. Nếu nhận JSON từ App Flutter
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

    // 2. Nếu nhận từ Web Browser thông thường
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

    EEPROM.writeString(ADDR_SSID, ssid_temp);
    EEPROM.writeString(ADDR_PASSWORD, password_temp);
    EEPROM.writeString(ADDR_UID, uid_temp);
    EEPROM.writeString(ADDR_FARMID, farmid_temp);
    EEPROM.writeString(ADDR_SENSORID, sensorid_temp);
    EEPROM.commit();

    Serial.printf("[WebServer] Da luu cau hinh: SSID='%s', UID='%s', FarmID='%s', SensorID='%s'\n",
                  ssid_temp.c_str(), uid_temp.c_str(), farmid_temp.c_str(), sensorid_temp.c_str());
    Serial.println("[WebServer] ESP32 se tu dong khoi dong lai trong 1.5 giay de ket noi WiFi...");

    webServer.send(200, "text/plain", "Da luu cau hinh! ESP32 dang khoi dong lai...");
    delay(1500);
    ESP.restart();
  };

  webServer.on("/saveWifi", handleSave);
  webServer.on("/config", HTTP_POST, handleSave); // App Flutter gọi đường dẫn này

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
      Serial.println("[Button] Dang xoa bo nho EEPROM...");
      for (int i = 0; i < EEPROM_SIZE; i++) {
        EEPROM.write(i, 0);
      }
      EEPROM.commit();
      Serial.println("[Button] Da xoa EEPROM! Dang khoi dong lai...");
      delay(1000);
      ESP.restart();
    }
  } else {
    lastTimePress = millis();
  }
}

String readEepromSafe(int addr, int maxLen) {
  char buf[64];
  memset(buf, 0, sizeof(buf));
  for (int i = 0; i < maxLen - 1; i++) {
    byte b = EEPROM.read(addr + i);
    if (b == 0 || b == 0xFF) {
      buf[i] = '\0';
      break;
    }
    buf[i] = (char)b;
  }
  return String(buf);
}

class Config {
public:
  void begin() {
    pinMode(ledPin, OUTPUT);
    pinMode(btnPin, INPUT_PULLUP);
    blinker.attach_ms(50, ledControl);
    EEPROM.begin(EEPROM_SIZE);

    ssid = readEepromSafe(ADDR_SSID, 32);
    password = readEepromSafe(ADDR_PASSWORD, 64);
    uid = readEepromSafe(ADDR_UID, 40);
    farmId = readEepromSafe(ADDR_FARMID, 32);
    sensorId = readEepromSafe(ADDR_SENSORID, 32);

    ssid.trim();
    password.trim();
    uid.trim();
    farmId.trim();
    sensorId.trim();

    Serial.println("\n--- THONG TIN DA LUU ---");
    Serial.println("SSID: " + (ssid.length() > 0 ? ssid : "[Chua co]"));
    Serial.println("UID: " + (uid.length() > 0 ? uid : "[Chua co]"));
    Serial.println("FarmID: " + (farmId.length() > 0 ? farmId : "[Chua co]"));
    Serial.println("SensorID: " + (sensorId.length() > 0 ? sensorId : "[Chua co]"));
    Serial.println("------------------------");

    setupWifi();
    setupWebServer();
  }

  void run() {
    checkButton();
    webServer.handleClient();

    if (needReconnect && wifiMode != 0) {
      unsigned long now = millis();
      if (now - lastReconnectAttempt > 8000) {
        lastReconnectAttempt = now;
        retryCount++;
        Serial.printf("[WiFi] Thu ket noi lai lan %d/%d toi '%s'...\n", retryCount, MAX_RETRY, ssid.c_str());

        if (retryCount >= MAX_RETRY) {
          Serial.println("[WiFi] Ket noi that bai qua nhieu lan. Chuyen ve che do AP!");
          needReconnect = false;
          startAccessPoint();
        } else {
          WiFi.disconnect(true);
          delay(100);
          WiFi.mode(WIFI_STA);
          WiFi.begin(ssid.c_str(), password.c_str());
        }
      }
    }
  }

  bool isProvisioned() {
    return (uid.length() > 0 && farmId.length() > 0 && sensorId.length() > 0);
  }
} wifiConfig;

#endif