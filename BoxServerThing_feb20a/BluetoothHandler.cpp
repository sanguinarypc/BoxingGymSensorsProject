#include "BluetoothHandler.h"
#include <WiFi.h>

// Initialize static pointer
BluetoothHandler* BluetoothHandler::instance = nullptr;

BluetoothHandler::BluetoothHandler()
  // Reserve 512 bytes if you want larger read/write buffers
  : service(SERVICE_UUID),
    rxCharacteristic(CHARACTERISTIC_UUID_RX, BLEWrite | BLEWriteWithoutResponse, 512),
    txCharacteristic(CHARACTERISTIC_UUID_TX, BLERead | BLENotify, 512)
{
  receivedMessage       = "";
  lastSentMessage       = "";
  duplicateMessageCount = 0;
  connectionCount       = 0;
}

void BluetoothHandler::begin(const char* deviceName) {
  instance = this;
  _deviceName = deviceName;

  // Start ArduinoBLE
  if (!BLE.begin()) {
    Serial.println("Failed to initialize ArduinoBLE!");
    while (1); // Stop if BLE init fails
  }

  // Set the local name and prepare to advertise
  BLE.setLocalName(_deviceName);
  BLE.setAdvertisedService(service);

  // Add characteristics to our service
  service.addCharacteristic(rxCharacteristic);
  service.addCharacteristic(txCharacteristic);

  // When RX is written, call onRxWrite
  rxCharacteristic.setEventHandler(BLEWritten, onRxWrite);

  // Add the service and start advertising
  BLE.addService(service);
  BLE.advertise();

  // Set event handlers for connect/disconnect
  BLE.setEventHandler(BLEConnected, onCentralConnect);
  BLE.setEventHandler(BLEDisconnected, onCentralDisconnect);

  Serial.print("BLE is active, advertising as: ");
  Serial.println(_deviceName);
}

void BluetoothHandler::poll() {
  // Must be called often in loop() to handle BLE events
  BLE.poll();
}

void BluetoothHandler::sendMessage(const String &message) {
  if (!isDeviceConnected()) {
    // Skip if no central connected
    return;
  }

  // Example logic: track duplicates
  if (message == lastSentMessage) {
    duplicateMessageCount++;
  } else {
    duplicateMessageCount = 0;
  }
  lastSentMessage = message;

  // Append duplicate count to the message (debugging)
  // String formattedMessage = message + " | Duplicates: " + String(duplicateMessageCount);
  String formattedMessage = message;

  // Write out via TX characteristic
  txCharacteristic.writeValue((const uint8_t*)formattedMessage.c_str(),
                              formattedMessage.length());

  Serial.println("Sent: " + formattedMessage);
}

bool BluetoothHandler::isDeviceConnected() {
  return BLE.connected(); // True if a central is connected
}

String BluetoothHandler::readMessage() {
  return receivedMessage;
}

void BluetoothHandler::clearMessage() {
  receivedMessage = "";
}

// Called whenever RX characteristic is written
void BluetoothHandler::onRxWrite(BLEDevice central, BLECharacteristic characteristic) {
  if (instance) {
    // Convert raw bytes to a String
    const uint8_t* data = characteristic.value();
    unsigned length     = characteristic.valueLength();

    String incoming;
    for (unsigned i = 0; i < length; i++) {
      incoming += (char)data[i];
    }
    incoming.trim();

    instance->receivedMessage = incoming;

    Serial.print("Received via RX : ");
    Serial.println(incoming);
  }
}

// Called when a central connects
void BluetoothHandler::onCentralConnect(BLEDevice central) {
  if (!instance) return;
  instance->connectionCount++;
  Serial.print("Connected to Wi-Fi! IP Address: ");
  Serial.println(WiFi.localIP());
  Serial.print("BoxServer is connected with a client. Total connections: ");
  Serial.println(instance->connectionCount);
}

// Called when a central disconnects
void BluetoothHandler::onCentralDisconnect(BLEDevice central) {
  if (!instance) return;
  if (instance->connectionCount > 0) {
    instance->connectionCount--;
  }
  Serial.print("Connected to Wi-Fi! IP Address: ");
  Serial.println(WiFi.localIP());
  Serial.print("Client disconnected. Remaining connections: ");
  Serial.println(instance->connectionCount);
}
