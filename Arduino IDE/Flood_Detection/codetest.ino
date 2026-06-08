#include <WiFi.h>
#include <HTTPClient.h>

// ------------------- WIFI -------------------
const char* ssid = "TT_A538";
const char* password = "ihfy8l43wd";

// ------------------- SERVER -------------------
String serverUrl = "https://attentive-shale-defiance.ngrok-free.dev/data";

// ------------------- HC-SR04 -------------------
#define TRIG_PIN 26
#define ECHO_PIN 18

float tankHeight = 50.0;

// ------------------- GSM -------------------
#define MODEM_RX 16
#define MODEM_TX 27
#define MODEM_PWRKEY 4
#define MODEM_POWER_ON 23
#define MODEM_RST 5

HardwareSerial SerialAT(1);

String phoneNumber = "+21652154335";

// ------------------- GLOBAL -------------------
bool smsSent = false;
float previousLevel = 0;

// ==================================================
// 🔹 STABLE DISTANCE (AVERAGING FILTER)
// ==================================================
float getDistance() {
  float sum = 0;
  int valid = 0;

  for (int i = 0; i < 5; i++) {

    digitalWrite(TRIG_PIN, LOW);
    delayMicroseconds(2);

    digitalWrite(TRIG_PIN, HIGH);
    delayMicroseconds(10);
    digitalWrite(TRIG_PIN, LOW);

    long duration = pulseIn(ECHO_PIN, HIGH, 30000);

    if (duration > 0) {
      float d = (duration * 0.034) / 2;
      sum += d;
      valid++;
    }

    delay(50);
  }

  if (valid == 0) return -1;

  return sum / valid;
}

// ==================================================
// 🔹 SAFE SMS SENDER (FIXED)
// ==================================================
void sendSMS(String message) {

  Serial.println("📩 Sending SMS...");

  SerialAT.println("AT+CMGF=1");
  delay(1000);

  SerialAT.print("AT+CMGS=\"");
  SerialAT.print(phoneNumber);
  SerialAT.println("\"");

  delay(2000);

  SerialAT.print(message);
  delay(1000);

  SerialAT.write(26); // CTRL + Z

  delay(8000); // 🔥 IMPORTANT: allow GSM to finish

  Serial.println("📩 SMS sent (check +CMGS in serial)");
}

// ==================================================
// 🔹 SETUP
// ==================================================
void setup() {

  Serial.begin(115200);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  Serial.println("=== SYSTEM START ===");

  // ---------------- WIFI ----------------
  WiFi.begin(ssid, password);
  Serial.print("Connecting WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\n✅ WiFi Connected");

  // ---------------- GSM POWER ----------------
  pinMode(MODEM_POWER_ON, OUTPUT);
  digitalWrite(MODEM_POWER_ON, HIGH);

  pinMode(MODEM_PWRKEY, OUTPUT);
  digitalWrite(MODEM_PWRKEY, HIGH);
  delay(1000);
  digitalWrite(MODEM_PWRKEY, LOW);

  delay(8000); // 🔥 IMPORTANT: let GSM stabilize fully

  pinMode(MODEM_RST, OUTPUT);
  digitalWrite(MODEM_RST, HIGH);

  SerialAT.begin(9600, SERIAL_8N1, MODEM_RX, MODEM_TX);

  delay(3000);

  SerialAT.println("AT");
  delay(1000);
  SerialAT.println("AT+CSQ");
  SerialAT.println("AT+CREG?");
}

// ==================================================
// 🔹 LOOP
// ==================================================
void loop() {

  float distance = getDistance();

  if (distance < 0) {
    Serial.println("❌ Sensor error");
    delay(2000);
    return;
  }

  // ---------------- LEVEL ----------------
  float level = (1 - (distance / tankHeight)) * 100;

  if (level < 0) level = 0;
  if (level > 100) level = 100;

  // ---------------- RISK ----------------
  String risk;

  if (level > 70) risk = "HIGH";
  else if (level > 40) risk = "MEDIUM";
  else risk = "LOW";

  // ---------------- PRINT ----------------
  Serial.print("Distance: ");
  Serial.print(distance);
  Serial.print(" cm | Level: ");
  Serial.print(level);
  Serial.print("% | Risk: ");
  Serial.println(risk);

  // ---------------- HTTP ----------------
  if (WiFi.status() == WL_CONNECTED) {

    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");

    String json = "{\"level\": " + String(level) + ", \"risk\": \"" + risk + "\"}";

    int response = http.POST(json);

    if (response > 0) {
      Serial.print("HTTP OK: ");
      Serial.println(response);
    } else {
      Serial.print("HTTP FAIL: ");
      Serial.println(response);
    }

    http.end();
  }

  // ---------------- SMS (FIXED LOGIC) ----------------
  static unsigned long lastSMS = 0;

  if (risk == "HIGH" && millis() - lastSMS > 30000) {

    sendSMS("🚨 Flood Alert! Water level HIGH!");

    lastSMS = millis();
    smsSent = true;
  }

  if (risk != "HIGH") {
    smsSent = false;
  }

  previousLevel = level;

  delay(2000);
}