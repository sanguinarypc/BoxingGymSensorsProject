#include "BoxingApp.h"
#include <ArduinoJson.h>
#include <BLEDevice.h>
#include "MacDevicesConfig.h"  // mac address store header

// Global variable for device name
String DEVICE_NAME = "";

// SleepHandler* sleepHandler;

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

  // Optionally start your time handler here: timeHandler->start();
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

  // (Optional sleep/inactivity handling commented out)
}

void BoxingApp::handleCommands() {
  String incomingMessage = bluetoothHandler->readMessage();
  if (incomingMessage.length() > 0) {
    //  Serial.println("Received: " + incomingMessage);

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

  // Fetch punch details with elapsed time
  //fsrHandler->setFsrValue();

  if (fsrHandler->getFsrValue() > fsrHandler->getThreshold()) {
    fsrHandler->increasePunch();
    String punchDetails = fsrHandler->getPunchDetails(elapsedMilliseconds);
    //int i = fsrHandler->getPunchCount();


    //Serial.println(fsrHandler->getFsrValue());
    //Serial.println(punchDetails); // print the message in terminal <--------------------------------------------
    bluetoothHandler->sendMessage(punchDetails);
  }
}

// void BoxingApp::sendPunchData1() {
//   unsigned long elapsedMilliseconds = timeHandler->getElapsedMilliseconds();

//   // Use checkPunch() so we trigger only when a new punch is detected
//   if (fsrHandler->checkPunch()) {
//     fsrHandler->increasePunch();
//     String punchDetails = fsrHandler->getPunchDetails(elapsedMilliseconds);
//     Serial.println("Punch detected: " + punchDetails);

//     // Reset duplicate counter for new messages
//     if (punchDetails != lastSentPunch) {
//       duplicatePunchCount = 0;
//       lastSentPunch = punchDetails;
//       bluetoothHandler->sendMessage(punchDetails);
//     } else {
//       duplicatePunchCount++;
//       if (duplicatePunchCount % 5 == 0) {
//         bluetoothHandler->sendMessage(punchDetails);
//       }
//     }
//   } else {
//     // For debugging: print sensor value and threshold
//     Serial.println("No punch event. Sensor: " + String(fsrHandler->getFsrValue()) +
//     ", Sensitivity: " + String(fsrHandler->getSensitivity()) +
//     ", Threshold: " + String(fsrHandler->getThreshold()));
//   }
// }

// void BoxingApp::sendPunchData2() {
//   unsigned long elapsedMilliseconds = timeHandler->getElapsedMilliseconds();

//   // Use checkPunch() so we trigger only when a new punch is detected
//   if (fsrHandler->checkPunch()) {
//     fsrHandler->increasePunch();
//     String punchDetails = fsrHandler->getPunchDetails(elapsedMilliseconds);
//     Serial.println("Punch detected: " + punchDetails);

//     // Reset duplicate counter for new messages
//     if (punchDetails != lastSentPunch) {
//       duplicatePunchCount = 0;
//       lastSentPunch = punchDetails;
//       bluetoothHandler->sendMessage(punchDetails);
//     } else {
//       duplicatePunchCount++;
//       if (duplicatePunchCount % 5 == 0) {
//         bluetoothHandler->sendMessage(punchDetails);
//       }
//     }
//   } else {
//     // For debugging: print sensor value and threshold
//     Serial.println("No punch event. Sensor: " + String(fsrHandler->getFsrValue()) +
//                    ", Sensitivity: " + String(fsrHandler->getSensitivity()) +
//                    ", Threshold: " + String(fsrHandler->getThreshold()));
//   }
// }

// void BoxingApp::sendPunchData3() {
//   unsigned long elapsedMilliseconds = timeHandler->getElapsedMilliseconds();

//   // Use the new delta-based checkPunch() method.
//   if (fsrHandler->checkPunch()) {
//     fsrHandler->increasePunch();
//     String punchDetails = fsrHandler->getPunchDetails(elapsedMilliseconds);
//     Serial.println("Punch detected: " + punchDetails);

//     // Duplicate message prevention (unchanged from your version)
//     if (punchDetails != lastSentPunch) {
//       duplicatePunchCount = 0;
//       lastSentPunch = punchDetails;
//       bluetoothHandler->sendMessage(punchDetails);
//     } else {
//       duplicatePunchCount++;
//       if (duplicatePunchCount % 5 == 0) {
//         bluetoothHandler->sendMessage(punchDetails);
//       }
//     }
//   }
//    else {
//     // Optional debugging information:
//     // Serial.println("No punch event. Sensor: " + String(fsrHandler->getFsrValue()) +
//     //                ", Sensitivity: " + String(fsrHandler->getSensitivity()) +
//     //                ", Threshold: " + String(fsrHandler->getThreshold()));
//   }
// }

// void BoxingApp::sendPunchData4() {
//   unsigned long elapsedMilliseconds = timeHandler->getElapsedMilliseconds();

//   if (fsrHandler->checkPunch()) {
//     fsrHandler->increasePunch();
//     String punchDetails = fsrHandler->getPunchDetails(elapsedMilliseconds);
//     Serial.println("Punch detected: " + punchDetails);
//     bluetoothHandler->sendMessage(punchDetails);
//   } else {
//     // For debugging, you might print sensor info:
//     Serial.println("No punch event. Sensor: " + String(fsrHandler->getFsrValue()) +
//                    ", Sensitivity: " + String(fsrHandler->getSensitivity()) +
//                    ", Release Threshold: " + String(fsrHandler->getThreshold()));
//   }
// }
















// -------------------------------------------------------------------------------------
// #include "BoxingApp.h"
// #include <ArduinoJson.h>
// #include <BLEDevice.h>
// #include "MacDevicesConfig.h" // mac adress store header

// // Global variable for device name
// String DEVICE_NAME = "";

// // SleepHandler* sleepHandler;

// BoxingApp::BoxingApp()
//   : startReading(false), roundTime(180000), breakTime(60000), fsrSensitivity(800),
//     isPaused(false), elapsedTime(0), command(0), roundActive(false) {

//   bluetoothHandler = new BluetoothHandler();
//   fsrHandler = new FSRPunchDetector(6, fsrSensitivity);  // GPIO36 for FSR input, GPIO15 for LED
//   timeHandler = new TimeHandler();
// }

// void BoxingApp::setup() {
//   Serial.begin(115200);

//     // Initialize SleepHandler
//     //  sleepHandler = new SleepHandler();

//     // Detect wake-up cause (this prints why the ESP32 woke up)
//     //sleepHandler->wakeUpHandler();

//     // Set a timer wake-up (Example: 10 seconds)
//     // sleepHandler->enableTimerWakeUp(300);  // Wakes up after 10 seconds

//     // Enable external wake-up on GPIO 5 (wakes up if GPIO 5 goes HIGH)
//     // sleepHandler->enableExtWakeUp(1ULL << 6, ESP_EXT1_WAKEUP_ANY_HIGH);


//   // Initialize BLE
//   BLEDevice::init("");
//   // Get and print the BLE mac address of a BLE device
//   String bleAddress = BLEDevice::getAddress().toString().c_str();
//   Serial.print("BLE Address: ");
//   Serial.println(bleAddress.c_str());

//   // Assign the device name based on the BLE address
//   // if (bleAddress.equals(mac_BlueBoxer) || bleAddress.equals(mac_BlueBoxer2)) {
//   //   DEVICE_NAME = "BlueBoxer";
//   // } else if (bleAddress.equals(mac_RedBoxer)) {
//   //   DEVICE_NAME = "RedBoxer";
//   // } else {
//   //   DEVICE_NAME = "UnknownDevice"; // Fallback for unknown devices
//   // }


//   // Default name
//   DEVICE_NAME = "UnknownDevice";

//   // Check BlueBoxer list
//   for (int i = 0; i < NUM_BLUEBOXER_MACS; i++) {
//     if (bleAddress.equalsIgnoreCase(BLUEBOXER_MACS[i])) {
//       DEVICE_NAME = "BlueBoxer";
//       break;
//     }
//   }

//   // If still unknown, check RedBoxer list
//   if (DEVICE_NAME.equals("UnknownDevice")) {
//     for (int i = 0; i < NUM_REDBOXER_MACS; i++) {
//       if (bleAddress.equalsIgnoreCase(REDBOXER_MACS[i])) {
//         DEVICE_NAME = "RedBoxer";
//         break;
//       }
//     }
//   }

//   // Set the device name in the Bluetooth handler
//   DEVICE_NAME.trim(); // Trim whitespace
//   // Reinitialize BLE with the device name
//   BLEDevice::deinit(); // Ensure the BLE stack is reset
//   BLEDevice::init(DEVICE_NAME.c_str()); // Reinitialize with the device name

//   bluetoothHandler->begin(DEVICE_NAME.c_str()); // Set the device name in the Bluetooth handler
//   // bluetoothHandler->begin("RedBoxer");  // BlueBoxer RedBoxer
//   fsrHandler->setup();
//   Serial.print(DEVICE_NAME);
//   Serial.print(" BLE Device is Ready  ");
//   Serial.println("BoxingApp is ready... ");
//   Serial.println("Waiting for client connections...");

//   //timeHandler->start();
// }

// void BoxingApp::loop() {
//   handleCommands();


//   // If the round is active and not paused, check for punches
//   if (roundActive && !isPaused) {
//     //Serial.println("-------1------");
//     if (fsrHandler->checkPunch()) {
//       //Serial.println("--------2------");
//       sendPunchData();  // Send sensor values to Android
//     }

//     // End the round when time elapses
//     if (timeHandler->getElapsedMilliseconds() >= roundTime) {
//       Serial.println("Round complete.");
//       roundActive = false;
//       bluetoothHandler->sendMessage("{\"RoundState\":\"Completed\"}");
//       timeHandler->reset();
//     }
//   }


//   // **FIX: Use inactivity timeout before entering deep sleep**
//   // **Wait for 5 minutes (300,000 milliseconds) before entering light sleep**
//   // static unsigned long lastActivityTime = millis(); // Track last activity
//   // static bool sleepTriggered = false;

//   // if (roundActive || isPaused) {
//   //     lastActivityTime = millis(); // Reset inactivity timer if active
//   //     sleepTriggered = false;  // Reset sleep flag
//   // }

//   // // If no activity for 30 seconds, go to sleep
//   // if (!roundActive && !isPaused && (millis() - lastActivityTime > 300000)) {
//   //     if (!sleepTriggered) {
//   //         Serial.println("No activity for 5 minutes, preparing to enter deep sleep...");
//   //         sleepTriggered = true;  // Prevent immediate re-looping
//   //         delay(500); // Allow messages to print
//   //         // sleepHandler->enterDeepSleep();
//   //         // Serial.println("No activity for 5 minutes, entering light sleep...");
//   //         // **NEW: Delay before allowing sleep again to prevent instant wake/sleep loop**
//   //           delay(10000); // Wait 10 seconds before sleeping again
//   //         sleepHandler->enterLightSleep(true);  // Enable Bluetooth wake-up
//   //     }
//   // }


// }

// void BoxingApp::handleCommands() {
//   String incomingMessage = bluetoothHandler->readMessage();
//   //Serial.println("Received: " + incomingMessage.length());
//   if (incomingMessage.length() > 0) {
//     Serial.println("Received: " + incomingMessage);


//     // Create a JSON document to parse the incoming message
//     StaticJsonDocument<256> jsonDoc;
//     DeserializationError error = deserializeJson(jsonDoc, incomingMessage);

//     // Check if JSON parsing was successful
//     if (error) {
//       Serial.print("JSON Parsing Failed: ");
//       Serial.println(error.c_str());
//       return;
//     }

//     // Update sensor settings
//     if (jsonDoc.containsKey("SensorSettings")) {

//       JsonObject settings = jsonDoc["SensorSettings"];
//       roundTime = settings["RoundTime"];
//       breakTime = settings["BreakTime"];
//       fsrSensitivity = settings["FsrSensitivity"];
//       fsrHandler->setFsrSensitivity(fsrSensitivity);
//       Serial.println("Sensor settings updated.");
//       Serial.println(fsrHandler->getThreshold());
//       bluetoothHandler->sendMessage("{\"RoundState\":\"Settings Updated\"}");
//       bluetoothHandler->clearMessage();
//     }

//     // Handle round commands
//     if (jsonDoc.containsKey("RoundStatusCommand")) {
//       int commandValue = jsonDoc["RoundStatusCommand"]["Command"];
//       unsigned long elapsedSeconds = timeHandler->getElapsedSeconds();

//       switch (commandValue) {
//         case 1:  // Start round
//           Serial.println("Starting the round at " + String(timeHandler->getElapsedSeconds()) + "...");
//           fsrHandler->resetPunchCount();
//           timeHandler->reset();  // Reset the timer to 0
//           timeHandler->start();  // Start the timer from 0
//           roundActive = true;
//           isPaused = false;
//           bluetoothHandler->sendMessage("{\"RoundState\":\"Started\",\"Time\":\"" + String(timeHandler->getElapsedSeconds()) + "...s\"}");
//           bluetoothHandler->clearMessage();
//           break;

//         case 2:  // Pause round
//           Serial.println("Pausing the round at " + String(timeHandler->getElapsedSeconds()) + "...");
//           timeHandler->pause();
//           isPaused = true;
//           bluetoothHandler->sendMessage("{\"RoundState\":\"Paused\",\"Time\":\"" + String(timeHandler->getElapsedSeconds()) + "...s\"}");
//           bluetoothHandler->clearMessage();
//           break;
//         case 3:  // Resume round
//           Serial.println("Resuming the round at " + String(timeHandler->getElapsedSeconds()) + "...");
//           timeHandler->resume();
//           isPaused = false;
//           bluetoothHandler->sendMessage("{\"RoundState\":\"Resumed\",\"Time\":\"" + String(timeHandler->getElapsedSeconds()) + "...s\"}");
//           bluetoothHandler->clearMessage();
//           break;
//         case 4:  // Reset round
//           Serial.println("Resetting the round at " + String(timeHandler->getElapsedSeconds()) + "...");
//           fsrHandler->resetPunchCount();
//           timeHandler->reset();
//           timeHandler->start();
//           roundActive = true;
//           isPaused = false;
//           bluetoothHandler->sendMessage("{\"RoundState\":\"Reset\",\"Time\":\"0s\"}");
//           bluetoothHandler->clearMessage();
//           break;

//         case 5:  // End round
//           Serial.println("Ending the round at " + String(timeHandler->getElapsedSeconds()) + "...");
//           roundActive = false;
//           bluetoothHandler->sendMessage("{\"RoundState\":\"Ended\",\"FinalTime\":\"" + String(timeHandler->getElapsedSeconds()) + "s\"}");
//           timeHandler->reset();  // Reset the timer to 0
//           fsrHandler->resetPunchCount();
//           bluetoothHandler->clearMessage();
//           break;
//         default:
//           Serial.println("Unknown Command Received.");
//           bluetoothHandler->sendMessage("{\"Error\":\"Unknown Command\"}");
//           bluetoothHandler->clearMessage();
//           break;
//       }
//     }
//   }
// }

// void BoxingApp::sendPunchData() {
//   unsigned long elapsedMilliseconds = timeHandler->getElapsedMilliseconds();

//   // Fetch punch details with elapsed time
//   //fsrHandler->setFsrValue();

//   if (fsrHandler->getFsrValue() > fsrHandler->getThreshold()) {
//     fsrHandler->increasePunch();
//     String punchDetails = fsrHandler->getPunchDetails(elapsedMilliseconds);
//     //int i = fsrHandler->getPunchCount();


//     //Serial.println(fsrHandler->getFsrValue());
//     Serial.println(punchDetails);
//     bluetoothHandler->sendMessage(punchDetails);
//   }
// }