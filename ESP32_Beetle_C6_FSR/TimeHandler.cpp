#include "TimeHandler.h"

// Constructor
TimeHandler::TimeHandler()
  : startCountTime(0), elapsedTime(0), isRunning(false), pausedTime(0), resumedTime(0) {}

// Start the timer (or resume from where it was paused)
void TimeHandler::start() {
  if (!isRunning) {
    startCountTime = millis() - elapsedTime;  // Adjust to resume if paused
    isRunning = true;
  }
}

// Pause the timer
void TimeHandler::pause() {
  if (isRunning) {
    elapsedTime = millis() - startCountTime;  // Record the elapsed time
    pausedTime = elapsedTime / 1000;          // Record paused time in seconds
    isRunning = false;
  }
}

// Resume the timer
void TimeHandler::resume() {
  if (!isRunning) {
    startCountTime = millis() - elapsedTime;  // Adjust to resume from where paused
    resumedTime = elapsedTime / 1000;         // Record resumed time in seconds
    isRunning = true;
  }
}

// Reset the timer (elapsed time set to 0, timer stopped)
void TimeHandler::reset() {
  startCountTime = 0;
  elapsedTime = 0;
  pausedTime = 0;
  resumedTime = 0;
  isRunning = false;
}

// Restart the timer (reset and start from 0)
void TimeHandler::restart() {
  reset();                    // Reset all values
  startCountTime = millis();  // Start counting from current time
  isRunning = true;
}

// Get elapsed time in milliseconds
unsigned long TimeHandler::getElapsedMilliseconds() {
  if (isRunning) {
    return millis() - startCountTime;  // Time since the timer started
  } else {
    return elapsedTime;  // Return paused elapsed time
  }
}

// Get elapsed time in seconds
unsigned long TimeHandler::getElapsedSeconds() {
  return getElapsedMilliseconds() / 1000;
}

// Get time when paused
unsigned long TimeHandler::getPausedTime() {
  return pausedTime;
}

// Get time when resumed
unsigned long TimeHandler::getResumedTime() {
  return resumedTime;
}

// Get time since the timer was started
unsigned long TimeHandler::getTimeSinceStart() {
  return getElapsedMilliseconds();  // Same as elapsed time when running
}
