/**
 * @file BluetoothHandler.cpp
 * @author [Nick Dimitrakarakos / 83899]
 * @brief Υλοποίηση της κλάσης BluetoothHandler για τη διαχείριση της επικοινωνίας
 * Bluetooth Low Energy (BLE) σε μια συσκευή Arduino, χρησιμοποιώντας την υπηρεσία Nordic UART Service (NUS).
 * @version 1.0 
 * @date 2025-05-14
 *
 * @copyright Copyright (c) 2025
 */

#include "BluetoothHandler.h" // Ορισμός της κλάσης BluetoothHandler.
#include <WiFi.h>             // Περιλαμβάνεται για την εμφάνιση της IP διεύθυνσης στα μηνύματα σύνδεσης/αποσύνδεσης BLE.
                              // Αυτό μπορεί να είναι χρήσιμο για debugging, για να υπάρχει γενικότερο πλαίσιο της κατάστασης του δικτύου.

// Αρχικοποίηση του στατικού δείκτη 'instance'.
// Αυτός ο δείκτης θα δείχνει στο μοναδικό αντικείμενο (instance) της κλάσης BluetoothHandler.
// Χρησιμοποιείται από τις στατικές συναρτήσεις callback (onRxWrite, onCentralConnect, onCentralDisconnect)
// για να έχουν πρόσβαση στα μη στατικά μέλη και μεθόδους του αντικειμένου.
BluetoothHandler* BluetoothHandler::instance = nullptr;

/**
 * @brief Κατασκευαστής της κλάσης BluetoothHandler.
 * Αρχικοποιεί τα αντικείμενα της υπηρεσίας BLE (NUS) και των χαρακτηριστικών της (RX, TX),
 * καθώς και τις μεταβλητές μέλη της κλάσης στις προεπιλεγμένες τους τιμές.
 */
BluetoothHandler::BluetoothHandler()
  // Λίστα αρχικοποίησης μελών (Member Initializer List):
  // Αρχικοποιεί την υπηρεσία 'service' με το SERVICE_UUID.
  // Αρχικοποιεί το 'rxCharacteristic' με το CHARACTERISTIC_UUID_RX,
  // ορίζοντας τις ιδιότητες BLEWrite (επιτρέπει εγγραφή από client) και
  // BLEWriteWithoutResponse (επιτρέπει εγγραφή χωρίς απόκριση από το peripheral).
  // Το '512' ορίζει το μέγιστο μέγεθος (σε bytes) του buffer για αυτό το χαρακτηριστικό.
  : service(SERVICE_UUID),
    rxCharacteristic(CHARACTERISTIC_UUID_RX, BLEWrite | BLEWriteWithoutResponse, 512),
  // Αρχικοποιεί το 'txCharacteristic' με το CHARACTERISTIC_UUID_TX,
  // ορίζοντας τις ιδιότητες BLERead (επιτρέπει ανάγνωση από client) και
  // BLENotify (επιτρέπει την αποστολή ειδοποιήσεων στον client όταν η τιμή αλλάζει).
  // Το '512' ορίζει το μέγιστο μέγεθος του buffer.
    txCharacteristic(CHARACTERISTIC_UUID_TX, BLERead | BLENotify, 512)
{
  // Αρχικοποίηση των υπόλοιπων μεταβλητών μέλη.
  receivedMessage       = "";     // Το buffer για τα εισερχόμενα μηνύματα είναι αρχικά κενό.
  lastSentMessage       = "";     // Το τελευταίο απεσταλμένο μήνυμα (για έλεγχο διπλοτύπων) είναι αρχικά κενό.
  duplicateMessageCount = 0;      // Ο μετρητής διπλότυπων απεσταλμένων μηνυμάτων αρχικοποιείται στο 0.
  connectionCount       = 0;      // Ο μετρητής ενεργών συνδέσεων από κεντρικές συσκευές αρχικοποιείται στο 0.
}

/**
 * @brief Αρχικοποιεί το BLE stack, ρυθμίζει την υπηρεσία NUS και τα χαρακτηριστικά της,
 * ορίζει το όνομα της συσκευής, προσθέτει τις απαραίτητες συναρτήσεις callback για γεγονότα,
 * και ξεκινά τη διαφήμιση (advertising) της συσκευής ώστε να είναι ανιχνεύσιμη.
 * @param deviceName Το όνομα (C-style string) με το οποίο η συσκευή θα διαφημίζεται μέσω BLE.
 */
void BluetoothHandler::begin(const char* deviceName) {
  // Ο στατικός δείκτης 'instance' τίθεται να δείχνει σε αυτό το τρέχον αντικείμενο (this).
  // Αυτό επιτρέπει στις static callback συναρτήσεις να έχουν πρόσβαση στα μέλη και τις μεθόδους της κλάσης.
  instance = this;
  _deviceName = deviceName; // Αποθήκευση του ονόματος της συσκευής.

  // Έναρξη της βιβλιοθήκης ArduinoBLE.
  if (!BLE.begin()) {
    Serial.println(F("[BLE Handler] Failed to initialize ArduinoBLE library!"));
    // Κρίσιμο σφάλμα: αν η αρχικοποίηση του BLE αποτύχει, η συσκευή εισέρχεται σε ατέρμονα βρόχο.
    // Σε μια πιο ανθεκτική εφαρμογή, θα μπορούσε να γίνει προσπάθεια επανεκκίνησης,
    // να ενεργοποιηθεί μια κατάσταση σφάλματος (π.χ., LED), ή να συνεχίσει χωρίς BLE αν είναι δυνατό.
    while (1);
  }

  // Ορισμός του τοπικού ονόματος της συσκευής BLE (αυτό που φαίνεται στις σαρώσεις).
  BLE.setLocalName(_deviceName);
  // Ορισμός της υπηρεσίας που θα διαφημίζεται (η υπηρεσία NUS).
  BLE.setAdvertisedService(service);

  // Προσθήκη των χαρακτηριστικών RX και TX στην προσαρμοσμένη υπηρεσία NUS.
  service.addCharacteristic(rxCharacteristic);
  service.addCharacteristic(txCharacteristic);

  // Ορισμός της συνάρτησης callback (event handler) για το χαρακτηριστικό RX.
  // Η συνάρτηση `onRxWrite` θα καλείται αυτόματα κάθε φορά που μια κεντρική συσκευή (client)
  // γράφει δεδομένα στο χαρακτηριστικό RX.
  rxCharacteristic.setEventHandler(BLEWritten, onRxWrite);

  // Προσθήκη της υπηρεσίας NUS στο BLE stack της συσκευής.
  BLE.addService(service);
  // Έναρξη της διαφήμισης (advertising). Η συσκευή γίνεται ανιχνεύσιμη από άλλες BLE συσκευές.
  BLE.advertise();

  // Ορισμός των συναρτήσεων callback (event handlers) για τα γεγονότα σύνδεσης και αποσύνδεσης κεντρικών συσκευών.
  BLE.setEventHandler(BLEConnected, onCentralConnect);
  BLE.setEventHandler(BLEDisconnected, onCentralDisconnect);

  Serial.print(F("[BLE Handler] BLE stack initialized. Advertising as: "));
  Serial.println(_deviceName);
}

/**
 * @brief Επεξεργάζεται τα εισερχόμενα γεγονότα και τις εργασίες του BLE stack.
 * Αυτή η συνάρτηση πρέπει να καλείται συχνά και τακτικά μέσα στην κύρια συνάρτηση `loop()`
 * του Arduino σκίτσου για τη σωστή λειτουργία του BLE (π.χ., διαχείριση συνδέσεων,
 * λήψη δεδομένων, αποστολή ειδοποιήσεων).
 */
void BluetoothHandler::poll() {
  // Καλεί την αντίστοιχη `poll()` της βιβλιοθήκης ArduinoBLE.
  BLE.poll();
}

/**
 * @brief Αποστέλλει ένα μήνυμα (String) μέσω του χαρακτηριστικού TX της υπηρεσίας NUS.
 * Το μήνυμα αποστέλλεται σε όλες τις συνδεδεμένες κεντρικές συσκευές (clients)
 * που έχουν ενεργοποιήσει τις ειδοποιήσεις (notifications) για το TX χαρακτηριστικό.
 * @param message Η συμβολοσειρά (Arduino String) προς αποστολή.
 */
void BluetoothHandler::sendMessage(const String &message) {
  // Έλεγχος αν υπάρχει τουλάχιστον μία συνδεδεμένη κεντρική συσκευή.
  // Αν όχι, η αποστολή παραλείπεται για εξοικονόμηση πόρων και αποφυγή σφαλμάτων.
  if (!isDeviceConnected()) {
    // Serial.println(F("[BLE Handler] No BLE client connected. Message not sent.")); // Προαιρετικό μήνυμα
    return;
  }

  // Παράδειγμα λογικής για την παρακολούθηση διπλότυπων μηνυμάτων (κυρίως για debugging ή ειδικές περιπτώσεις).
  // Αυτή η λογική μπορεί να αφαιρεθεί ή να τροποποιηθεί ανάλογα με τις απαιτήσεις της εφαρμογής.
  if (message == lastSentMessage) {
    duplicateMessageCount++;
  } else {
    duplicateMessageCount = 0; // Επαναφορά του μετρητή αν το μήνυμα είναι νέο.
  }
  lastSentMessage = message; // Αποθήκευση του τρέχοντος μηνύματος ως το τελευταίο απεσταλμένο.

  // Η μορφοποίηση του μηνύματος για να περιλαμβάνει τον αριθμό των διπλοτύπων είναι
  // σε σχόλια, καθώς μπορεί να μην είναι επιθυμητή στην τελική εφαρμογή.
  // String formattedMessage = message + " | Duplicates: " + String(duplicateMessageCount);
  String formattedMessage = message; // Χρήση του αρχικού μηνύματος για αποστολή.

  // Εγγραφή της τιμής (μηνύματος) στο χαρακτηριστικό TX.
  // Η κεντρική συσκευή θα λάβει αυτό το μήνυμα μέσω ειδοποίησης (notification) αν την έχει ενεργοποιήσει.
  // Το μήνυμα μετατρέπεται σε πίνακα από bytes (const uint8_t*) χρησιμοποιώντας τη μέθοδο c_str() του String.
  txCharacteristic.writeValue((const uint8_t*)formattedMessage.c_str(),
                              formattedMessage.length());

  Serial.print(F("[BLE Handler] Sent TX: "));
  Serial.println(formattedMessage);
}

/**
 * @brief Ελέγχει αν υπάρχει τουλάχιστον μία ενεργή σύνδεση BLE με κεντρική συσκευή.
 * @return true Αν υπάρχει τουλάχιστον μία συνδεδεμένη κεντρική συσκευή, false διαφορετικά.
 */
bool BluetoothHandler::isDeviceConnected() {
  // Η μέθοδος `BLE.connected()` της βιβλιοθήκης ArduinoBLE επιστρέφει `true`
  // αν υπάρχει τουλάχιστον μία ενεργή σύνδεση, και `false` διαφορετικά.
  return BLE.connected();
}

/**
 * @brief Επιστρέφει το τελευταίο πλήρες μήνυμα που λήφθηκε μέσω του χαρακτηριστικού RX
 * και αποθηκεύτηκε στην εσωτερική μεταβλητή `receivedMessage`.
 * @return String Το περιεχόμενο του τελευταίου ληφθέντος μηνύματος.
 * Επιστρέφει κενή συμβολοσειρά αν δεν έχει ληφθεί νέο μήνυμα ή αν έχει καθαριστεί.
 */
String BluetoothHandler::readMessage() {
  return receivedMessage;
}

/**
 * @brief Καθαρίζει (κάνει κενή) την εσωτερική μεταβλητή `receivedMessage` που αποθηκεύει
 * το τελευταίο ληφθέν μήνυμα.
 * Αυτό πρέπει να καλείται από τον κώδικα της εφαρμογής μετά την επεξεργασία ενός μηνύματος,
 * ώστε να είναι δυνατή η ανίχνευση και αποθήκευση του επόμενου νέου μηνύματος.
 */
void BluetoothHandler::clearMessage() {
  receivedMessage = "";
}

/**
 * @brief Στατική συνάρτηση callback. Καλείται αυτόματα από το BLE stack όταν μια κεντρική συσκευή (client)
 * γράφει δεδομένα στο χαρακτηριστικό RX (`rxCharacteristic`) αυτής της περιφερειακής συσκευής.
 * @param central Η αντικείμενο BLEDevice που αντιπροσωπεύει την κεντρική συσκευή που έγραψε τα δεδομένα.
 * @param characteristic Το αντικείμενο BLECharacteristic στο οποίο έγινε η εγγραφή (αναμένεται να είναι το `rxCharacteristic`).
 */
void BluetoothHandler::onRxWrite(BLEDevice central, BLECharacteristic characteristic) {
  // Έλεγχος αν ο στατικός δείκτης 'instance' έχει αρχικοποιηθεί (δείχνει σε ένα έγκυρο αντικείμενο BluetoothHandler).
  if (instance) {
    // Λήψη των ανεπεξέργαστων δεδομένων (raw bytes) και του μήκους τους από το χαρακτηριστικό.
    const uint8_t* data = characteristic.value();
    unsigned int length = characteristic.valueLength(); // Χρήση unsigned int για το μήκος για συμβατότητα.

    String incoming; // Δημιουργία ενός Arduino String για την αποθήκευση του μηνύματος.
    incoming.reserve(length); // Προ-δέσμευση μνήμης για το String για πιθανή βελτίωση απόδοσης.

    // Μετατροπή των bytes σε Arduino String.
    for (unsigned int i = 0; i < length; i++) {
      incoming += (char)data[i];
    }
    incoming.trim(); // Αφαίρεση τυχόν κενών χαρακτήρων (whitespace) από την αρχή ή το τέλος του μηνύματος.

    // Αποθήκευση του ληφθέντος και επεξεργασμένου μηνύματος στο μέλος 'receivedMessage'
    // του αντικειμένου BluetoothHandler, μέσω του στατικού δείκτη 'instance'.
    instance->receivedMessage = incoming;

    Serial.print(F("[BLE Handler] Received RX from ["));
    Serial.print(central.address()); // Εκτύπωση της διεύθυνσης MAC της κεντρικής συσκευής για debugging.
    Serial.print(F("]: "));
    Serial.println(incoming);
  }
}

/**
 * @brief Στατική συνάρτηση callback. Καλείται αυτόματα από το BLE stack όταν μια νέα κεντρική συσκευή (client)
 * συνδέεται επιτυχώς με αυτή την περιφερειακή συσκευή (server).
 * @param central Η αντικείμενο BLEDevice που αντιπροσωπεύει την κεντρική συσκευή που μόλις συνδέθηκε.
 */
void BluetoothHandler::onCentralConnect(BLEDevice central) {
  if (!instance) return; // Έλεγχος αν ο δείκτης 'instance' είναι έγκυρος.

  instance->connectionCount++; // Αύξηση του μετρητή ενεργών συνδέσεων.

  // Εμφάνιση πληροφοριών σύνδεσης στη σειριακή οθόνη.
  // Η εμφάνιση της IP εδώ είναι για γενικότερο logging context, καθώς η σύνδεση είναι BLE.
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print(F("[BLE Handler] Wi-Fi Connected. IP: "));
    Serial.println(WiFi.localIP());
  } else {
    Serial.println(F("[BLE Handler] Wi-Fi not connected."));
  }
  Serial.print(F("[BLE Handler] Client ["));
  Serial.print(central.address()); // Εκτύπωση της διεύθυνσης MAC του client.
  Serial.print(F("] connected. Total connections: "));
  Serial.println(instance->connectionCount);
}

/**
 * @brief Στατική συνάρτηση callback. Καλείται αυτόματα από το BLE stack όταν μια συνδεδεμένη
 * κεντρική συσκευή (client) αποσυνδέεται από αυτή την περιφερειακή συσκευή.
 * @param central Η αντικείμενο BLEDevice που αντιπροσωπεύει την κεντρική συσκευή που μόλις αποσυνδέθηκε.
 */
void BluetoothHandler::onCentralDisconnect(BLEDevice central) {
  if (!instance) return; // Έλεγχος αν ο δείκτης 'instance' είναι έγκυρος.

  // Μείωση του μετρητή ενεργών συνδέσεων, διασφαλίζοντας ότι δεν γίνεται αρνητικός.
  if (instance->connectionCount > 0) {
    instance->connectionCount--;
  }

  // Εμφάνιση πληροφοριών αποσύνδεσης στη σειριακή οθόνη.
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print(F("[BLE Handler] Wi-Fi Status: Connected. IP: "));
    Serial.println(WiFi.localIP());
  } else {
    Serial.println(F("[BLE Handler] Wi-Fi Status: Not connected."));
  }
  Serial.print(F("[BLE Handler] Client ["));
  Serial.print(central.address()); // Εκτύπωση της διεύθυνσης MAC του client.
  Serial.print(F("] disconnected. Remaining connections: "));
  Serial.println(instance->connectionCount);
}
