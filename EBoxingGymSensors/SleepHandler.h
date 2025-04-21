// SleepHandler.h
#ifndef SLEEP_HANDLER_H
#define SLEEP_HANDLER_H

#include <Arduino.h>
#include "esp_sleep.h"

class SleepHandler {
public:
  SleepHandler();
  void enterLightSleep(bool enableBluetoothWake);  // void enterLightSleep();
  void enableTimerWakeUp(uint64_t timeInSeconds);
  void enableExtWakeUp(uint64_t gpioPinMask, esp_sleep_ext1_wakeup_mode_t mode);
  void enterDeepSleep();
  void wakeUpHandler();  // Handles actions after waking up
};

#endif  // SLEEP_HANDLER_H
