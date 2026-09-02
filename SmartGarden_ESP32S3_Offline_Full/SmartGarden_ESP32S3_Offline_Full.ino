#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_ADS1X15.h>
#include <BH1750.h>
#include <DHT.h>
#include <Stepper.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "wifiConfig.h"

// URL Realtime Database (KHÔNG có dấu gạch chéo ở cuối)
const char* DATABASE_URL = "https://greenpulse-daklak-default-rtdb.firebaseio.com";

// ===== GPIO =====
#define I2C_SDA         8
#define I2C_SCL         9
#define DHT_PIN         10
#define RAIN_PIN        11
#define RELAY_QUAT      12
#define RELAY_SUOI      13
#define RELAY_BOM       14
#define RELAY_PHUN      21
#define ULN_IN1         15
#define ULN_IN2         16
#define ULN_IN3         17
#define ULN_IN4         18

// ===== OLED / I2C =====
#define OLED_ADDR       0x3C
Adafruit_SSD1306 display(128, 64, &Wire, -1);
Adafruit_ADS1115 ads;
BH1750 lightMeter;
DHT dht(DHT_PIN, DHT22);

bool oledOK = false, adsOK = false, bhOK = false, dhtOK = false;

#define PH_CH           0
#define SOIL_CH         1

// ===== STEPPER =====
#define STEPS_PER_REV   2048
#define CURTAIN_TURNS   3
#define CURTAIN_STEPS   (STEPS_PER_REV * CURTAIN_TURNS)
Stepper curtainStepper(STEPS_PER_REV, ULN_IN1, ULN_IN3, ULN_IN2, ULN_IN4);
bool curtainClosed = false;
unsigned long lastCurtainMove = 0;
const unsigned long CURTAIN_LOCK_MS = 60000UL;

// ===== THRESHOLDS =====
const float TEMP_FAN_ON = 30.0, TEMP_FAN_OFF = 28.0;
const float TEMP_HEATER_ON = 20.0, TEMP_HEATER_OFF = 22.0;
const float HUM_MIST_ON = 50.0, HUM_MIST_OFF = 55.0;
const float SOIL_PUMP_ON = 35.0, SOIL_PUMP_OFF = 70.0;
const float LUX_CLOSE = 30000.0, LUX_OPEN = 20000.0;

const int SOIL_ADC_DRY = 28000;
const int SOIL_ADC_WET = 12000;
const float PH_NEUTRAL_V = 2.50;
const float PH_SLOPE = 0.18;

// ===== STATE & DATA SHARING =====
bool fanState = false, heaterState = false, pumpState = false, mistState = false;
bool rainState = false;
float temperature = NAN, humidity = NAN, lux = NAN, soil = NAN, pH = NAN;
int16_t soilADC = 0, phADC = 0;

unsigned long lastSensor = 0, lastOLED = 0, lastSerial = 0, lastPage = 0;
const unsigned long SENSOR_MS = 2500UL;
const unsigned long OLED_MS = 500UL;
const unsigned long SERIAL_MS = 2500UL;
const unsigned long PAGE_MS = 3000UL;
uint8_t page = 0;

// Mutex để đồng bộ dữ liệu giữa Core 1 (Phần cứng) và Core 0 (Mạng)
portMUX_TYPE dataMux = portMUX_INITIALIZER_UNLOCKED;

void setRelay(uint8_t pin, bool on) { digitalWrite(pin, on ? HIGH : LOW); }

void releaseStepperPins() {
  // Ngắt điện 4 cuộn dây để ULN2003 không ngậm dòng gây sụt áp
  digitalWrite(ULN_IN1, LOW);
  digitalWrite(ULN_IN2, LOW);
  digitalWrite(ULN_IN3, LOW);
  digitalWrite(ULN_IN4, LOW);
}

bool readDHT() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  if (isnan(h) || isnan(t)) { dhtOK = false; return false; }
  humidity = h; temperature = t; dhtOK = true; return true;
}

int16_t adsAverage(uint8_t ch, uint8_t n) {
  long sum = 0;
  for (uint8_t i = 0; i < n; i++) sum += ads.readADC_SingleEnded(ch);
  return (int16_t)(sum / n);
}

void readSoil() {
  if (!adsOK) { soil = NAN; return; }
  soilADC = adsAverage(SOIL_CH, 10);
  soil = 100.0f * (SOIL_ADC_DRY - soilADC) / (float)(SOIL_ADC_DRY - SOIL_ADC_WET);
  soil = constrain(soil, 0.0f, 100.0f);
}

void readPH() {
  if (!adsOK) { pH = NAN; return; }
  phADC = adsAverage(PH_CH, 20);
  float v = ads.computeVolts(phADC);
  pH = 7.0f + (PH_NEUTRAL_V - v) / PH_SLOPE;
  pH = constrain(pH, 0.0f, 14.0f);
}

void readSensors() {
  readDHT();
  if (bhOK) {
    float x = lightMeter.readLightLevel();
    if (!isnan(x) && x >= 0) lux = x; else bhOK = false;
  }
  readSoil();
  readPH();
  rainState = (digitalRead(RAIN_PIN) == LOW);
}

void controlFan() {
  if (!dhtOK) { fanState = false; setRelay(RELAY_QUAT, false); return; }
  if (temperature >= TEMP_FAN_ON) fanState = true;
  else if (temperature <= TEMP_FAN_OFF) fanState = false;
  setRelay(RELAY_QUAT, fanState);
}

void controlHeater() {
  if (!dhtOK) { heaterState = false; setRelay(RELAY_SUOI, false); return; }
  if (temperature <= TEMP_HEATER_ON) heaterState = true;
  else if (temperature >= TEMP_HEATER_OFF) heaterState = false;
  setRelay(RELAY_SUOI, heaterState);
}

void controlMist() {
  if (!dhtOK) { mistState = false; setRelay(RELAY_PHUN, false); return; }
  if (humidity <= HUM_MIST_ON) mistState = true;
  else if (humidity >= HUM_MIST_OFF) mistState = false;
  setRelay(RELAY_PHUN, mistState);
}

void controlPump() {
  if (isnan(soil)) { pumpState = false; setRelay(RELAY_BOM, false); return; }
  if (soil <= SOIL_PUMP_ON && !rainState) pumpState = true;
  else if (soil >= SOIL_PUMP_OFF || rainState) pumpState = false;
  setRelay(RELAY_BOM, pumpState);
}

void controlCurtain() {
  if (isnan(lux)) return;
  if (millis() - lastCurtainMove < CURTAIN_LOCK_MS) return;
  if (lux >= LUX_CLOSE && !curtainClosed) {
    Serial.println("[REM] Nang manh -> DONG 3 VONG");
    curtainStepper.step(CURTAIN_STEPS);
    releaseStepperPins();
    curtainClosed = true; lastCurtainMove = millis();
  } else if (lux <= LUX_OPEN && curtainClosed) {
    Serial.println("[REM] Anh sang thap -> MO 3 VONG");
    curtainStepper.step(-CURTAIN_STEPS);
    releaseStepperPins();
    curtainClosed = false; lastCurtainMove = millis();
  }
}

void drawPage1() {
  display.clearDisplay(); display.setTextSize(1); display.setCursor(0, 0);
  display.println("SMART GARDEN"); display.drawLine(0, 9, 127, 9, SSD1306_WHITE);
  display.setCursor(0, 13);
  display.print("T: "); if (dhtOK) { display.print(temperature, 1); display.println(" C"); } else display.println("ERR");
  display.print("H: "); if (dhtOK) { display.print(humidity, 1); display.println(" %"); } else display.println("ERR");
  display.print("Lux: "); if (!isnan(lux)) display.println(lux, 0); else display.println("ERR");
  display.print("Soil: "); if (!isnan(soil)) { display.print(soil, 0); display.println(" %"); } else display.println("ERR");
  display.print("pH: "); if (!isnan(pH)) display.println(pH, 2); else display.println("ERR");
  display.print("Mua: "); display.println(rainState ? "CO" : "KHONG");
  display.display();
}

void drawPage2() {
  display.clearDisplay(); display.setTextSize(1); display.setCursor(0, 0);
  display.println("TRANG THAI"); display.drawLine(0, 9, 127, 9, SSD1306_WHITE);
  display.setCursor(0, 13);
  display.print("Quat : "); display.println(fanState ? "ON" : "OFF");
  display.print("Suoi : "); display.println(heaterState ? "ON" : "OFF");
  display.print("Bom  : "); display.println(pumpState ? "ON" : "OFF");
  display.print("Phun : "); display.println(mistState ? "ON" : "OFF");
  display.print("Rem  : "); display.println(curtainClosed ? "DONG" : "MO");
  display.print("Mua  : "); display.println(rainState ? "CO" : "KHONG");
  display.display();
}

void drawPage3() {
  display.clearDisplay(); display.setTextSize(1); display.setCursor(0, 0);
  display.println("TIN HIEU / ADC"); display.drawLine(0, 9, 127, 9, SSD1306_WHITE);
  display.setCursor(0, 13);
  display.print("DHT22: "); display.println(dhtOK ? "OK" : "ERR");
  display.print("BH1750: "); display.println(bhOK ? "OK" : "ERR");
  display.print("ADS1115: "); display.println(adsOK ? "OK" : "ERR");
  display.print("Soil ADC: "); display.println(soilADC);
  display.print("pH ADC: "); display.println(phADC);
  display.print("WiFi: "); display.println(WiFi.status() == WL_CONNECTED ? "ONLINE" : "OFFLINE/AP");
  display.display();
}

void updateOLED() {
  if (!oledOK) return;
  if (millis() - lastPage >= PAGE_MS) { lastPage = millis(); page = (page + 1) % 3; }
  if (millis() - lastOLED < OLED_MS) return;
  lastOLED = millis();
  if (page == 0) drawPage1(); else if (page == 1) drawPage2(); else drawPage3();
}

void printSerial() {
  if (millis() - lastSerial < SERIAL_MS) return;
  lastSerial = millis();
  Serial.printf("[Sensors] T=%.1fC | H=%.1f%% | Lux=%.0f | Soil=%.1f%% | pH=%.2f | Mua=%s | WiFi=%s\n",
                dhtOK ? temperature : -999.0, dhtOK ? humidity : -999.0,
                isnan(lux) ? -1.0 : lux, isnan(soil) ? -1.0 : soil,
                isnan(pH) ? -1.0 : pH, rainState ? "CO" : "KHONG",
                WiFi.status() == WL_CONNECTED ? "ONLINE" : "AP_CONFIG");
}

// ==========================================
// TASK CHUYÊN TRÁCH MẠNG & FIREBASE (CORE 0)
// ==========================================
void pushToFirebase() {
  if (WiFi.status() != WL_CONNECTED || !wifiConfig.isProvisioned()) return;

  // Lấy dữ liệu an toàn từ biến toàn cục
  float t, h, l, s, p;
  portENTER_CRITICAL(&dataMux);
  t = isnan(temperature) ? 28.0 : temperature;
  h = isnan(humidity) ? 75.0 : humidity;
  l = isnan(lux) ? 0.0 : lux;
  s = isnan(soil) ? 50.0 : soil;
  p = isnan(pH) ? 6.5 : pH;
  portEXIT_CRITICAL(&dataMux);

#if ARDUINOJSON_VERSION_MAJOR >= 7
  JsonDocument doc;
#else
  DynamicJsonDocument doc(256);
#endif
  doc["temperature"] = round(t * 10) / 10.0;
  doc["humidity"] = round(h * 10) / 10.0;
  doc["light"] = round(l);
  doc["soil"] = round(s * 10) / 10.0;
  doc["ph"] = round(p * 10) / 10.0;

  String payload;
  serializeJson(doc, payload);

  String url = String(DATABASE_URL) + "/sensors/" + uid + "/" + farmId + "/" + sensorId + ".json";

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  http.begin(client, url);
  http.addHeader("Content-Type", "application/json");

  int httpCode = http.PATCH(payload);
  if (httpCode == 200) {
    Serial.printf("[Firebase OK] -> %s\n", payload.c_str());
  } else if (httpCode > 0) {
    Serial.printf("[Firebase Code %d]: %s\n", httpCode, http.getString().c_str());
  }
  http.end();
}

void taskNetworkCore0(void *pvParameters) {
  TickType_t lastFirebaseTime = 0;
  const TickType_t firebaseInterval = pdMS_TO_TICKS(4000); // Đẩy Firebase đều đặn mỗi 4 giây

  for (;;) {
    // 1. Duy trì Web Server cấu hình AP & kiểm tra nút bấm reset
    wifiConfig.run();

    // 2. Gửi Firebase
    TickType_t now = xTaskGetTickCount();
    if (now - lastFirebaseTime >= firebaseInterval) {
      lastFirebaseTime = now;
      pushToFirebase();
    }

    vTaskDelay(pdMS_TO_TICKS(20));
  }
}

// ==========================================
// SETUP & LOOP (CHẠY TRÊN CORE 1)
// ==========================================
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== ESP32-S3 SMART GARDEN - DUAL CORE FULL SYSTEM ===");

  Wire.begin(I2C_SDA, I2C_SCL);
  Wire.setClock(100000);

  oledOK = display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR);
  if (oledOK) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("SMART GARDEN");
    display.println("ESP32-S3 ONLINE");
    display.println("CONNECTING...");
    display.display();
  } else Serial.println("[OLED] LOI");

  ads.setGain(GAIN_TWOTHIRDS);
  adsOK = ads.begin(0x48, &Wire);
  Serial.println(adsOK ? "[ADS1115] OK 0x48" : "[ADS1115] LOI");

  dht.begin();
  delay(1000);
  readDHT();

  bhOK = lightMeter.begin(BH1750::CONTINUOUS_HIGH_RES_MODE, 0x23, &Wire);
  Serial.println(bhOK ? "[BH1750] OK 0x23" : "[BH1750] LOI");

  pinMode(RAIN_PIN, INPUT_PULLUP);
  pinMode(RELAY_QUAT, OUTPUT);
  pinMode(RELAY_SUOI, OUTPUT);
  pinMode(RELAY_BOM, OUTPUT);
  pinMode(RELAY_PHUN, OUTPUT);
  setRelay(RELAY_QUAT, false);
  setRelay(RELAY_SUOI, false);
  setRelay(RELAY_BOM, false);
  setRelay(RELAY_PHUN, false);

  pinMode(ULN_IN1, OUTPUT);
  pinMode(ULN_IN2, OUTPUT);
  pinMode(ULN_IN3, OUTPUT);
  pinMode(ULN_IN4, OUTPUT);
  releaseStepperPins();

  curtainStepper.setSpeed(10);
  rainState = (digitalRead(RAIN_PIN) == LOW);

  // Khởi động module cấu hình WiFi & WebServer
  wifiConfig.begin();

  // Khởi tạo Task mạng trên Core 0 (Lõi riêng biệt)
  xTaskCreatePinnedToCore(
    taskNetworkCore0,
    "NetworkTask",
    8192,
    NULL,
    1,
    NULL,
    0 // PIN VÀO CORE 0
  );

  lastSensor = millis(); lastOLED = millis(); lastSerial = millis(); lastPage = millis();
  Serial.println("He thong khoi tao hoan tat. Core 1 chay Hardware, Core 0 chay Network.");
}

void loop() {
  // Loop mặc định của Arduino chạy độc quyền trên CORE 1
  if (millis() - lastSensor >= SENSOR_MS) {
    lastSensor = millis();
    readSensors();
    controlFan();
    controlHeater();
    controlMist();
    controlPump();
    controlCurtain();
  }
  updateOLED();
  printSerial();
}