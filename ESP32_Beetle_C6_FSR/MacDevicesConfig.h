#ifndef MAC_DEVICES_CONFIG_H
#define MAC_DEVICES_CONFIG_H

#include <Arduino.h>

// Array of MAC addresses for BlueBoxer
static const String BLUEBOXER_MACS[] = {
  "f0:f5:bd:2c:10:72",
  "f0:f5:bd:2c:1a:32",
  "f0:f5:bd:2c:0b:ee",
  "f0:f5:bd:2c:16:3a",
  "54:32:04:3f:e8:8e"

};
static const int NUM_BLUEBOXER_MACS = sizeof(BLUEBOXER_MACS) / sizeof(BLUEBOXER_MACS[0]);

// Array of MAC addresses for RedBoxer
static const String REDBOXER_MACS[] = {
  "f0:f5:bd:2c:15:1a",
  "f0:f5:bd:2c:11:e6",
  "54:32:04:3f:da:ee"
};
static const int NUM_REDBOXER_MACS = sizeof(REDBOXER_MACS) / sizeof(REDBOXER_MACS[0]);

#endif
