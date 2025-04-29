// FSRPunchDetector.h
#ifndef FSR_PUNCH_DETECTOR_H
#define FSR_PUNCH_DETECTOR_H

#include <Arduino.h>
#include <vector>
#include <initializer_list>

class FSRPunchDetector {
private:
  std::vector<int> fsrPins;
  int fsrSensitivity;
  int fsrThreshold;
  bool isPressed;
  int punchCount;
  int punchPower;
  float sensorVoltage;
  int fsrValue;
  unsigned long lastPunchTime;

public:
  // Now takes a list of pins + sensitivity + threshold
  FSRPunchDetector(const std::initializer_list<int>& pins,
                   int sensitivity,
                   int threshold);

  void setup();
  bool checkPunch();

  float getSensorVoltage();
  int   getFsrValue();

  void  setSensitivity(int value);
  int   getSensitivity();
  void  setThreshold(int value);
  int   getThreshold();

  void  increasePunch();
  int   getPunchCount();
  void  resetPunchCount();
  String getPunchDetails(unsigned long elapsedMilliseconds);

  // Internals for result formatting
  void calculateResults(int fsrSensorValue,
                        float R_FSR,
                        unsigned long punchTimestamp,
                        String &outputMessage);
};

#endif  // FSR_PUNCH_DETECTOR_H














// #include <sys/_intsup.h>
// #ifndef FSR_PUNCH_DETECTOR_H
// #define FSR_PUNCH_DETECTOR_H

// #include <Arduino.h>

// class FSRPunchDetector {
// private:
//   int fsrPin;
//   int fsrPin2;
//   int fsrPin3;
//   int fsrSensitivity;
//   int fsrThreshold;
//   bool isPressed;
//   int punchCount;
//   int punchPower;
//   float sensorVoltage;
//   int fsrValue;
//   unsigned long lastPunchTime;

// public:
//   FSRPunchDetector(int fsrPin, int sensitivity);
//   void setup();
//   bool checkPunch();
//   float getSensorVoltage();
//   //void setFsrValue();
//   int getFsrValue();
//   void setSensitivity(int value);
//   int getSensitivity();
//   void setThreshold(int value);
//   int getThreshold();
//   void increasePunch();
//   int getPunchCount();
//   void resetPunchCount();
//   String getPunchDetails(unsigned long elapsedMilliseconds);

//   // Used internally for result formatting
//   void calculateResults(int fsrSensorValue, float R_FSR, unsigned long punchTimestamp, String &outputMessage);
// };

// #endif  // FSR_PUNCH_DETECTOR_H
