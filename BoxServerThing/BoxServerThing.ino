#include "arduino_secrets.h"
/**
 * @file BoxServerThing_feb20a.ino // (Ή το πραγματικό όνομα του .ino αρχείου σας)
 * @author [Nick Dimitrakarakos / 83899]
 * @brief Κύριο αρχείο σκίτσου Arduino για το IoT Cloud Boxing Game Project.
 *
 * Αυτό το σκίτσο διαχειρίζεται:
 * 1. Σύνδεση στο Arduino IoT Cloud.
 * 2. Αρχικοποίηση και διαχείριση των Cloud Variables (μέσω του thingProperties.h).
 * 3. Επικοινωνία μέσω Bluetooth Low Energy (BLE) χρησιμοποιώντας την κλάση BluetoothHandler.
 * 4. Λήψη μηνυμάτων JSON μέσω BLE και επεξεργασία τους χρησιμοποιώντας την ενσωματωμένη κλάση JsonHandler.
 * 5. Ενημέρωση των Cloud Variables με βάση τα επεξεργασμένα δεδομένα JSON.
 * 6. Συγχρονισμό της τοπικής ώρας με το Arduino IoT Cloud.
 * 7. Εμφάνιση πληροφοριών κατάστασης και debugging μέσω της σειριακής κονσόλας.
 *
 * @version 1.0 
 * @date 2025-05-14
 *
 * @copyright Copyright (c) 2025
 */

// Βασικές βιβλιοθήκες Arduino και του project
#include <Arduino.h>
#include "thingProperties.h"  // Αυτόματα παραγόμενο αρχείο από το Arduino IoT Cloud.
#include "BluetoothHandler.h" // Προσαρμοσμένη βιβλιοθήκη για BLE.
#include <TimeLib.h>
#include <ArduinoJson.h>

class JsonHandler {
public:
  static void parseIncoming(const String &incoming) {
    StaticJsonDocument<256> doc;
    DeserializationError error = deserializeJson(doc, incoming);
    if (error) {
      Serial.print(F("JsonHandler - JSON parse failed: "));
      Serial.println(error.f_str());
      return;
    }

    if (doc.containsKey("RoundStatusCommand")) {
      int cmd = doc["RoundStatusCommand"]["Command"] | 0;
      if (cmd == 1) {
        Serial.println(F("JsonHandler - Received RoundStatusCommand (cmd=1): Resetting all game variables."));
        deviceThatGotHit          = "";
        boxerThatScoresThePoint   = "";
        punchScore                = 0;
        timeStampOfThePunch       = "";
        sensorValue               = 0;
        blueBoxer_punchCount      = 0;
        blueBoxer_timestamp       = "";
        blueBoxer_sensorValue     = 0;
        redBoxer_punchCount       = 0;
        redBoxer_timestamp        = "";
        redBoxer_sensorValue      = 0;
      } else {
        Serial.print(F("JsonHandler - Received RoundStatusCommand with unknown command value: "));
        Serial.println(cmd);
      }
    }
    else {
      Serial.println(F("JsonHandler - Received punch data JSON. Parsing..."));

      const char* devStr   = doc["deviceStr"];
      const char* oppDev   = doc["oppositeDevice"];
      const char* punchStr = doc["punchCount"];
      const char* timeStr  = doc["timestamp"] | "";
      const char* sensor   = doc["sensorValue"];

      // Μετατροπή 3ου ':' σε '.' ώστε να έχουμε mm:ss.ff
      // String tsRaw = String(timeStr);
      // int idx = tsRaw.lastIndexOf(':');
      // if (idx != -1) {
      //   tsRaw.setCharAt(idx, '.');
      // }
      // timeStampOfThePunch = tsRaw;
      // Serial.print(F("JsonHandler - Parsed timestamp → "));
      // Serial.println(timeStampOfThePunch);

      deviceThatGotHit        = devStr   ? String(devStr)   : "";
      boxerThatScoresThePoint = oppDev   ? String(oppDev)   : "";
      punchScore              = punchStr ? atoi(punchStr)   : 0;
      sensorValue             = sensor   ? atoi(sensor)     : 0;

      String deviceString = devStr ? String(devStr) : "";
      if (deviceString == "RedBoxer") {
        blueBoxer_punchCount  = punchScore;
        blueBoxer_timestamp   = timeStr; //tsRaw;
        blueBoxer_sensorValue = sensorValue;
        Serial.println(F("JsonHandler - Data attributed to BlueBoxer (hit on RedBoxer)."));
      }
      else if (deviceString == "BlueBoxer") {
        redBoxer_punchCount   = punchScore;
        redBoxer_timestamp    = timeStr; // tsRaw;
        redBoxer_sensorValue  = sensorValue;
        Serial.println(F("JsonHandler - Data attributed to RedBoxer (hit on BlueBoxer)."));
      }
      else if (devStr != nullptr) {
        Serial.print(F("JsonHandler - Unknown deviceStr for boxer-specific logic: "));
        Serial.println(deviceString);
      } else {
        Serial.println(F("JsonHandler - deviceStr is null, cannot determine specific boxer logic."));
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
  Serial.println(F("\n[SETUP] Booting up device..."));
  ArduinoCloud.begin(ArduinoIoTPreferredConnection);
  initProperties();
  Serial.println(F("[SETUP] Initialized Thing Properties."));

  Serial.println(F("[SETUP] Attempting to connect to Arduino IoT Cloud..."));
  unsigned long cloudConnectTimeout = millis() + 30000;
  while (!ArduinoCloud.connected() && millis() < cloudConnectTimeout) {
    ArduinoCloud.update();
    delay(500);
    Serial.print(F("."));
  }
  Serial.println();
  if (!ArduinoCloud.connected()) {
    Serial.println(F("[SETUP] WARNING: Failed to connect to IoT Cloud within timeout."));
  } else {
    Serial.println(F("[SETUP] Successfully connected to Arduino IoT Cloud!"));
  }

  Serial.println(F("[SETUP] Waiting for initial IoT Cloud Time Sync (5s delay)..."));
  delay(5000);
  bleHandler.begin("BoxerServer");
  Serial.println(F("[SETUP] BLE server started. Advertising as 'BoxerServer'."));

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(F("[SETUP] Connected to Wi-Fi."));
    Serial.print(F("[SETUP] Local IP Address: "));
    Serial.println(WiFi.localIP());
  } else {
    Serial.println(F("[SETUP] WARNING: Wi-Fi not connected. IoT Cloud functionality might be affected."));
  }
  delay(2000);
  waitForValidTime();
  Serial.println(F("[SETUP] Device setup complete. Entering main loop."));
}

void loop() {
  ArduinoCloud.update();
  bleHandler.poll();
  String incomingMessage = bleHandler.readMessage();
  if (incomingMessage.length() > 0) {
    Serial.print(F("[LOOP] Received raw BLE message: "));
    Serial.println(incomingMessage);
    bleHandler.clearMessage();
    if (incomingMessage.startsWith("{")) {
      Serial.println(F("[LOOP] Message starts with '{', attempting JSON parse..."));
      JsonHandler::parseIncoming(incomingMessage);
      ArduinoCloud.update();  // στέλνουμε τις νέες τιμές άμεσα
    } else {
      Serial.println(F("[LOOP] Incoming message does not start with '{'. Not treated as JSON."));
    }
  }
  // delay(10);
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
  Serial.print(F("[TIME] Waiting for IoT Cloud time sync..."));
  unsigned long timeSyncTimeout = millis() + 30000;
  while (ArduinoCloud.getLocalTime() == 0 && millis() < timeSyncTimeout) {
    Serial.print(F("."));
    delay(1000);
    ArduinoCloud.update();
  }
  Serial.println();
  if (ArduinoCloud.getLocalTime() == 0) {
    Serial.println(F("[TIME] ERROR: IoT Cloud time sync failed after timeout!"));
  } else {
    Serial.print(F("[TIME] IoT Cloud time sync successful! "));
    printCurrentTime();
  }
}

void printCurrentTime() {
  unsigned long currentTime = ArduinoCloud.getLocalTime();
  if (currentTime == 0) {
    Serial.println(F("[TIME] Current time not available from IoT Cloud yet."));
  } else {
    Serial.print(F("[TIME] Current Time (Cloud Sync - Unix Timestamp): "));
    Serial.println(currentTime);
    String humanReadableTime = formatTimestamp(currentTime);
    Serial.print(F("[TIME] Human Readable Time: "));
    Serial.println(humanReadableTime);
  }
}
