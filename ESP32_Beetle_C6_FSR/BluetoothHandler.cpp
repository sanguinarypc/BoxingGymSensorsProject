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
  pTxCharacteristic->setValue(message.c_str());
  pTxCharacteristic->notify();                 // Using notify without connection id.
  Serial.println("Sent Message: " + message);  // Print the message that is sending in terminal
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
  parent->connectedClients.push_back(1);  // Dummy ID; adjust as needed.
  Serial.println("Device connected. Total connections: " + String(parent->connectedClients.size()));
  parent->pTxCharacteristic->setValue("");
  parent->pTxCharacteristic->notify();
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
