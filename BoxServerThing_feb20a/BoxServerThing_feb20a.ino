#include "arduino_secrets.h"
#include <Arduino.h>
#include "thingProperties.h"  // The IoT Cloud environment merges this once
#include "BluetoothHandler.h"
#include <TimeLib.h>
#include <ArduinoJson.h>

class JsonHandler {
public:
  static void parseIncoming(const String &incoming) {
    StaticJsonDocument<256> doc;
    DeserializationError error = deserializeJson(doc, incoming);
    if (error) {
      Serial.print("JSON parse failed: ");
      Serial.println(error.f_str());
      return;
    }

    // Handle reset command
    if (doc.containsKey("RoundStatusCommand")) {
      int cmd = doc["RoundStatusCommand"]["Command"] | 0;
      if (cmd == 1) {
        deviceThatGotHit        = "";
        boxerThatScoresThePoint = "";
        punchScore              = 0;
        timeStampOfThePunch     = "";
        sensorValue             = 0;
        blueBoxer_punchCount    = 0;
        blueBoxer_timestamp     = "";
        blueBoxer_sensorValue   = 0;
        redBoxer_punchCount     = 0;
        redBoxer_timestamp      = "";
        redBoxer_sensorValue    = 0;
      }
    }
    else {
      // Parse normal fields
      const char* devStr   = doc["deviceStr"];
      const char* oppDev   = doc["oppositeDevice"];
      const char* punchStr = doc["punchCount"];
      const char* timeStr  = doc["timestamp"];
      const char* sensor   = doc["sensorValue"];

      deviceThatGotHit        = devStr   ? String(devStr)   : "";
      boxerThatScoresThePoint = oppDev   ? String(oppDev)   : "";
      punchScore              = punchStr ? atoi(punchStr)   : 0;
      timeStampOfThePunch     = timeStr  ? String(timeStr)  : "";
      sensorValue             = sensor   ? atoi(sensor)     : 0;

      String deviceString = devStr ? String(devStr) : "";
      if (deviceString == "RedBoxer") {
        blueBoxer_punchCount   = punchScore;
        blueBoxer_timestamp    = timeStr ? String(timeStr) : "";
        blueBoxer_sensorValue  = sensor  ? atoi(sensor)    : 0;
      }
      else if (deviceString == "BlueBoxer") {
        redBoxer_punchCount    = punchScore;
        redBoxer_timestamp     = timeStr ? String(timeStr) : "";
        redBoxer_sensorValue   = sensor  ? atoi(sensor)    : 0;
      }
    }
  }
};


BluetoothHandler bleHandler;

void waitForValidTime();
void printCurrentTime();
String formatTimestamp(unsigned long timestamp);

void setup() {
  Serial.begin(9600);
  delay(2000);

  // Start IoT Cloud
  ArduinoCloud.begin(ArduinoIoTPreferredConnection);
  initProperties(); // sets up all your cloud variables

  unsigned long timeout = millis() + 30000;
  while (!ArduinoCloud.connected() && millis() < timeout) {
    ArduinoCloud.update();
    delay(500);
  }
  if (!ArduinoCloud.connected()) {
    Serial.println("Warning: Failed to connect to IoT Cloud within timeout.");
  } else {
    Serial.println("Connected to IoT Cloud!");
  }

  Serial.println("Waiting for IoT Cloud Time Sync...");
  delay(5000);

  // Start BLE
  bleHandler.begin("BoxerServer");
  Serial.println("Setup complete: BLE");
  Serial.println("Connected to Wi-Fi, IoT Cloud started!");

  Serial.print("Local IP: ");
  Serial.println(WiFi.localIP());

  delay(2000);
  waitForValidTime();
}

void loop() {
  ArduinoCloud.update();
  bleHandler.poll();

  String incoming = bleHandler.readMessage();
  if (incoming.length() > 0) {
    bleHandler.clearMessage();

    if (incoming.startsWith("{")) {
      JsonHandler::parseIncoming(incoming);

    // (Optional) Confirm in Serial
    // Serial.println("Stored to IoT Cloud variables:");
    // Serial.println("deviceThatGotHit = " + (String)deviceThatGotHit);
    // Serial.println("boxerThatScoresThePoint = " + (String)boxerThatScoresThePoint);
    // Serial.println("punchScore = " + (String)punchScore);
    // Serial.println("timeStampOfThePunch = " + (String)timeStampOfThePunch);
    // Serial.println("sensorValue = " + (String)sensorValue);

      
    } else {
      Serial.println("Incoming message is not JSON.");
    }
  }
}

String formatTimestamp(unsigned long timestamp) {
  tmElements_t tm;
  breakTime(timestamp, tm);
  char buffer[20];
  sprintf(buffer, "%02d/%02d/%04d %02d:%02d:%02d",
          tm.Day, tm.Month, tm.Year + 1970,
          tm.Hour, tm.Minute, tm.Second);
  return String(buffer);
}

void waitForValidTime() {
  Serial.print("Waiting for IoT Cloud time sync...");
  unsigned long timeout = millis() + 30000;
  while (ArduinoCloud.getLocalTime() == 0 && millis() < timeout) {
    Serial.print(".");
    delay(1000);
    ArduinoCloud.update();
  }
  if (ArduinoCloud.getLocalTime() == 0) {
    Serial.println("\nERROR: IoT Cloud time sync failed!");
  } else {
    Serial.print("\nIoT Cloud time sync successful! ");
    printCurrentTime();
  }
}

void printCurrentTime() {
  unsigned long currentTime = ArduinoCloud.getLocalTime();
  if (currentTime == 0) {
    Serial.println("Time not available yet.");
  } else {
    Serial.print("Current Time (Cloud Sync): ");
    Serial.println(currentTime);
    String humanReadableTime = formatTimestamp(currentTime);
    Serial.print("Human Readable Time: ");
    Serial.println(humanReadableTime);
  }
}