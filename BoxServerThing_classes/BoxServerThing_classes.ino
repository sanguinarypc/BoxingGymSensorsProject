/**
 * @file BoxServerThing_classes.ino 
 * @author [Nick Dimitrakarakos / 83899]
 * @brief Κύριο αρχείο για το Arduino project που διαχειρίζεται τη σύνδεση με το Arduino IoT Cloud,
 * επικοινωνία μέσω Bluetooth Low Energy (BLE) για λήψη δεδομένων σε μορφή JSON,
 * και συγχρονισμό ώρας με το cloud.
 * @version 1.0
 * @date [Ημερομηνία Τελευταίας Τροποποίησης, π.χ., 2025-05-14]
 *
 * @copyright Copyright (c) 2025
 *
 * @mainpage IoT Cloud Project για Πτυχιακή Εργασία
 *
 * Αυτό το project υλοποιεί ένα σύστημα που συνδέεται στο Arduino IoT Cloud,
 * επιτρέπει την επικοινωνία μέσω Bluetooth Low Energy (BLE) για τη λήψη
 * δεδομένων (π.χ., από αισθητήρες ή άλλες συσκευές) σε μορφή JSON,
 * και διασφαλίζει τον συγχρονισμό της τοπικής ώρας με την ώρα του cloud.
 *
 * Κύριες λειτουργίες:
 * - Αρχικοποίηση και διατήρηση σύνδεσης με το Arduino IoT Cloud.
 * - Αρχικοποίηση και διαχείριση BLE server για λήψη μηνυμάτων.
 * - Επεξεργασία εισερχόμενων μηνυμάτων BLE, με έμφαση στα μηνύματα JSON.
 * - Συγχρονισμός και εμφάνιση της ώρας από το IoT Cloud.
 *
 * Αρχιτεκτονική:
 * - main.ino: Κύριος κώδικας εφαρμογής, διαχείριση setup και loop.
 * - thingProperties.h: Αυτόματα παραγόμενο αρχείο από το Arduino IoT Cloud για τις μεταβλητές cloud.
 * - BluetoothHandler.h/.cpp: Κλάση για τη διαχείριση της λειτουργίας BLE.
 * - JsonHandler.h/.cpp: Κλάση/συναρτήσεις για την επεξεργασία (parsing) των JSON μηνυμάτων.
 */

// Βασική βιβλιοθήκη Arduino
#include <Arduino.h>
// Αρχείο ιδιοτήτων για το Arduino IoT Cloud.
// Αυτό το αρχείο συγχωνεύεται αυτόματα από το περιβάλλον του Arduino IoT Cloud
// και περιέχει τις δηλώσεις των Cloud μεταβλητών.
#include "thingProperties.h"
// Προσαρμοσμένη βιβλιοθήκη για τη διαχείριση της επικοινωνίας Bluetooth Low Energy (BLE).
#include "BluetoothHandler.h"
// Βιβλιοθήκη για τη διαχείριση του χρόνου (π.χ. μετατροπή timestamp).
#include <TimeLib.h>
// Βιβλιοθήκη για την επεξεργασία (parsing και δημιουργία) δεδομένων JSON.
#include <ArduinoJson.h>
// Προσαρμοσμένη βιβλιοθήκη για την επεξεργασία εισερχόμενων JSON.
#include "JsonHandler.h"

// Δημιουργία αντικειμένου για τη διαχείριση της λειτουργίας Bluetooth.
BluetoothHandler bleHandler;

// Δηλώσεις συναρτήσεων (Function prototypes) για καλύτερη οργάνωση του κώδικα.
void waitForValidTime();
void printCurrentTime();
String formatTimestamp(unsigned long timestamp);

/**
 * @brief Συνάρτηση αρχικοποίησης. Εκτελείται μία φορά κατά την εκκίνηση ή το reset του Arduino.
 *
 * Αρχικοποιεί την σειριακή επικοινωνία, συνδέεται στο Arduino IoT Cloud,
 * αρχικοποιεί τις Cloud μεταβλητές, ξεκινά τον BLE server,
 * και συγχρονίζει την τοπική ώρα με αυτή του IoT Cloud.
 */
void setup() {
  // Έναρξη σειριακής επικοινωνίας για debugging και μηνύματα κατάστασης.
  Serial.begin(9600);
  // Μικρή καθυστέρηση για να προλάβει να αρχικοποιηθεί η σειριακή οθόνη.
  delay(2000);

  Serial.println("Booting up...");

  // Έναρξη σύνδεσης με το Arduino IoT Cloud χρησιμοποιώντας την προτιμώμενη μέθοδο σύνδεσης.
  // Η `ArduinoIoTPreferredConnection` συνήθως αναφέρεται σε Wi-Fi για ESP32/ESP8266.
  ArduinoCloud.begin(ArduinoIoTPreferredConnection);
  // Αρχικοποίηση όλων των Cloud μεταβλητών που ορίστηκαν στο thingProperties.h.
  initProperties();

  Serial.println("Attempting to connect to Arduino IoT Cloud...");
  // Ορισμός χρονικού ορίου για την προσπάθεια σύνδεσης στο IoT Cloud (30 δευτερόλεπτα).
  unsigned long timeout = millis() + 30000;
  // Βρόχος αναμονής για τη σύνδεση στο IoT Cloud, μέχρι να επιτευχθεί σύνδεση ή να λήξει το χρονικό όριο.
  while (!ArduinoCloud.connected() && millis() < timeout) {
    ArduinoCloud.update(); // Απαραίτητη κλήση για την επεξεργασία των λειτουργιών του cloud.
    delay(500);            // Μικρή καθυστέρηση μεταξύ των προσπαθειών.
    Serial.print(".");
  }
  Serial.println(); // Νέα γραμμή μετά τις τελείες της αναμονής.

  // Έλεγχος αποτελέσματος σύνδεσης στο IoT Cloud.
  if (!ArduinoCloud.connected()) {
    Serial.println("Warning: Failed to connect to IoT Cloud within timeout.");
    // Εδώ θα μπορούσε να προστεθεί λογική για εναλλακτική λειτουργία ή επανεκκίνηση.
  } else {
    Serial.println("Successfully connected to Arduino IoT Cloud!");
  }

  Serial.println("Waiting for IoT Cloud Time Sync (initial delay)...");
  // Μικρή καθυστέρηση για να δοθεί χρόνος στο Cloud να είναι έτοιμο για συγχρονισμό ώρας.
  delay(5000);

  // Έναρξη του BLE server με το όνομα "BoxerServer".
  // Η `begin` πιθανότατα αρχικοποιεί το BLE stack και διαφημίζει τη συσκευή.
  bleHandler.begin("BoxerServer");
  Serial.println("Setup complete: BLE server started.");

  // Επιβεβαίωση ότι οι κύριες υπηρεσίες έχουν ξεκινήσει.
  // Το μήνυμα αυτό μπορεί να είναι περιττό αν το προηγούμενο για το Cloud ήταν επιτυχές.
  // Θα μπορούσε να εξαρτάται από την κατάσταση της σύνδεσης Wi-Fi.
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("Connected to Wi-Fi.");
    Serial.print("Local IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("Warning: Wi-Fi not connected.");
  }


  // Καθυστέρηση για σταθεροποίηση πριν τον συγχρονισμό ώρας.
  delay(2000);
  // Κλήση της συνάρτησης για συγχρονισμό της τοπικής ώρας με το IoT Cloud.
  waitForValidTime();

  Serial.println("Device setup complete. Entering main loop.");
}

/**
 * @brief Κύρια συνάρτηση βρόχου. Εκτελείται επαναληπτικά μετά την ολοκλήρωση του setup().
 *
 * Ενημερώνει συνεχώς την κατάσταση του Arduino IoT Cloud, ελέγχει για νέες συνδέσεις
 * ή μηνύματα από το BLE, και επεξεργάζεται τα εισερχόμενα μηνύματα JSON.
 */
void loop() {
  // Ενημέρωση της κατάστασης και των λειτουργιών του Arduino IoT Cloud.
  // Αυτή η κλήση είναι κρίσιμη για τη διατήρηση της σύνδεσης και τον συγχρονισμό των Cloud μεταβλητών.
  ArduinoCloud.update();

  // Επεξεργασία των λειτουργιών του BLE (π.χ., έλεγχος για νέα μηνύματα, διαχείριση συνδέσεων).
  bleHandler.poll();

  // Ανάγνωση τυχόν εισερχόμενου μηνύματος από τη συσκευή BLE client.
  String incoming = bleHandler.readMessage();

  // Έλεγχος αν υπάρχει κάποιο μήνυμα.
  if (incoming.length() > 0) {
    Serial.print("Received BLE message: ");
    Serial.println(incoming);

    // Καθαρισμός του buffer του εισερχόμενου μηνύματος στον BluetoothHandler για να είναι έτοιμος για το επόμενο.
    bleHandler.clearMessage();

    // Έλεγχος αν το εισερχόμενο μήνυμα πιθανόν να είναι ένα αντικείμενο JSON (απλή ευρετική).
    // Μια πιο ανθεκτική προσέγγιση θα μπορούσε να περιλαμβάνει και έλεγχο για `[` αν υποστηρίζονται JSON arrays.
    if (incoming.startsWith("{")) {
      // Κλήση της στατικής μεθόδου parseIncoming της κλάσης JsonHandler για την επεξεργασία του JSON.
      // Η επεξεργασία (parsing) γίνεται σε ξεχωριστό handler για καλύτερη οργάνωση.
      JsonHandler::parseIncoming(incoming);
    } else {
      Serial.println("Incoming message is not in expected JSON object format.");
    }
  }
  // Μικρή καθυστέρηση για αποφυγή υπερβολικής χρήσης CPU και για σταθερότητα, αν χρειάζεται.
  // delay(10); // Ανάλογα με τις απαιτήσεις απόκρισης.
}

/**
 * @brief Μετατρέπει ένα timestamp (δευτερόλεπτα από την Unix Epoch) σε μορφοποιημένη συμβολοσειρά.
 *
 * @param timestamp Το Unix timestamp (unsigned long) προς μετατροπή.
 * @return String Η μορφοποιημένη ημερομηνία και ώρα (DD/MM/YYYY HH:MM:SS).
 */
String formatTimestamp(unsigned long timestamp) {
  tmElements_t tm; // Δομή για την αποθήκευση των στοιχείων της ώρας.
  breakTime(timestamp, tm); // Συνάρτηση από τη TimeLib.h για τη μετατροπή του timestamp σε tmElements_t.

  char buffer[25]; // Buffer για τη μορφοποιημένη συμβολοσειρά (αρκετά μεγάλος για DD/MM/YYYY HH:MM:SS\0).
  // Μορφοποίηση της ημερομηνίας και ώρας. Το tm.Year είναι έτη από το 1970.
  sprintf(buffer, "%02d/%02d/%04d %02d:%02d:%02d",
          tm.Day, tm.Month, tm.Year + 1970, // Προσθήκη 1970 για το πλήρες έτος
          tm.Hour, tm.Minute, tm.Second);
  return String(buffer); // Επιστροφή ως αντικείμενο String του Arduino.
}

/**
 * @brief Αναμένει μέχρι η τοπική ώρα να συγχρονιστεί με το Arduino IoT Cloud.
 *
 * Προσπαθεί να λάβει την ώρα από το cloud για ένα συγκεκριμένο χρονικό διάστημα (timeout).
 * Εμφανίζει κατάλληλα μηνύματα για την επιτυχία ή αποτυχία του συγχρονισμού.
 */
void waitForValidTime() {
  Serial.print("Waiting for IoT Cloud time sync...");
  // Ορισμός χρονικού ορίου για την προσπάθεια συγχρονισμού ώρας (30 δευτερόλεπτα).
  unsigned long timeout = millis() + 30000;

  // Βρόχος αναμονής μέχρι να ληφθεί έγκυρη ώρα (διαφορετική του 0) ή να λήξει το χρονικό όριο.
  // Η ArduinoCloud.getLocalTime() επιστρέφει Unix timestamp ή 0 αν δεν είναι διαθέσιμη.
  while (ArduinoCloud.getLocalTime() == 0 && millis() < timeout) {
    Serial.print(".");
    delay(1000);            // Αναμονή ενός δευτερολέπτου.
    ArduinoCloud.update();  // Απαραίτητο για την ενημέρωση της ώρας από το cloud.
  }

  // Έλεγχος αποτελέσματος συγχρονισμού ώρας.
  if (ArduinoCloud.getLocalTime() == 0) {
    Serial.println("\nERROR: IoT Cloud time sync failed after timeout!");
    // Εδώ θα μπορούσε να προστεθεί λογική για χρήση μιας προεπιλεγμένης ώρας ή επανάληψη προσπάθειας.
  } else {
    Serial.print("\nIoT Cloud time sync successful! ");
    printCurrentTime(); // Εκτύπωση της συγχρονισμένης ώρας.
  }
}

/**
 * @brief Εκτυπώνει την τρέχουσα τοπική ώρα που έχει ληφθεί από το Arduino IoT Cloud.
 *
 * Εμφανίζει τόσο το raw Unix timestamp όσο και τη μορφοποιημένη, αναγνώσιμη από άνθρωπο, ώρα.
 */
void printCurrentTime() {
  // Λήψη της τρέχουσας τοπικής ώρας (ως Unix timestamp).
  unsigned long currentTime = ArduinoCloud.getLocalTime();

  if (currentTime == 0) {
    Serial.println("Time not available from IoT Cloud yet.");
  } else {
    Serial.print("Current Time (Cloud Sync - Unix Timestamp): ");
    Serial.println(currentTime);
    // Μετατροπή του timestamp σε αναγνώσιμη μορφή.
    String humanReadableTime = formatTimestamp(currentTime);
    Serial.print("Human Readable Time: ");
    Serial.println(humanReadableTime);
  }
}