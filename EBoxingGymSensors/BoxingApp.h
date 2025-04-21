#ifndef BOXING_APP_H
#define BOXING_APP_H

#include <Arduino.h>
#include "BluetoothHandler.h"
#include "FSRPunchDetector.h"
#include "TimeHandler.h"
// #include "SleepHandler.h"

class BoxingApp {
private:
  BluetoothHandler* bluetoothHandler;
  FSRPunchDetector* fsrHandler;
  TimeHandler* timeHandler;

  // App configuration
  bool startReading;
  long roundTime;
  long breakTime;
  int fsrSensitivity;
  int fsrThreshold;
  bool isPaused;
  unsigned long elapsedTime;
  int command;
  bool roundActive;

  // added for debugging messages
  String lastSentPunch;     // Stores the last punch details to detect duplicates
  int duplicatePunchCount;  // Counts how many times the same punch was detected

  void handleCommands();

public:
  BoxingApp();
  void setup();
  void loop();
  void sendPunchData();  // Sends punch data with duplicate prevention
};

#endif  // BOXING_APP_H