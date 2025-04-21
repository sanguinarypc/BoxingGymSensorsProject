#include "BluetoothHandler.h"
#include "esp_gap_ble_api.h"  // For security parameters if needed
#include <string.h>

BluetoothHandler::BluetoothHandler()
  : pServer(nullptr), pTxCharacteristic(nullptr), pRxCharacteristic(nullptr),
    serverCallbacks(this), rxCallbacks(this) {}

void BluetoothHandler::begin(const char* deviceName) {
  // Initialize BLE with the given device name.
  BLEDevice::init(deviceName);

  // Set MTU to a value more compatible with Android devices.
  BLEDevice::setMTU(247);

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(&serverCallbacks);

  BLEService* pService = pServer->createService(SERVICE_UUID);

  // Create TX characteristic with notify property.
  pTxCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_TX, BLECharacteristic::PROPERTY_NOTIFY);
  BLE2902* p2902 = new BLE2902();
  p2902->setAccessPermissions(ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE);
  pTxCharacteristic->addDescriptor(p2902);

  // Create RX characteristic with write and read properties.
  pRxCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID_RX, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ);
  pRxCharacteristic->setAccessPermissions(ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE);
  pRxCharacteristic->setCallbacks(&rxCallbacks);

  pService->start();

  // Enable scan response to include the device name.
  BLEAdvertising* pAdvertising = pServer->getAdvertising();
  pAdvertising->setScanResponse(true);
  pAdvertising->start();
  Serial.println("Waiting for client connections...");
}

void BluetoothHandler::sendMessage(const String& message) {
  if (message == lastSentMessage) {
    duplicateMessageCount++;
  } else {
    duplicateMessageCount = 0;
  }
  lastSentMessage = message;
  
  // For debugging, you can log duplicate count if needed.
  String formattedMessage = message;  // Optionally append duplicate info.

  pTxCharacteristic->setValue(formattedMessage.c_str());
  pTxCharacteristic->notify();  // Using notify without connection id.
  Serial.println("Sent Message: " + formattedMessage);  //  <---------------------------------------------------------------------
}

String BluetoothHandler::readMessage() {
  return receivedMessage;
}

void BluetoothHandler::clearMessage() {
  receivedMessage = "";
}

bool BluetoothHandler::isDeviceConnected() {
  return !connectedClients.empty();
}

void BluetoothHandler::cleanDisconnectedClients() {
  connectedClients.erase(
    std::remove_if(connectedClients.begin(), connectedClients.end(),
                   [&](uint16_t handle) {
                     return pServer->getConnectedCount() == 0;
                   }),
    connectedClients.end());
}

// ----------------------- Server Callbacks -----------------------

BluetoothHandler::ServerCallbacks::ServerCallbacks(BluetoothHandler* parentInstance)
  : parent(parentInstance) {}

void BluetoothHandler::ServerCallbacks::onConnect(BLEServer* pServer) {
  // You may not have direct access to a connection ID with this signature.
  // For now, we simply note a connection has been made.
  parent->connectedClients.push_back(1); // Dummy ID; adjust as needed.
  Serial.println("Device connected. Total connections: " + String(parent->connectedClients.size()));
  parent->pTxCharacteristic->setValue("");
  parent->pTxCharacteristic->notify();

  // If multiple connections are allowed, you can restart advertising here.
  // if (pServer->getConnectedCount() < 2) {
  //   pServer->getAdvertising()->start();
  // }
}

void BluetoothHandler::ServerCallbacks::onDisconnect(BLEServer* pServer) {
  parent->connectedClients.clear();
  delay(150);
  Serial.println("Device disconnected. Remaining connections: " + String(parent->connectedClients.size()));
  pServer->startAdvertising();
}

// ----------------------- RX Callbacks -----------------------

BluetoothHandler::RxCallbacks::RxCallbacks(BluetoothHandler* parentInstance)
  : parent(parentInstance) {}

void BluetoothHandler::RxCallbacks::onWrite(BLECharacteristic* pCharacteristic) {
  parent->receivedMessage = pCharacteristic->getValue().c_str();
  parent->receivedMessage.trim();
  Serial.println("Received message: " + parent->receivedMessage);
}

















// #include "BluetoothHandler.h"
// #include "esp_gap_ble_api.h"  // for security parameters
// #include <string.h>

// BluetoothHandler::BluetoothHandler()
//   : pServer(nullptr), pTxCharacteristic(nullptr), pRxCharacteristic(nullptr),
//     serverCallbacks(this), rxCallbacks(this) {}

// void BluetoothHandler::begin(const char* deviceName) {
//   // Initialize BLE with the given device name.
//   BLEDevice::init(deviceName);

//   // Disable pairing/bonding to avoid SMP errors on ESP32-C6.
//   // uint8_t auth_req = ESP_LE_AUTH_NO_BOND;
//   // esp_ble_gap_set_security_param(ESP_BLE_SM_AUTHEN_REQ_MODE, &auth_req, sizeof(uint8_t));

//   // Increase MTU for robust connections
//   BLEDevice::setMTU(247); //512
//   //esp_ble_gatt_set_local_mtu(247);

//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(&serverCallbacks);

//   BLEService* pService = pServer->createService(SERVICE_UUID);

//   // Create TX characteristic with notify property.
//   pTxCharacteristic = pService->createCharacteristic(
//     CHARACTERISTIC_UUID_TX, BLECharacteristic::PROPERTY_NOTIFY);
//   // Create a BLE2902 descriptor and explicitly set its access permissions.
//   BLE2902* p2902 = new BLE2902();
//   p2902->setAccessPermissions(ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE);
//   pTxCharacteristic->addDescriptor(p2902);

//   // Create RX characteristic with write and read properties.
//   pRxCharacteristic = pService->createCharacteristic(
//     CHARACTERISTIC_UUID_RX, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ);
//   pRxCharacteristic->setAccessPermissions(ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE);
//   pRxCharacteristic->setCallbacks(&rxCallbacks);

//   pService->start();

//   // --- NEW CODE: Enable scan response so the device's local name is included ---
//   BLEAdvertising* pAdvertising = pServer->getAdvertising();
//   pAdvertising->setScanResponse(true);  // Include scan response data (local name)
//   // Optionally, set preferred advertising parameters (optional)
//   // pAdvertising->setMinPreferred(0x06);
//   // pAdvertising->setMinPreferred(0x12);
//   pAdvertising->start();
//   // Serial.println("Waiting for client connections...");
// }

// // void BluetoothHandler::sendMessageOriginal(const String& message) {
// //   pTxCharacteristic->setValue(message.c_str());
// //   pTxCharacteristic->notify();
// // }


// void BluetoothHandler::sendMessage(const String& message) {

//   if (message == lastSentMessage) {
//     duplicateMessageCount++;
//   } else {
//     duplicateMessageCount = 0;
//   }

//   lastSentMessage = message;

//   // Append duplicate count to the message for debugging
//   String formattedMessage = message;  //+ " | Duplicates: " + String(duplicateMessageCount);

//   pTxCharacteristic->setValue(formattedMessage.c_str());
//   pTxCharacteristic->notify();
//   Serial.println("Sent: " + formattedMessage);
// }




// String BluetoothHandler::readMessage() {
//   String temp = receivedMessage;
//   return temp;
// }

// void BluetoothHandler::clearMessage() {
//   receivedMessage = "";
// }

// bool BluetoothHandler::isDeviceConnected() {
//   return !connectedClients.empty();
// }

// void BluetoothHandler::cleanDisconnectedClients() {
//   connectedClients.erase(
//     std::remove_if(connectedClients.begin(), connectedClients.end(),
//                    [&](uint16_t handle) {
//                      return pServer->getConnectedCount() == 0;
//                    }),
//     connectedClients.end());
// }

// BluetoothHandler::ServerCallbacks::ServerCallbacks(BluetoothHandler* parentInstance)
//   : parent(parentInstance) {}

// void BluetoothHandler::ServerCallbacks::onConnect(BLEServer* pServer, esp_ble_gatts_cb_param_t* param) {
//   uint16_t connId = param->connect.conn_id;
//   parent->connectedClients.push_back(connId);
//   Serial.println("Device connected. Total connections: " + String(parent->connectedClients.size()));
//   parent->pTxCharacteristic->setValue("");  // Clear any residual value
//   parent->pTxCharacteristic->notify(connId);

//   // Restart advertising if we allow multiple connections.
//   if (pServer->getConnectedCount() < 2) {
//     pServer->getAdvertising()->start();
//   }
// }

// void BluetoothHandler::ServerCallbacks::onDisconnect(BLEServer* pServer, esp_ble_gatts_cb_param_t* param) {
//   uint16_t connId = param->disconnect.conn_id;
//   auto it = std::remove(parent->connectedClients.begin(), parent->connectedClients.end(), connId);
//   parent->connectedClients.erase(it, parent->connectedClients.end());

//   // Wait a short while to let the BLE stack clean up before restarting advertising.
//   delay(150);
//   Serial.println("Device disconnected. Remaining connections: " + String(parent->connectedClients.size()));
//   pServer->startAdvertising();  // Restart advertising.
// }

// BluetoothHandler::RxCallbacks::RxCallbacks(BluetoothHandler* parentInstance)
//   : parent(parentInstance) {}

// void BluetoothHandler::RxCallbacks::onWrite(BLECharacteristic* pCharacteristic) {
//   parent->receivedMessage = pCharacteristic->getValue().c_str();
//   parent->receivedMessage.trim();
//   Serial.println("Received message: " + parent->receivedMessage);
// }




























// #include "BluetoothHandler.h"

// BluetoothHandler::BluetoothHandler()
//   : pServer(nullptr), pTxCharacteristic(nullptr), pRxCharacteristic(nullptr),
//     serverCallbacks(this), rxCallbacks(this) {}

// void BluetoothHandler::begin(const char* deviceName) {
//   BLEDevice::init(deviceName);
//   BLEDevice::setMTU(517);  // Increase MTU for robust connections

//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(&serverCallbacks);

//   BLEService* pService = pServer->createService(SERVICE_UUID);

//   pTxCharacteristic = pService->createCharacteristic(
//     CHARACTERISTIC_UUID_TX, BLECharacteristic::PROPERTY_NOTIFY);
//   pTxCharacteristic->addDescriptor(new BLE2902());

//   pRxCharacteristic = pService->createCharacteristic(
//     CHARACTERISTIC_UUID_RX, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ);
//   pRxCharacteristic->setCallbacks(&rxCallbacks);

//   pService->start();
//   pServer->getAdvertising()->start();
//   // Serial.println("Waiting for client connections...");
// }

// void BluetoothHandler::sendMessage(const String& message) {

//    pTxCharacteristic->setValue(message.c_str());
//    pTxCharacteristic->notify();
//     //cleanDisconnectedClients();

//     //  for (auto connHandle : connectedClients) {
//     // //     if (pTxCharacteristic) {
//     //          pTxCharacteristic->setValue(message.c_str());
//     //          pTxCharacteristic->notify(connHandle);  // Send notification

//     // //         Serial.println("Notification sent to connection handle: " + String(connHandle));
//     // //     }
//     // }
// }


// String BluetoothHandler::readMessage() {
//   String temp = receivedMessage;
//   //receivedMessage = "";
//   return temp;
// }

// void BluetoothHandler::clearMessage() {
//   receivedMessage = "";

// }

// bool BluetoothHandler::isDeviceConnected() {
//   return !connectedClients.empty();
// }

// void BluetoothHandler::cleanDisconnectedClients() {
//   connectedClients.erase(
//     std::remove_if(connectedClients.begin(), connectedClients.end(),
//                    [&](uint16_t handle) {
//                      return pServer->getConnectedCount() == 0;
//                    }),
//     connectedClients.end());
// }


// BluetoothHandler::ServerCallbacks::ServerCallbacks(BluetoothHandler* parentInstance)
//   : parent(parentInstance) {}

//   void BluetoothHandler::ServerCallbacks::onConnect(BLEServer* pServer, esp_ble_gatts_cb_param_t* param) {
//       uint16_t connId = param->connect.conn_id;
//       parent->connectedClients.push_back(connId);
//       Serial.println("Device connected. Total connections: " + String(parent->connectedClients.size()));
//       parent->pTxCharacteristic->setValue("");  // Clear any residual value
//       parent->pTxCharacteristic->notify(connId);

//       if (pServer->getConnectedCount() < 2) {
//         pServer->getAdvertising()->start();
//       }
//   }



//   void BluetoothHandler::ServerCallbacks::onDisconnect(BLEServer* pServer, esp_ble_gatts_cb_param_t* param) {
//       uint16_t connId = param->disconnect.conn_id;
//       auto it = std::remove(parent->connectedClients.begin(), parent->connectedClients.end(), connId);
//       parent->connectedClients.erase(it, parent->connectedClients.end());

//       Serial.println("Device disconnected. Remaining connections: " + String(parent->connectedClients.size()));
//       pServer->startAdvertising();  // Restart advertising
//   }


// BluetoothHandler::RxCallbacks::RxCallbacks(BluetoothHandler* parentInstance)
//   : parent(parentInstance) {}

//   void BluetoothHandler::RxCallbacks::onWrite(BLECharacteristic* pCharacteristic) {
//     parent->receivedMessage = pCharacteristic->getValue().c_str();
//     parent->receivedMessage.trim();
//     Serial.println("Received message: " + parent->receivedMessage);
//   }
















// #include "BluetoothHandler.h"

// BluetoothHandler::BluetoothHandler()
//   : pServer(nullptr), pTxCharacteristic(nullptr), pRxCharacteristic(nullptr),
//     serverCallbacks(this), rxCallbacks(this) {}

// void BluetoothHandler::begin(const char* deviceName) {
//   BLEDevice::init(deviceName);
//   BLEDevice::setMTU(247);  // 512 517 Increase MTU for robust connections

//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(&serverCallbacks);

//   BLEService* pService = pServer->createService(SERVICE_UUID);

//   pTxCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_TX, BLECharacteristic::PROPERTY_NOTIFY);
//   pTxCharacteristic->addDescriptor(new BLE2902());

//   pRxCharacteristic = pService->createCharacteristic(
//     CHARACTERISTIC_UUID_RX, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ);
//   //pRxCharacteristic->setPermissions(ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE);  // #include <BLEDevice.h> and #include <BLE2902.h> from esp32 BLE Arduino, you likely need setPermissions().
//   pRxCharacteristic->setAccessPermissions(ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE);  //  #include <NimBLEDevice.h> or your platformio.ini uses NimBLE-Arduino
//   pRxCharacteristic->setCallbacks(&rxCallbacks);

//   pService->start();
//   pServer->getAdvertising()->start();
//   // Serial.println("Waiting for client connections...");
// }

// void BluetoothHandler::sendMessage(const String& message) {

//   pTxCharacteristic->setValue(message.c_str());
//   pTxCharacteristic->notify();
//   //cleanDisconnectedClients();

//   //  for (auto connHandle : connectedClients) {
//   // //     if (pTxCharacteristic) {
//   //          pTxCharacteristic->setValue(message.c_str());
//   //          pTxCharacteristic->notify(connHandle);  // Send notification

//   // //         Serial.println("Notification sent to connection handle: " + String(connHandle));
//   // //     }
//   // }
// }


// String BluetoothHandler::readMessage() {
//   String temp = receivedMessage;
//   //receivedMessage = "";
//   return temp;
// }

// void BluetoothHandler::clearMessage() {
//   receivedMessage = "";
// }

// bool BluetoothHandler::isDeviceConnected() {
//   return !connectedClients.empty();
// }

// void BluetoothHandler::cleanDisconnectedClients() {
//   connectedClients.erase(
//     std::remove_if(connectedClients.begin(), connectedClients.end(),
//                    [&](uint16_t handle) {
//                      return pServer->getConnectedCount() == 0;
//                    }),
//     connectedClients.end());
// }


// BluetoothHandler::ServerCallbacks::ServerCallbacks(BluetoothHandler* parentInstance)
//   : parent(parentInstance) {}

// void BluetoothHandler::ServerCallbacks::onConnect(BLEServer* pServer, esp_ble_gatts_cb_param_t* param) {
//   uint16_t connId = param->connect.conn_id;
//   parent->connectedClients.push_back(connId);
//   Serial.println("Device connected. Total connections: " + String(parent->connectedClients.size()));
//   parent->pTxCharacteristic->setValue("");  // Clear any residual value
//   parent->pTxCharacteristic->notify(connId);

//   if (pServer->getConnectedCount() < 2) {
//     pServer->getAdvertising()->start();
//   }
// }



// void BluetoothHandler::ServerCallbacks::onDisconnect(BLEServer* pServer, esp_ble_gatts_cb_param_t* param) {
//   uint16_t connId = param->disconnect.conn_id;
//   auto it = std::remove(parent->connectedClients.begin(), parent->connectedClients.end(), connId);
//   parent->connectedClients.erase(it, parent->connectedClients.end());

//   Serial.println("Device disconnected. Remaining connections: " + String(parent->connectedClients.size()));
//   pServer->startAdvertising();  // Restart advertising
// }


// BluetoothHandler::RxCallbacks::RxCallbacks(BluetoothHandler* parentInstance)
//   : parent(parentInstance) {}

// void BluetoothHandler::RxCallbacks::onWrite(BLECharacteristic* pCharacteristic) {
//   parent->receivedMessage = pCharacteristic->getValue().c_str();
//   parent->receivedMessage.trim();
//   Serial.println("Received message: " + parent->receivedMessage);
// }























// #include "BluetoothHandler.h"

// BluetoothHandler::BluetoothHandler()
//   : pServer(nullptr), pTxCharacteristic(nullptr), pRxCharacteristic(nullptr),
//     serverCallbacks(this), rxCallbacks(this) {}

// void BluetoothHandler::begin(const char* deviceName) {
//   BLEDevice::init(deviceName);

//   // ***** FIX: Disable pairing/bonding to avoid SMP errors on ESP32-C6 *****
//   uint8_t auth_req = ESP_LE_AUTH_NO_BOND;
//   esp_ble_gap_set_security_param(ESP_BLE_SM_AUTHEN_REQ_MODE, &auth_req, sizeof(uint8_t));

//   BLEDevice::setMTU(512);  // Increase MTU for robust connections 517

//   pServer = BLEDevice::createServer();
//   pServer->setCallbacks(&serverCallbacks);

//   BLEService* pService = pServer->createService(SERVICE_UUID);

//   // Create TX characteristic with notify property
//   pTxCharacteristic = pService->createCharacteristic(
//       CHARACTERISTIC_UUID_TX, BLECharacteristic::PROPERTY_NOTIFY);
//   // Create a BLE2902 descriptor and explicitly set its access permissions
//   BLE2902* p2902 = new BLE2902();
//   p2902->setAccessPermissions(ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE);
//   pTxCharacteristic->addDescriptor(p2902);

//   // Create RX characteristic with write and read properties
//   pRxCharacteristic = pService->createCharacteristic(
//       CHARACTERISTIC_UUID_RX, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ);
//   pRxCharacteristic->setAccessPermissions(ESP_GATT_PERM_READ | ESP_GATT_PERM_WRITE);
//   pRxCharacteristic->setCallbacks(&rxCallbacks);

//   pService->start();
//   pServer->getAdvertising()->start();
//   // Serial.println("Waiting for client connections...");
// }

// void BluetoothHandler::sendMessage(const String& message) {
//   pTxCharacteristic->setValue(message.c_str());
//   pTxCharacteristic->notify();
// }

// // void BluetoothHandler::sendMessage(const String& message) {

// //   pTxCharacteristic->setValue(message.c_str());
// //   pTxCharacteristic->notify();
// //   cleanDisconnectedClients();

// //    for (auto connHandle : connectedClients) {
// //   //     if (pTxCharacteristic) {
// //            pTxCharacteristic->setValue(message.c_str());
// //            pTxCharacteristic->notify(connHandle);  // Send notification

// //   //         Serial.println("Notification sent to connection handle: " + String(connHandle));
// //   //     }
// //   }
// // }

// String BluetoothHandler::readMessage() {
//   String temp = receivedMessage;
//   return temp;
// }

// void BluetoothHandler::clearMessage() {
//   receivedMessage = "";
// }

// bool BluetoothHandler::isDeviceConnected() {
//   return !connectedClients.empty();
// }

// void BluetoothHandler::cleanDisconnectedClients() {
//   connectedClients.erase(
//     std::remove_if(connectedClients.begin(), connectedClients.end(),
//                    [&](uint16_t handle) {
//                      return pServer->getConnectedCount() == 0;
//                    }),
//     connectedClients.end());
// }

// BluetoothHandler::ServerCallbacks::ServerCallbacks(BluetoothHandler* parentInstance)
//   : parent(parentInstance) {}

// void BluetoothHandler::ServerCallbacks::onConnect(BLEServer* pServer, esp_ble_gatts_cb_param_t* param) {
//   uint16_t connId = param->connect.conn_id;
//   parent->connectedClients.push_back(connId);
//   Serial.println("Device connected. Total connections: " + String(parent->connectedClients.size()));
//   parent->pTxCharacteristic->setValue("");  // Clear any residual value
//   parent->pTxCharacteristic->notify(connId);

//   if (pServer->getConnectedCount() < 2) {
//     pServer->getAdvertising()->start();
//   }
// }

// void BluetoothHandler::ServerCallbacks::onDisconnect(BLEServer* pServer, esp_ble_gatts_cb_param_t* param) {
//   uint16_t connId = param->disconnect.conn_id;
//   auto it = std::remove(parent->connectedClients.begin(), parent->connectedClients.end(), connId);
//   parent->connectedClients.erase(it, parent->connectedClients.end());

//   // Wait a short while to let the BLE stack clean up before restarting advertising
//   delay(150);  // 150 milliseconds is an example; adjust as needed

//   Serial.println("Device disconnected. Remaining connections: " + String(parent->connectedClients.size()));
//   pServer->startAdvertising();  // Restart advertising
// }

// BluetoothHandler::RxCallbacks::RxCallbacks(BluetoothHandler* parentInstance)
//   : parent(parentInstance) {}

// void BluetoothHandler::RxCallbacks::onWrite(BLECharacteristic* pCharacteristic) {
//   parent->receivedMessage = pCharacteristic->getValue().c_str();
//   parent->receivedMessage.trim();
//   Serial.println("Received message: " + parent->receivedMessage);
// }
