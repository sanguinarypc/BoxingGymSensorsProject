/**
 * @file BluetoothHandler.cpp
 * @author [Nick Dimitrakarakos / 83899]
 * @brief Υλοποίηση της κλάσης BluetoothHandler για τη διαχείριση της επικοινωνίας
 * Bluetooth Low Energy (BLE) σε μια συσκευή Arduino.
 * @version 1.0
 * @date 2025-05-14
 *
 * @copyright Copyright (c) 2025
 */

#include "BluetoothHandler.h"
#include <WiFi.h> // Περιλαμβάνεται για την εμφάνιση της IP στις συνδέσεις/αποσυνδέσεις BLE (για debugging/logging context).

// Αρχικοποίηση του στατικού δείκτη 'instance'.
// Αυτός ο δείκτης θα δείχνει στο μοναδικό αντικείμενο BluetoothHandler
// και χρησιμοποιείται από τις στατικές συναρτήσεις callback.
BluetoothHandler* BluetoothHandler::instance = nullptr;

/**
 * @brief Κατασκευαστής της κλάσης BluetoothHandler.
 * Αρχικοποιεί τα αντικείμενα υπηρεσίας και χαρακτηριστικών BLE,
 * καθώς και τις μεταβλητές μέλη της κλάσης.
 */
BluetoothHandler::BluetoothHandler()
  // Αρχικοποίηση της υπηρεσίας και των χαρακτηριστικών BLE μέσω της λίστας αρχικοποίησης μελών.
  // Ορίζονται τα UUIDs και οι ιδιότητες/δικαιώματα των χαρακτηριστικών.
  // Το '512' ορίζει το μέγιστο μέγεθος (σε bytes) του buffer για κάθε χαρακτηριστικό.
  // Αυτό μπορεί να προσαρμοστεί ανάλογα με τις ανάγκες της εφαρμογής για το μέγεθος των μηνυμάτων.
  : service(SERVICE_UUID),
    rxCharacteristic(CHARACTERISTIC_UUID_RX, BLEWrite | BLEWriteWithoutResponse, 512), // RX: επιτρέπει εγγραφή από client
    txCharacteristic(CHARACTERISTIC_UUID_TX, BLERead | BLENotify, 512)                  // TX: επιτρέπει ανάγνωση και ειδοποιήσεις προς client
{
  // Αρχικοποίηση των υπόλοιπων μεταβλητών μέλη.
  receivedMessage       = "";     // Το buffer για τα εισερχόμενα μηνύματα είναι αρχικά κενό.
  lastSentMessage       = "";     // Το τελευταίο απεσταλμένο μήνυμα είναι αρχικά κενό.
  duplicateMessageCount = 0;      // Ο μετρητής διπλότυπων μηνυμάτων αρχικοποιείται στο 0.
  connectionCount       = 0;      // Ο μετρητής ενεργών συνδέσεων αρχικοποιείται στο 0.
}

/**
 * @brief Αρχικοποιεί το BLE stack, ορίζει το όνομα της συσκευής,
 * προσθέτει την υπηρεσία και τα χαρακτηριστικά, και ξεκινά τη διαφήμιση (advertising).
 * @param deviceName Το όνομα με το οποίο η συσκευή θα διαφημίζεται μέσω BLE.
 */
void BluetoothHandler::begin(const char* deviceName) {
  // Ο στατικός δείκτης 'instance' τίθεται να δείχνει σε αυτό το αντικείμενο (this),
  // ώστε οι static callback συναρτήσεις να έχουν πρόσβαση στα μέλη της κλάσης.
  instance = this;
  _deviceName = deviceName; // Αποθήκευση του ονόματος της συσκευής.

  // Έναρξη της βιβλιοθήκης ArduinoBLE.
  if (!BLE.begin()) {
    Serial.println("Failed to initialize ArduinoBLE!");
    // Κρίσιμο σφάλμα: αν η αρχικοποίηση του BLE αποτύχει, η συσκευή σταματά την εκτέλεση.
    // Σε μια πιο ανθεκτική εφαρμογή, θα μπορούσε να γίνει προσπάθεια επανεκκίνησης ή
    // να ενεργοποιηθεί μια κατάσταση σφάλματος.
    while (1);
  }

  // Ορισμός του τοπικού ονόματος της συσκευής BLE.
  BLE.setLocalName(_deviceName);
  // Ορισμός της υπηρεσίας που θα διαφημίζεται.
  BLE.setAdvertisedService(service);

  // Προσθήκη των χαρακτηριστικών RX και TX στην προσαρμοσμένη υπηρεσία.
  service.addCharacteristic(rxCharacteristic);
  service.addCharacteristic(txCharacteristic);

  // Ορισμός του event handler για το χαρακτηριστικό RX.
  // Η συνάρτηση onRxWrite θα καλείται κάθε φορά που μια κεντρική συσκευή (client)
  // γράφει δεδομένα στο χαρακτηριστικό RX.
  rxCharacteristic.setEventHandler(BLEWritten, onRxWrite);

  // Προσθήκη της υπηρεσίας στο BLE stack.
  BLE.addService(service);
  // Έναρξη της διαφήμισης (advertising), ώστε άλλες συσκευές BLE να μπορούν να εντοπίσουν αυτή τη συσκευή.
  BLE.advertise();

  // Ορισμός των event handlers για τα γεγονότα σύνδεσης και αποσύνδεσης κεντρικών συσκευών.
  BLE.setEventHandler(BLEConnected, onCentralConnect);
  BLE.setEventHandler(BLEDisconnected, onCentralDisconnect);

  Serial.print("BLE stack initialized. Advertising as: ");
  Serial.println(_deviceName);
}

/**
 * @brief Επεξεργάζεται τα γεγονότα του BLE stack.
 * Πρέπει να καλείται συχνά μέσα στην κύρια συνάρτηση loop() του Arduino
 * για τη σωστή λειτουργία του BLE (π.χ. διαχείριση συνδέσεων, λήψη δεδομένων).
 */
void BluetoothHandler::poll() {
  BLE.poll();
}

/**
 * @brief Αποστέλλει ένα μήνυμα μέσω του χαρακτηριστικού TX.
 * Το μήνυμα αποστέλλεται σε όλες τις συνδεδεμένες κεντρικές συσκευές
 * που έχουν ενεργοποιήσει τις ειδοποιήσεις (notifications) για το TX χαρακτηριστικό.
 * @param message Η συμβολοσειρά (String) προς αποστολή.
 */
void BluetoothHandler::sendMessage(const String &message) {
  // Έλεγχος αν υπάρχει συνδεδεμένη κεντρική συσκευή.
  // Αν όχι, η αποστολή παραλείπεται για εξοικονόμηση πόρων.
  if (!isDeviceConnected()) {
    Serial.println("No BLE client connected. Message not sent.");
    return;
  }

  // Παράδειγμα λογικής για την παρακολούθηση διπλότυπων μηνυμάτων (κυρίως για debugging).
  // Αυτή η λογική μπορεί να αφαιρεθεί ή να τροποποιηθεί ανάλογα με τις απαιτήσεις.
  if (message == lastSentMessage) {
    duplicateMessageCount++;
  } else {
    duplicateMessageCount = 0; // Επαναφορά του μετρητή αν το μήνυμα είναι νέο.
  }
  lastSentMessage = message; // Αποθήκευση του τρέχοντος μηνύματος ως το τελευταίο απεσταλμένο.

  // Η μορφοποίηση του μηνύματος για να περιλαμβάνει τον αριθμό των διπλοτύπων είναι
  // σε σχόλια, καθώς μπορεί να μην είναι επιθυμητή στην τελική εφαρμογή.
  // String formattedMessage = message + " | Duplicates: " + String(duplicateMessageCount);
  String formattedMessage = message; // Χρήση του αρχικού μηνύματος.

  // Εγγραφή της τιμής (μηνύματος) στο χαρακτηριστικό TX.
  // Η κεντρική συσκευή θα λάβει αυτό το μήνυμα μέσω ειδοποίησης (notification).
  // Το μήνυμα μετατρέπεται σε πίνακα από bytes (uint8_t*).
  txCharacteristic.writeValue((const uint8_t*)formattedMessage.c_str(),
                              formattedMessage.length());

  Serial.println("BLE Sent: " + formattedMessage);
}

/**
 * @brief Ελέγχει αν υπάρχει τουλάχιστον μία κεντρική συσκευή συνδεδεμένη.
 * @return true Αν υπάρχει ενεργή σύνδεση BLE, false διαφορετικά.
 */
bool BluetoothHandler::isDeviceConnected() {
  // Η μέθοδος BLE.connected() της βιβλιοθήκης ArduinoBLE επιστρέφει την κατάσταση σύνδεσης.
  return BLE.connected();
}

/**
 * @brief Επιστρέφει το τελευταίο μήνυμα που λήφθηκε μέσω του χαρακτηριστικού RX.
 * @return String Το περιεχόμενο του τελευταίου ληφθέντος μηνύματος.
 */
String BluetoothHandler::readMessage() {
  return receivedMessage;
}

/**
 * @brief Καθαρίζει το buffer του τελευταίου ληφθέντος μηνύματος (receivedMessage).
 * Καλείται συνήθως μετά την επεξεργασία ενός μηνύματος για να επιτρέψει την αποθήκευση του επόμενου.
 */
void BluetoothHandler::clearMessage() {
  receivedMessage = "";
}

/**
 * @brief Στατική συνάρτηση callback. Καλείται όταν μια κεντρική συσκευή (client)
 * γράφει δεδομένα στο χαρακτηριστικό RX.
 * @param central Η κεντρική συσκευή (BLEDevice) που έγραψε τα δεδομένα.
 * @param characteristic Το χαρακτηριστικό (BLECharacteristic) στο οποίο έγινε η εγγραφή.
 */
void BluetoothHandler::onRxWrite(BLEDevice central, BLECharacteristic characteristic) {
  // Έλεγχος αν ο στατικός δείκτης 'instance' έχει αρχικοποιηθεί.
  if (instance) {
    // Λήψη των ανεπεξέργαστων δεδομένων (bytes) και του μήκους τους από το χαρακτηριστικό.
    const uint8_t* data = characteristic.value();
    unsigned int length = characteristic.valueLength(); // Χρήση unsigned int για το μήκος

    String incoming;
    incoming.reserve(length); // Προ-δέσμευση μνήμης για αποδοτικότητα
    // Μετατροπή των bytes σε Arduino String.
    for (unsigned int i = 0; i < length; i++) {
      incoming += (char)data[i];
    }
    incoming.trim(); // Αφαίρεση τυχόν κενών χαρακτήρων στην αρχή ή το τέλος.

    // Αποθήκευση του ληφθέντος μηνύματος στο μέλος 'receivedMessage' του αντικειμένου BluetoothHandler.
    instance->receivedMessage = incoming;

    Serial.print("BLE Received via RX from [");
    Serial.print(central.address()); // Εκτύπωση της διεύθυνσης MAC του client
    Serial.print("]: ");
    Serial.println(incoming);
  }
}

/**
 * @brief Στατική συνάρτηση callback. Καλείται όταν μια κεντρική συσκευή (client) συνδέεται
 * με αυτή τη συσκευή (server/peripheral).
 * @param central Η κεντρική συσκευή (BLEDevice) που συνδέθηκε.
 */
void BluetoothHandler::onCentralConnect(BLEDevice central) {
  if (!instance) return; // Έλεγχος αν ο δείκτης 'instance' είναι έγκυρος.

  instance->connectionCount++; // Αύξηση του μετρητή ενεργών συνδέσεων.

  // Εμφάνιση πληροφοριών σύνδεσης στη σειριακή οθόνη.
  // Η εμφάνιση της IP εδώ είναι για γενικότερο logging, καθώς η σύνδεση είναι BLE.
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Wi-Fi Connected! IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("Wi-Fi not connected.");
  }
  Serial.print("BLE Client [");
  Serial.print(central.address());
  Serial.print("] connected. Total connections: ");
  Serial.println(instance->connectionCount);
}

/**
 * @brief Στατική συνάρτηση callback. Καλείται όταν μια συνδεδεμένη κεντρική συσκευή (client)
 * αποσυνδέεται.
 * @param central Η κεντρική συσκευή (BLEDevice) που αποσυνδέθηκε.
 */
void BluetoothHandler::onCentralDisconnect(BLEDevice central) {
  if (!instance) return; // Έλεγχος αν ο δείκτης 'instance' είναι έγκυρος.

  // Μείωση του μετρητή ενεργών συνδέσεων, αν είναι μεγαλύτερος του μηδενός.
  if (instance->connectionCount > 0) {
    instance->connectionCount--;
  }

  // Εμφάνιση πληροφοριών αποσύνδεσης στη σειριακή οθόνη.
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Wi-Fi Status: Connected. IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("Wi-Fi Status: Not connected.");
  }
  Serial.print("BLE Client [");
  Serial.print(central.address());
  Serial.print("] disconnected. Remaining connections: ");
  Serial.println(instance->connectionCount);
}
