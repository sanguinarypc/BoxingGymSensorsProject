#include "FSRPunchDetector.h"

// Declare that DEVICE_NAME is defined in another file (boxingApp.cpp)
extern String DEVICE_NAME;

FSRPunchDetector::FSRPunchDetector(int fsrPin, int threshold)
  : fsrPin(fsrPin), fsrThreshold(threshold), isPressed(false), punchCount(0) {}

float sensorVoltage;
int fsrValue;
unsigned long lastPunchTime = 0;  // Track the time of the last punch

void FSRPunchDetector::setup() {
  pinMode(fsrPin, INPUT);
  Serial.println("FSR Punch Detector Initialized.");
}

bool FSRPunchDetector::checkPunch() {
  const unsigned long debounceDelay = 200;  // Minimum time (in milliseconds) between punches
  fsrValue = analogReadMilliVolts(fsrPin);  // Read FSR value in millivolts
  // Serial.println("Sensor reading: " + String(fsrValue));

  // Check if the sensor value exceeds the threshold and the debounce period has passed
  if (fsrValue > fsrSensitivity && !isPressed) {
    unsigned long currentTime = millis();  // Get the current time

    if (currentTime - lastPunchTime > debounceDelay) {
      isPressed = true;             // Set flag to indicate the sensor is pressed
      lastPunchTime = currentTime;  // Update the last punch time

      return true;  // Punch detected
    }
  } else if (fsrValue < fsrThreshold) {
  // }else if (fsrValue < (fsrSensitivity - 200)) {  // For fsrSensitivity of 800, reset below 600 mV  (fsrValue < (fsrSensitivity * 0.75))
    // Reset flag when the sensor value drops below a low threshold
    isPressed = false;
  }

  return false;  // No punch detected
}


String FSRPunchDetector::getPunchDetails(unsigned long elapsedMilliseconds) {
  String details = "";

  sensorVoltage = fsrValue / 1000.0;
  float R_FSR = 0.0;  // Optional: Calculate resistance here if needed

  calculateResults(fsrValue, R_FSR, elapsedMilliseconds, details);
  // details = "Punch Count: " + String(punchCount) + "\n" + details;   < -------------------------------------------
  details = "Punch Count: " + String(punchCount) + " " + details;
  return details;
}

void FSRPunchDetector::calculateResults(int fsrSensorValue, float R_FSR, unsigned long punchTimestamp, String &outputMessage) {
  // Convert time to minutes:seconds:hundredths of a second
  unsigned long minutes = punchTimestamp / 60000;
  unsigned long seconds = (punchTimestamp % 60000) / 1000;
  unsigned long hundredths = (punchTimestamp % 1000) / 10;

  // Format the timestamp
  char timestampFormatted[12];
  sprintf(timestampFormatted, "%02lu:%02lu:%02lu", minutes, seconds, hundredths);

  // Append the details to the output message
  // outputMessage += "Timestamp: " + String(timestampFormatted) + " | Sensor millivolts: " + String(fsrSensorValue);
  outputMessage += "Timestamp: " + String(timestampFormatted) + " Device: " + String(DEVICE_NAME) + " | Sensor millivolts: " + String(fsrSensorValue);
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
