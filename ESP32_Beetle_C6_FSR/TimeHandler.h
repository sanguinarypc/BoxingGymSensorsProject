#ifndef TIME_HANDLER_H
#define TIME_HANDLER_H

#include <Arduino.h>

class TimeHandler {
private:
  unsigned long startCountTime;
  unsigned long elapsedTime;
  bool isRunning;

  unsigned long pausedTime;
  unsigned long resumedTime;

public:
  TimeHandler();
  void start();
  void pause();
  void reset();
  void resume();
  void restart();  // New method to reset and start the timer

  unsigned long getElapsedMilliseconds();
  unsigned long getElapsedSeconds();
  unsigned long getPausedTime();
  unsigned long getResumedTime();
  unsigned long getTimeSinceStart();  // New method to get time since start
};

#endif  // TIME_HANDLER_H
