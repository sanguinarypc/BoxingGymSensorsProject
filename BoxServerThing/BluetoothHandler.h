/**
 * @file BluetoothHandler.h
 * @author [Nick Dimitrakarakos / 83899]
 * @brief Ορισμός της κλάσης BluetoothHandler για τη διαχείριση της επικοινωνίας
 * Bluetooth Low Energy (BLE) σε μια συσκευή Arduino.
 * Παρέχει λειτουργίες για τη δημιουργία ενός περιφερειακού BLE (server)
 * με μια προσαρμοσμένη υπηρεσία τύπου UART (Nordic UART Service - NUS compatible)
 * για αποστολή και λήψη δεδομένων.
 * @version 1.0 
 * @date 2025-05-14
 *
 * @copyright Copyright (c) 2025
 */

#ifndef BLUETOOTH_HANDLER_H
#define BLUETOOTH_HANDLER_H

#include <Arduino.h>      // Βασική βιβλιοθήκη Arduino.
#include <ArduinoBLE.h>   // Βιβλιοθήκη για τη λειτουργία Bluetooth Low Energy (BLE) της Arduino.

// --- Προσαρμοσμένα UUIDs για την υπηρεσία και τα χαρακτηριστικά BLE (Nordic UART Service - NUS) ---
// Αυτά τα συγκεκριμένα UUIDs είναι τα τυπικά για την υπηρεσία Nordic UART Service (NUS),
// η οποία επιτρέπει την αποστολή και λήψη συμβολοσειρών μέσω BLE, μιμούμενη μια σειριακή σύνδεση.
// Είναι σημαντικό τα ίδια UUIDs να χρησιμοποιούνται και από την κεντρική συσκευή (π.χ., κινητό τηλέφωνο)
// για την επικοινωνία.

/**
 * @brief UUID για την υπηρεσία Nordic UART Service (NUS).
 * Η υπηρεσία αυτή ομαδοποιεί τα χαρακτηριστικά RX και TX.
 */
#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"

/**
 * @brief UUID για το χαρακτηριστικό RX (Receive) της υπηρεσίας NUS.
 * Η κεντρική συσκευή (π.χ. κινητό) γράφει (WRITE) σε αυτό το χαρακτηριστικό για να στείλει δεδομένα στο Arduino.
 * Από την πλευρά του Arduino (peripheral), αυτό είναι το "receive" χαρακτηριστικό.
 * Ιδιότητες (Properties): WRITE, WRITE_WITHOUT_RESPONSE.
 */
#define CHARACTERISTIC_UUID_RX   "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

/**
 * @brief UUID για το χαρακτηριστικό TX (Transmit) της υπηρεσίας NUS.
 * Το Arduino (peripheral) γράφει σε αυτό το χαρακτηριστικό για να στείλει δεδομένα (μέσω NOTIFY) στην κεντρική συσκευή.
 * Από την πλευρά του Arduino, αυτό είναι το "transmit" χαρακτηριστικό.
 * Ιδιότητες (Properties): NOTIFY (και συνήθως READ).
 */
#define CHARACTERISTIC_UUID_TX   "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

/**
 * @class BluetoothHandler
 * @brief Διαχειρίζεται τη λειτουργικότητα του Bluetooth Low Energy (BLE) για τη συσκευή Arduino,
 * λειτουργώντας ως περιφερειακό (peripheral/server) με την υπηρεσία Nordic UART Service (NUS).
 *
 * Η κλάση αυτή αρχικοποιεί το BLE stack, δημιουργεί την υπηρεσία NUS
 * και τα αντίστοιχα χαρακτηριστικά RX/TX, διαχειρίζεται τις συνδέσεις
 * από κεντρικές συσκευές (centrals/clients), και επιτρέπει την αποστολή και λήψη μηνυμάτων.
 */
class BluetoothHandler {
public:
  /**
   * @brief Κατασκευαστής της κλάσης BluetoothHandler.
   * Αρχικοποιεί ορισμένες μεταβλητές μέλη στις προεπιλεγμένες τους τιμές.
   */
  BluetoothHandler();

  /**
   * @brief Αρχικοποιεί το BLE stack, ρυθμίζει την υπηρεσία NUS και τα χαρακτηριστικά της,
   * και ξεκινά τη διαφήμιση (advertising) της συσκευής.
   * @param deviceName Το όνομα με το οποίο η συσκευή θα εμφανίζεται στις σαρώσεις BLE από άλλες συσκευές.
   * Πρέπει να είναι μια C-style συμβολοσειρά (const char*).
   */
  void begin(const char* deviceName);

  /**
   * @brief Πρέπει να καλείται τακτικά (συνήθως σε κάθε επανάληψη της `loop()`)
   * για την επεξεργασία των γεγονότων του BLE stack.
   * Διαχειρίζεται τις συνδέσεις, τις αποσυνδέσεις, και τη λήψη δεδομένων.
   */
  void poll();

  /**
   * @brief Αποστέλλει ένα μήνυμα μέσω του χαρακτηριστικού TX της υπηρεσίας NUS.
   * Το μήνυμα θα σταλεί (μέσω NOTIFY) σε όλες τις συνδεδεμένες κεντρικές συσκευές
   * που έχουν ενεργοποιήσει τις ειδοποιήσεις (notifications) για το χαρακτηριστικό TX.
   * @param message Η συμβολοσειρά (Arduino String) που θα αποσταλεί.
   */
  void sendMessage(const String &message);

  /**
   * @brief Ελέγχει αν υπάρχει τουλάχιστον μία κεντρική συσκευή (central/client) συνδεδεμένη
   * με αυτή την περιφερειακή συσκευή (peripheral/server).
   * @return true Εάν τουλάχιστον μία κεντρική συσκευή είναι συνδεδεμένη, false διαφορετικά.
   */
  bool isDeviceConnected();

  /**
   * @brief Διαβάζει το τελευταίο πλήρες μήνυμα που έχει ληφθεί μέσω του χαρακτηριστικού RX.
   * Η μέθοδος αυτή επιστρέφει το μήνυμα που έχει αποθηκευτεί εσωτερικά από την callback `onRxWrite`.
   * @return String Το περιεχόμενο του τελευταίου ληφθέντος μηνύματος.
   * Επιστρέφει μια κενή συμβολοσειρά αν δεν υπάρχει νέο μήνυμα ή αν έχει ήδη καθαριστεί.
   */
  String readMessage();

  /**
   * @brief Καθαρίζει το buffer του τελευταίου ληφθέντος μηνύματος (receivedMessage).
   * Αυτό πρέπει να καλείται μετά την επεξεργασία ενός μηνύματος για να επιτρέψει
   * την ανίχνευση και αποθήκευση του επόμενου νέου μηνύματος.
   */
  void clearMessage();

private:
  // Αντικείμενα της βιβλιοθήκης ArduinoBLE για την υπηρεσία και τα χαρακτηριστικά.
  BLEService        service;          ///< Το αντικείμενο που αντιπροσωπεύει την υπηρεσία NUS.
  BLECharacteristic rxCharacteristic; ///< Το χαρακτηριστικό για τη λήψη δεδομένων (RX) από τον client.
  BLECharacteristic txCharacteristic; ///< Το χαρακτηριστικό για την αποστολή δεδομένων (TX) προς τον client.

  String receivedMessage;             ///< Buffer για την προσωρινή αποθήκευση του τρέχοντος εισερχόμενου μηνύματος από το RX.

  const char* _deviceName;            ///< Το όνομα της συσκευής BLE όπως διαφημίζεται. Αποθηκεύεται κατά την κλήση της `begin()`.

  // Οι παρακάτω μεταβλητές είναι για επίδειξη ή πιθανό debugging και μπορούν να αφαιρεθούν αν δεν είναι απαραίτητες.
  String lastSentMessage;             ///< Αποθηκεύει το τελευταίο μήνυμα που στάλθηκε (π.χ., για αποφυγή διπλοτύπων αποστολών).
  int duplicateMessageCount;          ///< Μετρητής για διπλότυπα μηνύματα που επιχειρήθηκε να σταλούν (για debugging).

  int connectionCount;                ///< Μετρητής για τον αριθμό των ενεργών συνδέσεων από κεντρικές συσκευές.

  /**
   * @brief Στατικός δείκτης στο μοναδικό αντικείμενο (instance) της κλάσης BluetoothHandler.
   * Απαιτείται ώστε οι στατικές συναρτήσεις callback του BLE API (όπως onRxWrite, onCentralConnect)
   * να μπορούν να έχουν πρόσβαση στα μη στατικά μέλη και μεθόδους της κλάσης.
   * Αυτό είναι ένα κοινό μοτίβο σχεδίασης (singleton-like access for callbacks) σε C++ για Arduino.
   */
  static BluetoothHandler* instance;

  // --- Στατικές Συναρτήσεις Callback για Γεγονότα BLE ---
  // Αυτές οι συναρτήσεις δηλώνονται ως static γιατί περνούν ως δείκτες συναρτήσεων
  // στο API της βιβλιοθήκης ArduinoBLE, το οποίο δεν μπορεί να χειριστεί απευθείας non-static member functions.

  /**
   * @brief Συνάρτηση callback που καλείται από το BLE stack όταν μια κεντρική συσκευή (client)
   * γράφει δεδομένα στο χαρακτηριστικό RX (`rxCharacteristic`).
   * @param central Η αντικείμενο BLEDevice που αντιπροσωπεύει την κεντρική συσκευή που έγραψε τα δεδομένα.
   * @param characteristic Το αντικείμενο BLECharacteristic στο οποίο έγινε η εγγραφή (θα πρέπει να είναι το `rxCharacteristic`).
   */
  static void onRxWrite(BLEDevice central, BLECharacteristic characteristic);

  /**
   * @brief Συνάρτηση callback που καλείται από το BLE stack όταν μια νέα κεντρική συσκευή (client)
   * συνδέεται επιτυχώς με αυτή την περιφερειακή συσκευή (server).
   * @param central Η αντικείμενο BLEDevice που αντιπροσωπεύει την κεντρική συσκευή που μόλις συνδέθηκε.
   */
  static void onCentralConnect(BLEDevice central);

  /**
   * @brief Συνάρτηση callback που καλείται από το BLE stack όταν μια συνδεδεμένη κεντρική συσκευή (client)
   * αποσυνδέεται.
   * @param central Η αντικείμενο BLEDevice που αντιπροσωπεύει την κεντρική συσκευή που μόλις αποσυνδέθηκε.
   */
  static void onCentralDisconnect(BLEDevice central);
};

#endif // BLUETOOTH_HANDLER_H
