#ifndef FSR_PUNCH_DETECTOR_H
#define FSR_PUNCH_DETECTOR_H

#include <Arduino.h>

class FSRPunchDetector {
private:
  int fsrPin;
  int fsrSensitivity;
  int fsrThreshold;
  bool isPressed;
  int punchCount;
  int punchPower;
  float sensorVoltage;
  int fsrValue;
  unsigned long lastPunchTime;

public:
  FSRPunchDetector(int fsrPin, int sensitivity);
  void setup();
  bool checkPunch();
  float getSensorVoltage();
  //void setFsrValue();
  int getFsrValue();
  void setSensitivity(int value);
  int getSensitivity();
  void setThreshold(int value);
  int getThreshold();
  void increasePunch();
  int getPunchCount();
  void resetPunchCount();
  String getPunchDetails(unsigned long elapsedMilliseconds);

  // Used internally for result formatting
  void calculateResults(int fsrSensorValue, float R_FSR, unsigned long punchTimestamp, String &outputMessage);
};

#endif  // FSR_PUNCH_DETECTOR_H
