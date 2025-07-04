#include "BoxingApp.h"
#include <ArduinoJson.h>
#include <BLEDevice.h>
#include "MacDevicesConfig.h"  // mac address store header

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
  // fsrHandler = new FSRPunchDetector(6, fsrSensitivity);
  // new: watch pins 4, 5, and 6
  fsrHandler = new FSRPunchDetector({ 4, 5, 6 },
                                    fsrSensitivity,
                                    fsrThreshold);

  timeHandler = new TimeHandler();
}

void BoxingApp::setup() {
  Serial.begin(115200);

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

void BoxingApp::sendPunchData() {
  unsigned long elapsedMilliseconds = timeHandler->getElapsedMilliseconds();

  if (fsrHandler->getFsrValue() > fsrHandler->getThreshold()) {
    fsrHandler->increasePunch();
    String punchDetails = fsrHandler->getPunchDetails(elapsedMilliseconds);
    //Serial.println(punchDetails); // print the message in terminal <--------------------------------------------
    bluetoothHandler->sendMessage(punchDetails);
  }
}