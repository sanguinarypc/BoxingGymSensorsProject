#ifndef BLUETOOTH_HANDLER_H
#define BLUETOOTH_HANDLER_H

#include <Arduino.h>
#include <ArduinoBLE.h>

// Custom UART-like service & characteristics
#define SERVICE_UUID            "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_RX  "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX  "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

class BluetoothHandler {
public:
  BluetoothHandler();

  // Initialize BLE, advertise as deviceName
  void begin(const char* deviceName);

  // Must be called in loop() to handle BLE events
  void poll();

  // Send data via TX
  void sendMessage(const String &message);

  // Check if at least one central is connected
  bool isDeviceConnected();

  // Read and clear last incoming data from RX
  String readMessage();
  void clearMessage();

private:
  // Our BLE service & characteristics (ArduinoBLE)
  BLEService        service;
  BLECharacteristic rxCharacteristic;
  BLECharacteristic txCharacteristic;

  // Keep track of data from RX
  String receivedMessage;

  // Keep track of the device name
  const char* _deviceName;

  // For demonstration: track duplicates
  String lastSentMessage;
  int duplicateMessageCount;

  // Track how many centrals have connected
  int connectionCount;

  // Static pointer so the event handlers can access class members
  static BluetoothHandler* instance;

  // Callback for RX writes
  static void onRxWrite(BLEDevice central, BLECharacteristic characteristic);

  // Callbacks for connecting/disconnecting
  static void onCentralConnect(BLEDevice central);
  static void onCentralDisconnect(BLEDevice central);
};

#endif // BLUETOOTH_HANDLER_H
