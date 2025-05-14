/**
 * @file BluetoothHandler.h
 * @author [Nick Dimitrakarakos / 83899]
 * @brief Ορισμός της κλάσης BluetoothHandler για τη διαχείριση της επικοινωνίας
 * Bluetooth Low Energy (BLE) σε μια συσκευή Arduino.
 * Παρέχει λειτουργίες για τη δημιουργία ενός περιφερειακού BLE (server)
 * με μια προσαρμοσμένη υπηρεσία τύπου UART για αποστολή και λήψη δεδομένων.
 * @version 1.0
 * @date [Ημερομηνία Τελευταίας Τροποποίησης, π.χ., 2025-05-14]
 *
 * @copyright Copyright (c) 2025
 */

#ifndef BLUETOOTH_HANDLER_H
#define BLUETOOTH_HANDLER_H

#include <Arduino.h>      // Βασική βιβλιοθήκη Arduino
#include <ArduinoBLE.h>   // Βιβλιοθήκη για τη λειτουργία Bluetooth Low Energy

// --- Προσαρμοσμένα UUIDs για την υπηρεσία και τα χαρακτηριστικά BLE ---
// Αυτά τα UUIDs ορίζουν μια προσαρμοσμένη υπηρεσία που μιμείται τη σειριακή επικοινωνία (UART).
// Μπορούν να δημιουργηθούν από online UUID generators.
// Είναι σημαντικό τα ίδια UUIDs να χρησιμοποιούνται και από την κεντρική συσκευή (π.χ., κινητό τηλέφωνο)
// για την επικοινωνία.

/**
 * @brief UUID για την προσαρμοσμένη υπηρεσία BLE (Nordic UART Service (NUS) compatible).
 * Η υπηρεσία αυτή ομαδοποιεί τα χαρακτηριστικά RX και TX.
 */
#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"

/**
 * @brief UUID για το χαρακτηριστικό RX (Receive).
 * Η κεντρική συσκευή (π.χ. κινητό) γράφει σε αυτό το χαρακτηριστικό για να στείλει δεδομένα στο Arduino.
 * Από την πλευρά του Arduino, αυτό είναι το "receive" χαρακτηριστικό.
 * Properties: WRITE, WRITE_WITHOUT_RESPONSE
 */
#define CHARACTERISTIC_UUID_RX   "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

/**
 * @brief UUID για το χαρακτηριστικό TX (Transmit).
 * Το Arduino γράφει σε αυτό το χαρακτηριστικό για να στείλει δεδομένα (μέσω NOTIFY) στην κεντρική συσκευή.
 * Από την πλευρά του Arduino, αυτό είναι το "transmit" χαρακτηριστικό.
 * Properties: NOTIFY
 */
#define CHARACTERISTIC_UUID_TX   "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

/**
 * @class BluetoothHandler
 * @brief Διαχειρίζεται τη λειτουργικότητα του Bluetooth Low Energy (BLE) για τη συσκευή.
 *
 * Η κλάση αυτή αρχικοποιεί το BLE stack, δημιουργεί μια προσαρμοσμένη υπηρεσία
 * και τα αντίστοιχα χαρακτηριστικά RX/TX (που μιμούνται τη λειτουργία UART),
 * διαχειρίζεται τις συνδέσεις από κεντρικές συσκευές (centrals),
 * και επιτρέπει την αποστολή και λήψη μηνυμάτων.
 */
class BluetoothHandler {
public:
  /**
   * @brief Κατασκευαστής της κλάσης BluetoothHandler.
   * Αρχικοποιεί ορισμένες μεταβλητές μέλη.
   */
  BluetoothHandler();

  /**
   * @brief Αρχικοποιεί το BLE stack και ξεκινά τη διαφήμιση (advertising).
   * @param deviceName Το όνομα με το οποίο η συσκευή θα εμφανίζεται στις σαρώσεις BLE.
   * Πρέπει να είναι μια C-style συμβολοσειρά (const char*).
   */
  void begin(const char* deviceName);

  /**
   * @brief Πρέπει να καλείται τακτικά μέσα στην κύρια συνάρτηση loop() του Arduino.
   * Διαχειρίζεται τα γεγονότα BLE, όπως νέες συνδέσεις ή εισερχόμενα δεδομένα.
   */
  void poll();

  /**
   * @brief Αποστέλλει ένα μήνυμα μέσω του χαρακτηριστικού TX.
   * Το μήνυμα θα σταλεί σε όλες τις συνδεδεμένες κεντρικές συσκευές που έχουν
   * ενεργοποιήσει τις ειδοποιήσεις (notifications) για το χαρακτηριστικό TX.
   * @param message Η συμβολοσειρά (String) που θα αποσταλεί.
   */
  void sendMessage(const String &message);

  /**
   * @brief Ελέγχει αν υπάρχει τουλάχιστον μία κεντρική συσκευή (central) συνδεδεμένη.
   * @return true Εάν τουλάχιστον μία κεντρική συσκευή είναι συνδεδεμένη, false διαφορετικά.
   */
  bool isDeviceConnected();

  /**
   * @brief Διαβάζει το τελευταίο πλήρες μήνυμα που έχει ληφθεί μέσω του χαρακτηριστικού RX.
   * Μετά την ανάγνωση, το εσωτερικό buffer του μηνύματος συνήθως καθαρίζεται
   * (αν και εδώ η clearMessage() καλείται ξεχωριστά).
   * @return String Το περιεχόμενο του τελευταίου ληφθέντος μηνύματος.
   * Επιστρέφει κενή συμβολοσειρά αν δεν υπάρχει νέο μήνυμα.
   */
  String readMessage();

  /**
   * @brief Καθαρίζει το buffer του τελευταίου ληφθέντος μηνύματος.
   * Καλείται συνήθως μετά την επεξεργασία ενός μηνύματος για να επιτρέψει
   * τη λήψη του επόμενου.
   */
  void clearMessage();

private:
  // Αντικείμενα της βιβλιοθήκης ArduinoBLE για την υπηρεσία και τα χαρακτηριστικά.
  BLEService        service;          ///< Η προσαρμοσμένη υπηρεσία BLE.
  BLECharacteristic rxCharacteristic; ///< Το χαρακτηριστικό για τη λήψη δεδομένων (RX).
  BLECharacteristic txCharacteristic; ///< Το χαρακτηριστικό για την αποστολή δεδομένων (TX).

  String receivedMessage;             ///< Buffer για την αποθήκευση του τρέχοντος εισερχόμενου μηνύματος από το RX.

  const char* _deviceName;            ///< Το όνομα της συσκευής BLE όπως διαφημίζεται.

  // Μεταβλητές για παρακολούθηση και επίδειξη (μπορούν να αφαιρεθούν αν δεν χρειάζονται στην τελική έκδοση).
  String lastSentMessage;             ///< Αποθηκεύει το τελευταίο μήνυμα που στάλθηκε (για αποφυγή διπλοτύπων, αν χρειάζεται).
  int duplicateMessageCount;          ///< Μετρητής για διπλότυπα μηνύματα (για debugging ή ειδική λογική).

  int connectionCount;                ///< Μετρητής για τον αριθμό των ενεργών συνδέσεων από κεντρικές συσκευές.

  /**
   * @brief Στατικός δείκτης στο τρέχον αντικείμενο BluetoothHandler.
   * Απαιτείται ώστε οι στατικές συναρτήσεις callback του BLE API
   * να μπορούν να έχουν πρόσβαση στα μη στατικά μέλη της κλάσης.
   */
  static BluetoothHandler* instance;

  // --- Στατικές Συναρτήσεις Callback για Γεγονότα BLE ---
  // Αυτές οι συναρτήσεις καλούνται από το BLE stack όταν συμβαίνουν συγκεκριμένα γεγονότα.

  /**
   * @brief Συνάρτηση callback που καλείται όταν μια κεντρική συσκευή γράφει
   * δεδομένα στο χαρακτηριστικό RX.
   * @param central Η κεντρική συσκευή (BLEDevice) που έγραψε τα δεδομένα.
   * @param characteristic Το χαρακτηριστικό (BLECharacteristic) στο οποίο έγινε η εγγραφή (θα πρέπει να είναι το rxCharacteristic).
   */
  static void onRxWrite(BLEDevice central, BLECharacteristic characteristic);

  /**
   * @brief Συνάρτηση callback που καλείται όταν μια νέα κεντρική συσκευή συνδέεται.
   * @param central Η κεντρική συσκευή (BLEDevice) που συνδέθηκε.
   */
  static void onCentralConnect(BLEDevice central);

  /**
   * @brief Συνάρτηση callback που καλείται όταν μια κεντρική συσκευή αποσυνδέεται.
   * @param central Η κεντρική συσκευή (BLEDevice) που αποσυνδέθηκε.
   */
  static void onCentralDisconnect(BLEDevice central);
};

#endif // BLUETOOTH_HANDLER_H

