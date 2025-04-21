#ifndef BLUETOOTH_HANDLER_H
#define BLUETOOTH_HANDLER_H

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <vector>

#define SERVICE_UUID "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

class BluetoothHandler {
public:
  BluetoothHandler();
  void begin(const char* deviceName);
  void sendMessage(const String& message);
  String readMessage();
  void clearMessage();
  bool isDeviceConnected();

private:
  BLEServer* pServer;
  BLECharacteristic* pTxCharacteristic;
  BLECharacteristic* pRxCharacteristic;
  std::vector<uint16_t> connectedClients;
  String receivedMessage;

  // For debugging messages
  String lastSentMessage = "";
  int duplicateMessageCount = 0;

  class ServerCallbacks : public BLEServerCallbacks {
    BluetoothHandler* parent;
  public:
    ServerCallbacks(BluetoothHandler* parentInstance);
    void onConnect(BLEServer* pServer) override;
    void onDisconnect(BLEServer* pServer) override;
  };

  class RxCallbacks : public BLECharacteristicCallbacks {
    BluetoothHandler* parent;
  public:
    RxCallbacks(BluetoothHandler* parentInstance);
    void onWrite(BLECharacteristic* pCharacteristic) override;
  };

  ServerCallbacks serverCallbacks;
  RxCallbacks rxCallbacks;
  void cleanDisconnectedClients();
};

#endif  // BLUETOOTH_HANDLER_H
















// #ifndef BLUETOOTH_HANDLER_H
// #define BLUETOOTH_HANDLER_H

// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>
// #include <vector>

// #define SERVICE_UUID "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
// #define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
// #define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

// class BluetoothHandler {
// public:
//   BluetoothHandler();
//   void begin(const char* deviceName);
//   void sendMessage(const String& message);
//   String readMessage();
//   void clearMessage();
//   bool isDeviceConnected();

// private:
//   BLEServer* pServer;
//   BLECharacteristic* pTxCharacteristic;
//   BLECharacteristic* pRxCharacteristic;
//   std::vector<uint16_t> connectedClients;
//   String receivedMessage;

//   // added for debugging messages
//   String lastSentMessage = "";
//   int duplicateMessageCount = 0;

//   class ServerCallbacks : public BLEServerCallbacks {
//     BluetoothHandler* parent;
//   public:
//     ServerCallbacks(BluetoothHandler* parentInstance);
//     void onConnect(BLEServer* pServer, esp_ble_gatts_cb_param_t* param);
//     void onDisconnect(BLEServer* pServer, esp_ble_gatts_cb_param_t* param);
//   };

//   class RxCallbacks : public BLECharacteristicCallbacks {
//     BluetoothHandler* parent;
//   public:
//     RxCallbacks(BluetoothHandler* parentInstance);
//     void onWrite(BLECharacteristic* pCharacteristic);
//   };

//   ServerCallbacks serverCallbacks;
//   RxCallbacks rxCallbacks;
//   void cleanDisconnectedClients();
// };

// #endif  // BLUETOOTH_HANDLER_H
