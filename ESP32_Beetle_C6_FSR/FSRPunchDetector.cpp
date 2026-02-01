// FSRPunchDetector.cpp
#include "FSRPunchDetector.h"
#include <Arduino.h>

// Declare that DEVICE_NAME is defined in another file (boxingApp.cpp)
extern String DEVICE_NAME;

FSRPunchDetector::FSRPunchDetector(const std::initializer_list<int>& pins,
                                   int sensitivity,
                                   int threshold)
  : fsrPins(pins.begin(), pins.end()),
    fsrSensitivity(sensitivity),
    fsrThreshold(threshold),
    isPressed(false),
    punchCount(0),
    punchPower(0),
    sensorVoltage(0.0f),
    fsrValue(0),
    lastPunchTime(0UL) {}

void FSRPunchDetector::setup() {
  for (auto pin : fsrPins) {
    pinMode(pin, INPUT);
  }
  Serial.println("FSR Punch Detector Initialized.");
}

bool FSRPunchDetector::checkPunch() {
  const unsigned long debounceDelay = 200;  // ms between punches
  unsigned long now = millis();

  // Read all sensors and track the maximum reading
  int maxReading = 0;
  for (auto pin : fsrPins) {
    int mv = analogReadMilliVolts(pin);
    if (mv > maxReading) {
      maxReading = mv;
    }
  }
  fsrValue = maxReading;

  // If we detect a new hit above sensitivity
  if (maxReading > fsrSensitivity && !isPressed) {
    if (now - lastPunchTime > debounceDelay) {
      isPressed = true;
      lastPunchTime = now;
      return true;
    }
  }
  // Reset when reading drops below threshold
  else if (maxReading < fsrThreshold && isPressed) {
    isPressed = false;
  }

  return false;
}

String FSRPunchDetector::getPunchDetails(unsigned long elapsedMilliseconds) {
  String details = "";

  sensorVoltage = fsrValue / 1000.0;
  float R_FSR = 0.0;  // Optional: calculate resistance if needed

  calculateResults(fsrValue, R_FSR, elapsedMilliseconds, details);
  details = "Punch Count: " + String(punchCount) + " " + details;
  return details;
}

void FSRPunchDetector::calculateResults(int fsrSensorValue,
                                        float R_FSR,
                                        unsigned long punchTimestamp,
                                        String& outputMessage) {
  unsigned long minutes = punchTimestamp / 60000;
  unsigned long seconds = (punchTimestamp % 60000) / 1000;
  unsigned long hundredths = (punchTimestamp % 1000) / 10;

  char timestampFormatted[12];
  sprintf(timestampFormatted, "%02lu:%02lu:%02lu", minutes, seconds, hundredths);

  outputMessage += "Timestamp: " + String(timestampFormatted)
                   + " Device: " + DEVICE_NAME
                   + " | Sensor millivolts: " + String(fsrSensorValue);
}

float FSRPunchDetector::getSensorVoltage() {
  return sensorVoltage;
}

void FSRPunchDetector::setSensitivity(int value) {
  fsrSensitivity = value;
}

void FSRPunchDetector::setThreshold(int value) {
  fsrThreshold = value;
}

int FSRPunchDetector::getFsrValue() {
  return fsrValue;
}

int FSRPunchDetector::getSensitivity() {
  return fsrSensitivity;
}

int FSRPunchDetector::getThreshold() {
  return fsrThreshold;
}

void FSRPunchDetector::increasePunch() {
  punchCount++;
}

int FSRPunchDetector::getPunchCount() {
  return punchCount;
}

void FSRPunchDetector::resetPunchCount() {
  punchCount = 0;
}
