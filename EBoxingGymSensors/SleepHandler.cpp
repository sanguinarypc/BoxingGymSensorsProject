// SleepHandler.cpp
#include "SleepHandler.h"

SleepHandler::SleepHandler() {
    Serial.println("SleepHandler initialized.");
}

// void SleepHandler::enterLightSleep(bool enableBluetoothWake) {
//     Serial.println("Preparing to enter light sleep... Bluetooth remains active.");

//     // Enable wake-up sources
//     if (enableBluetoothWake) {
//         esp_sleep_enable_uart_wakeup(0);  // Allow Bluetooth UART to wake the ESP32
//         Serial.println("Bluetooth wake-up enabled.");
//     }

//     // Ensure Bluetooth stays connected
//     Serial.println("Delaying to allow Bluetooth tasks to complete...");
//     delay(100);  // Ensure BLE stack finishes any pending tasks

//     // Enter light sleep mode
//     Serial.println("Entering light sleep now...");
//     delay(100);  // Ensure messages are printed before sleep
//     esp_light_sleep_start();
    
//     Serial.println("Woke up from light sleep.");  // Code continues executing after wake-up
// }


void SleepHandler::enterLightSleep(bool enableBluetoothWake) {
    Serial.println("Preparing to enter light sleep... Bluetooth remains active.");

    if (enableBluetoothWake) {
        esp_sleep_enable_uart_wakeup(UART_NUM_0);  // Enable wake-up from Bluetooth UART
        Serial.println("Bluetooth wake-up enabled via UART.");
    }

    delay(100); // Ensure Serial prints complete before sleep
    Serial.println("Entering light sleep now...");
    esp_light_sleep_start();  // Enter light sleep mode
    
    Serial.println("Woke up from light sleep.");  // Code resumes here after wake-up
}







void SleepHandler::enableTimerWakeUp(uint64_t timeInSeconds) {
    esp_sleep_enable_timer_wakeup(timeInSeconds * 1000000ULL);
    Serial.println("Timer wake-up enabled for " + String(timeInSeconds) + " seconds.");
}

void SleepHandler::enableExtWakeUp(uint64_t gpioPinMask, esp_sleep_ext1_wakeup_mode_t mode) {
    esp_sleep_enable_ext1_wakeup(gpioPinMask, mode);
    Serial.println("External wake-up enabled on GPIO Mask: " + String(gpioPinMask));
}

void SleepHandler::enterDeepSleep() {
    Serial.println("Entering deep sleep...");
    delay(100); // Ensure messages are printed before sleep
    esp_deep_sleep_start();
}

// void SleepHandler::wakeUpHandler() {
//     esp_sleep_wakeup_cause_t wakeup_reason = esp_sleep_get_wakeup_cause();
//     switch (wakeup_reason) {
//         case ESP_SLEEP_WAKEUP_TIMER:
//             Serial.println("Woke up due to timer.");
//             break;
//         case ESP_SLEEP_WAKEUP_EXT1:
//             Serial.println("Woke up due to external signal (EXT1).");
//             break;
//         default:
//             Serial.println("Woke up due to unknown reason.");
//             break;
//     }
// }

void SleepHandler::wakeUpHandler() {
    esp_sleep_wakeup_cause_t wakeup_reason = esp_sleep_get_wakeup_cause();
    
    Serial.print("ESP32 woke up due to: ");
    switch (wakeup_reason) {
        case ESP_SLEEP_WAKEUP_TIMER:
            Serial.println("Timer Wake-up.");
            break;
        case ESP_SLEEP_WAKEUP_EXT1:
            Serial.println("External GPIO Wake-up.");
            break;
        case ESP_SLEEP_WAKEUP_UART:
            Serial.println("Bluetooth (UART) Wake-up.");
            break;
        default:
            Serial.println("Unknown reason (possibly manual reset).");
            break;
    }
}
