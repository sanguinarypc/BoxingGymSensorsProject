#include "BoxingApp.h"
#include <ArduinoJson.h>
#include <BLEDevice.h>
#include "MacDevicesConfig.h"  // mac address store header

// == Added at top of BoxingApp.cpp ==
#include <WiFi.h>
#include <time.h>

// TODO: Replace with your network credentials or receive via BLE
const char* ssid = "mywifi5G";
const char* password = "KaragiozisTrelaras##14##";
// Timezone string for Europe/Athens (EET/EEST)
const char* tzInfo = "EET-2EEST,M3.5.0/3,M10.5.0/4";


// Helper to get an ISO‑8601 timestamp
String getFormattedTime() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) {
    Serial.println("Failed to obtain time");
    return String("");
  }
  char buf[32];
  strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);
  return String(buf);
}



String DEVICE_NAME = "";  // Global variable for device name

BoxingApp::BoxingApp()
  : startReading(false),
    roundTime(180000),
    breakTime(60000),
    fsrSensitivity(800),
    fsrThreshold(200),
    isPaused(false),
    elapsedTime(0),
    command(0),
    roundActive(false),
    lastSentPunch(""),
    duplicatePunchCount(0)  // Initialize duplicate counter
{
  bluetoothHandler = new BluetoothHandler();
  fsrHandler = new FSRPunchDetector(6, fsrSensitivity);
  timeHandler = new TimeHandler();
}

void BoxingApp::setup() {
  Serial.begin(115200);

  // 1️⃣ Connect to Wi‑Fi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print('.');
  }
  Serial.println("\nWiFi connected");

  // 2️⃣ Initialize SNTP for RTC
  configTzTime(tzInfo, "pool.ntp.org", "time.nist.gov");
  struct tm timeinfo;
  while (!getLocalTime(&timeinfo)) {
    Serial.println("Waiting for time sync...");
    delay(1000);
  }
  Serial.println("Time synchronized: " + getFormattedTime());


  // Initialize BLE and get BLE address
  BLEDevice::init("");
  String bleAddress = BLEDevice::getAddress().toString().c_str();
  Serial.print("BLE Address: ");
  Serial.println(bleAddress.c_str());

  // Default device name; adjust as needed by checking your MAC lists
  DEVICE_NAME = "UnknownDevice";
  for (int i = 0; i < NUM_BLUEBOXER_MACS; i++) {
    if (bleAddress.equalsIgnoreCase(BLUEBOXER_MACS[i])) {
      DEVICE_NAME = "BlueBoxer";
      break;
    }
  }
  if (DEVICE_NAME.equals("UnknownDevice")) {
    for (int i = 0; i < NUM_REDBOXER_MACS; i++) {
      if (bleAddress.equalsIgnoreCase(REDBOXER_MACS[i])) {
        DEVICE_NAME = "RedBoxer";
        break;
      }
    }
  }

  DEVICE_NAME.trim();                    // Remove extra spaces
  BLEDevice::deinit();                   // Reset BLE stack
  BLEDevice::init(DEVICE_NAME.c_str());  // Reinitialize with device name

  bluetoothHandler->begin(DEVICE_NAME.c_str());  // Start BLE with your device name
  fsrHandler->setup();
  Serial.print(DEVICE_NAME);
  Serial.print(" BLE Device is Ready  ");
  Serial.println("BoxingApp is ready... ");
  Serial.println("Waiting for client connections...");
}


void BoxingApp::loop() {
  handleCommands();

  // If the round is active and not paused, check for punches
  if (roundActive && !isPaused) {
    if (fsrHandler->checkPunch()) {
      sendPunchData();  // Process and send punch data
    }

    // End the round when time elapses
    if (timeHandler->getElapsedMilliseconds() >= roundTime) {
      Serial.println("Round complete.");
      roundActive = false;
      bluetoothHandler->sendMessage("{\"RoundState\":\"Completed\"}");
      timeHandler->reset();
    }
  }
}

void BoxingApp::handleCommands() {
  String incomingMessage = bluetoothHandler->readMessage();
  if (incomingMessage.length() > 0) {

    StaticJsonDocument<256> jsonDoc;
    DeserializationError error = deserializeJson(jsonDoc, incomingMessage);
    if (error) {
      Serial.print("JSON Parsing Failed: ");
      Serial.println(error.c_str());
      return;
    }

    // Handle sensor settings update
    if (jsonDoc.containsKey("SensorSettings")) {
      JsonObject settings = jsonDoc["SensorSettings"];
      fsrSensitivity = settings["FsrSensitivity"];
      fsrThreshold = settings["FsrThreshold"];
      roundTime = settings["RoundTime"];
      breakTime = settings["BreakTime"];
      fsrHandler->setSensitivity(fsrSensitivity);
      fsrHandler->setThreshold(fsrThreshold);
      // Serial.println("Sensor settings updated.");
      // Serial.println(fsrHandler->getSensitivity());
      // Serial.println(fsrHandler->getThreshold());
      bluetoothHandler->sendMessage("{\"RoundState\":\"Settings Updated\"}");
      bluetoothHandler->clearMessage();
    }

    // Handle round commands
    if (jsonDoc.containsKey("RoundStatusCommand")) {
      int commandValue = jsonDoc["RoundStatusCommand"]["Command"];
      unsigned long elapsedSeconds = timeHandler->getElapsedSeconds();

      switch (commandValue) {
        case 1:  // Start round
          Serial.println("Starting the round at " + String(elapsedSeconds) + "s...");
          fsrHandler->resetPunchCount();
          timeHandler->reset();
          timeHandler->start();
          roundActive = true;
          isPaused = false;
          bluetoothHandler->sendMessage("{\"RoundState\":\"Started\",\"Time\":\"" + String(elapsedSeconds) + "...s\"}");
          bluetoothHandler->clearMessage();
          break;
        case 2:  // Pause round
          Serial.println("Pausing the round at " + String(elapsedSeconds) + "s...");
          timeHandler->pause();
          isPaused = true;
          bluetoothHandler->sendMessage("{\"RoundState\":\"Paused\",\"Time\":\"" + String(elapsedSeconds) + "...s\"}");
          bluetoothHandler->clearMessage();
          break;
        case 3:  // Resume round
          Serial.println("Resuming the round at " + String(elapsedSeconds) + "s...");
          timeHandler->resume();
          isPaused = false;
          bluetoothHandler->sendMessage("{\"RoundState\":\"Resumed\",\"Time\":\"" + String(elapsedSeconds) + "...s\"}");
          bluetoothHandler->clearMessage();
          break;
        case 4:  // Reset round
          Serial.println("Resetting the round at " + String(elapsedSeconds) + "s...");
          fsrHandler->resetPunchCount();
          timeHandler->reset();
          timeHandler->start();
          roundActive = true;
          isPaused = false;
          bluetoothHandler->sendMessage("{\"RoundState\":\"Reset\",\"Time\":\"0s\"}");
          bluetoothHandler->clearMessage();
          break;
        case 5:  // End round
          Serial.println("Ending the round at " + String(elapsedSeconds) + "s...");
          roundActive = false;
          bluetoothHandler->sendMessage("{\"RoundState\":\"Ended\",\"FinalTime\":\"" + String(elapsedSeconds) + "s\"}");
          timeHandler->reset();
          fsrHandler->resetPunchCount();
          bluetoothHandler->clearMessage();
          break;
        default:
          Serial.println("Unknown Command Received.");
          bluetoothHandler->sendMessage("{\"Error\":\"Unknown Command\"}");
          bluetoothHandler->clearMessage();
          break;
      }
    }
  }
}

// == Modify BoxingApp::handleCommands(), replacing elapsed-relative with RTC ==
// void BoxingApp::handleCommands() {
//   String msg = bluetoothHandler->readMessage();
//   if (msg.length() == 0) return;
//   StaticJsonDocument<256> jsonDoc;
//   if (deserializeJson(jsonDoc, msg)) return;

//   if (jsonDoc.containsKey("RoundStatusCommand")) {
//     int cmd = jsonDoc["RoundStatusCommand"]["Command"];
//     String ts = getFormattedTime();
//     switch (cmd) {
//       case 1: // Start
//         Serial.println("Starting the round at " + ts);
//         fsrHandler->resetPunchCount();
//         timeHandler->reset();
//         timeHandler->start();
//         roundActive = true; isPaused = false;
//         bluetoothHandler->sendMessage(
//           String("{\"RoundState\":\"Started\",\"Timestamp\":\"") + ts + "\"}");
//         break;
//       case 2: // Pause
//         Serial.println("Pausing the round at " + ts);
//         timeHandler->pause(); isPaused = true;
//         bluetoothHandler->sendMessage(
//           String("{\"RoundState\":\"Paused\",\"Timestamp\":\"") + ts + "\"}");
//         break;
//       case 3: // Resume
//         Serial.println("Resuming the round at " + ts);
//         timeHandler->resume(); isPaused = false;
//         bluetoothHandler->sendMessage(
//           String("{\"RoundState\":\"Resumed\",\"Timestamp\":\"") + ts + "\"}");
//         break;
//       case 4: // Reset
//         Serial.println("Resetting the round at " + ts);
//         fsrHandler->resetPunchCount();
//         timeHandler->reset(); timeHandler->start();
//         roundActive = true; isPaused = false;
//         bluetoothHandler->sendMessage(
//           String("{\"RoundState\":\"Reset\",\"Timestamp\":\"") + ts + "\"}");
//         break;
//       case 5: // End
//         Serial.println("Ending the round at " + ts);
//         roundActive = false;
//         bluetoothHandler->sendMessage(
//           String("{\"RoundState\":\"Ended\",\"Timestamp\":\"") + ts + "\"}");
//         timeHandler->reset(); fsrHandler->resetPunchCount();
//         break;
//       default:
//         Serial.println("Unknown Command");
//         bluetoothHandler->sendMessage("{\"Error\":\"Unknown Command\"}");
//         break;
//     }
//     bluetoothHandler->clearMessage();
//   }
// }

void BoxingApp::sendPunchData() {
  unsigned long elapsedMilliseconds = timeHandler->getElapsedMilliseconds();

  if (fsrHandler->getFsrValue() > fsrHandler->getThreshold()) {
    fsrHandler->increasePunch();
    String punchDetails = fsrHandler->getPunchDetails(elapsedMilliseconds);
    //Serial.println(punchDetails); // print the message in terminal <--------------------------------------------
    bluetoothHandler->sendMessage(punchDetails);
  }
}