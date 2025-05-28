#include "arduino_secrets.h"
/**
 * @file BoxServerThing_feb20a.ino // (Ή το πραγματικό όνομα του .ino αρχείου σας)
 * @author [Nick Dimitrakarakos / 83899]
 * @brief Κύριο αρχείο σκίτσου Arduino για το IoT Cloud Boxing Game Project.
 *
 * Αυτό το σκίτσο διαχειρίζεται:
 * 1. Σύνδεση στο Arduino IoT Cloud.
 * 2. Αρχικοποίηση και διαχείριση των Cloud Variables (μέσω του thingProperties.h).
 * 3. Επικοινωνία μέσω Bluetooth Low Energy (BLE) χρησιμοποιώντας την κλάση BluetoothHandler.
 * 4. Λήψη μηνυμάτων JSON μέσω BLE και επεξεργασία τους χρησιμοποιώντας την ενσωματωμένη κλάση JsonHandler.
 * 5. Ενημέρωση των Cloud Variables με βάση τα επεξεργασμένα δεδομένα JSON.
 * 6. Συγχρονισμό της τοπικής ώρας με το Arduino IoT Cloud.
 * 7. Εμφάνιση πληροφοριών κατάστασης και debugging μέσω της σειριακής κονσόλας.
 *
 * @version 1.0 
 * @date 2025-05-14
 *
 * @copyright Copyright (c) 2025
 */

// Βασικές βιβλιοθήκες Arduino και του project
#include <Arduino.h>
#include "thingProperties.h"  // Αυτόματα παραγόμενο αρχείο από το Arduino IoT Cloud.
                              // Περιέχει τους ορισμούς των Cloud Variables και τη συνάρτηση initProperties().
                              // Το περιβάλλον του IoT Cloud το συγχωνεύει κατά τη μεταγλώττιση.
#include "BluetoothHandler.h" // Προσαρμοσμένη βιβλιοθήκη για τη διαχείριση της επικοινωνίας BLE.
#include <TimeLib.h>          // Βιβλιοθήκη για τη διαχείριση και μετατροπή του χρόνου.
#include <ArduinoJson.h>      // Βιβλιοθήκη για την αποτελεσματική επεξεργασία (parsing και δημιουργία) δεδομένων JSON.

/**
 * @class JsonHandler
 * @brief Ενσωματωμένη βοηθητική (utility) κλάση που περιέχει μια στατική μέθοδο
 * για την επεξεργασία (parsing) εισερχόμενων δεδομένων σε μορφή JSON.
 *
 * Η κλάση αυτή δεν χρειάζεται δημιουργία αντικειμένου καθώς η μέθοδός της είναι στατική.
 * Χρησιμοποιείται για την ανάλυση των μηνυμάτων που λαμβάνονται μέσω BLE.
 */
class JsonHandler {
public:
  /**
   * @brief Επεξεργάζεται (parses) μια εισερχόμενη συμβολοσειρά που αναμένεται να είναι σε μορφή JSON.
   *
   * Αποσειριοποιεί τη συμβολοσειρά JSON χρησιμοποιώντας τη βιβλιοθήκη ArduinoJson.
   * Ενημερώνει τις καθολικές Cloud Variables ανάλογα με το περιεχόμενο του JSON.
   * Υποστηρίζει δύο κύριες δομές JSON:
   * 1. "RoundStatusCommand": Για εντολές επαναφοράς των μεταβλητών του παιχνιδιού.
   * 2. Δεδομένα χτυπήματος: Περιέχει πληροφορίες για ένα χτύπημα (ποιος χτύπησε, ποιος χτυπήθηκε, σκορ, κ.λπ.).
   *
   * @param incoming Η συμβολοσειρά (String) που περιέχει τα δεδομένα JSON προς επεξεργασία.
   */
  static void parseIncoming(const String &incoming) {
    // Δημιουργία ενός στατικού JSON document. Το μέγεθος (256 bytes) πρέπει να είναι
    // επαρκές για το μεγαλύτερο αναμενόμενο JSON μήνυμα.
    // Αν τα JSON μηνύματα είναι μεγαλύτερα, αυτό το μέγεθος πρέπει να αυξηθεί.
    StaticJsonDocument<256> doc;

    // Αποσειριοποίηση της εισερχόμενης συμβολοσειράς JSON.
    DeserializationError error = deserializeJson(doc, incoming);

    // Έλεγχος για σφάλματα κατά την αποσειριοποίηση.
    if (error) {
      Serial.print(F("JsonHandler - JSON parse failed: ")); // Χρήση F() για εξοικονόμηση RAM
      Serial.println(error.f_str());
      return; // Έξοδος από τη συνάρτηση αν η αποσειριοποίηση απέτυχε.
    }

    // Έλεγχος αν το JSON περιέχει το κλειδί "RoundStatusCommand".
    // Αυτό υποδεικνύει ένα μήνυμα εντολής για την κατάσταση του γύρου (π.χ., reset).
    if (doc.containsKey("RoundStatusCommand")) {
      // Εξαγωγή της τιμής "Command" από το αντικείμενο "RoundStatusCommand".
      // Η χρήση `| 0` παρέχει μια προεπιλεγμένη τιμή (0) αν το κλειδί "Command" δεν υπάρχει ή δεν είναι αριθμός.
      int cmd = doc["RoundStatusCommand"]["Command"] | 0;

      if (cmd == 1) { // Εντολή 1: Επαναφορά όλων των μεταβλητών του παιχνιδιού.
        Serial.println(F("JsonHandler - Received RoundStatusCommand (cmd=1): Resetting all game variables."));

        // Επαναφορά των γενικών Cloud Variables που αφορούν το τελευταίο χτύπημα.
        deviceThatGotHit      = "";
        boxerThatScoresThePoint = "";
        punchScore            = 0;
        timeStampOfThePunch   = "";
        sensorValue           = 0;

        // Επαναφορά των Cloud Variables για τον μπλε πυγμάχο.
        blueBoxer_punchCount  = 0;
        blueBoxer_timestamp   = "";
        blueBoxer_sensorValue = 0;

        // Επαναφορά των Cloud Variables για τον κόκκινο πυγμάχο.
        redBoxer_punchCount   = 0;
        redBoxer_timestamp    = "";
        redBoxer_sensorValue  = 0;
        // Οι αλλαγές στις Cloud Variables θα συγχρονιστούν με το cloud στην επόμενη κλήση ArduinoCloud.update().
      } else {
        Serial.print(F("JsonHandler - Received RoundStatusCommand with unknown command value: "));
        Serial.println(cmd);
      }
    }
    // Αν δεν είναι "RoundStatusCommand", τότε επεξεργασία ως κανονικό μήνυμα δεδομένων χτυπήματος.
    else {
      Serial.println(F("JsonHandler - Received punch data JSON. Parsing..."));

      // Εξαγωγή των τιμών από τα πεδία του JSON.
      // Χρήση `doc["key"]` για πρόσβαση στις τιμές.
      // Η συντομογραφία `var ? val_if_true : val_if_false` χρησιμοποιείται για έλεγχο nullptr.
      const char* devStr   = doc["deviceStr"];      // Η συσκευή που δέχτηκε το χτύπημα (π.χ., "RedBoxer")
      const char* oppDev   = doc["oppositeDevice"]; // Η συσκευή που έκανε το χτύπημα (ο αντίπαλος)
      const char* punchStr = doc["punchCount"];     // Ο τρέχων αριθμός χτυπήματος (ως string)
      const char* timeStr  = doc["timestamp"];      // Η χρονοσφραγίδα του χτυπήματος
      const char* sensor   = doc["sensorValue"];    // Η τιμή του αισθητήρα (ως string)

      // Εκχώρηση των τιμών στις γενικές Cloud μεταβλητές.
      // Έλεγχος για nullptr (μέσω της τριαδικής συνθήκης) για αποφυγή σφαλμάτων
      // αν κάποιο πεδίο λείπει από το JSON. Αν λείπει, εκχωρείται προεπιλεγμένη τιμή.
      deviceThatGotHit      = devStr   ? String(devStr)   : "";
      boxerThatScoresThePoint = oppDev   ? String(oppDev)   : "";
      punchScore            = punchStr ? atoi(punchStr)   : 0; // Μετατροπή string σε integer
      timeStampOfThePunch   = timeStr  ? String(timeStr)  : "";
      sensorValue           = sensor   ? atoi(sensor)     : 0; // Μετατροπή string σε integer

      // Debugging output για τις γενικές μεταβλητές
      /*
      Serial.print(F("JsonHandler - Parsed Generic Data: deviceThatGotHit=")); Serial.print(deviceThatGotHit);
      Serial.print(F(", boxerThatScoresThePoint=")); Serial.print(boxerThatScoresThePoint);
      Serial.print(F(", punchScore=")); Serial.print(punchScore);
      Serial.print(F(", timeStampOfThePunch=")); Serial.print(timeStampOfThePunch);
      Serial.print(F(", sensorValue=")); Serial.println(sensorValue);
      */

      // Ειδική λογική για την ενημέρωση των μεταβλητών του κάθε πυγμάχου.
      // Η λογική είναι: αν το `deviceStr` (η συσκευή που χτυπήθηκε) είναι ο "RedBoxer",
      // τότε ο "BlueBoxer" είναι αυτός που πέτυχε το χτύπημα, και αντίστροφα.
      String deviceString = devStr ? String(devStr) : "";

      if (deviceString == "RedBoxer") {
        // Το χτύπημα καταγράφηκε στον RedBoxer, άρα ο BlueBoxer το προκάλεσε.
        // Ενημέρωση των Cloud Variables του BlueBoxer με τα δεδομένα του χτυπήματος.
        blueBoxer_punchCount  = punchScore; // Ο αριθμός χτυπήματος που πέτυχε ο μπλε.
        blueBoxer_timestamp   = timeStampOfThePunch; // Η χρονοσφραγίδα του χτυπήματος του μπλε.
        blueBoxer_sensorValue = sensorValue;       // Η τιμή του αισθητήρα από το χτύπημα του μπλε.
        Serial.println(F("JsonHandler - Data attributed to BlueBoxer (hit on RedBoxer)."));
      }
      else if (deviceString == "BlueBoxer") {
        // Το χτύπημα καταγράφηκε στον BlueBoxer, άρα ο RedBoxer το προκάλεσε.
        // Ενημέρωση των Cloud Variables του RedBoxer με τα δεδομένα του χτυπήματος.
        redBoxer_punchCount   = punchScore; // Ο αριθμός χτυπήματος που πέτυχε ο κόκκινος.
        redBoxer_timestamp    = timeStampOfThePunch; // Η χρονοσφραγίδα του χτυπήματος του κόκκινου.
        redBoxer_sensorValue  = sensorValue;       // Η τιμή του αισθητήρα από το χτύπημα του κόκκινου.
        Serial.println(F("JsonHandler - Data attributed to RedBoxer (hit on BlueBoxer)."));
      } else if (devStr != nullptr) { // Αν το devStr υπάρχει αλλά δεν είναι "RedBoxer" ή "BlueBoxer"
        Serial.print(F("JsonHandler - Unknown deviceStr for boxer-specific logic: "));
        Serial.println(deviceString);
      } else { // Αν το devStr είναι nullptr
        Serial.println(F("JsonHandler - deviceStr is null, cannot determine specific boxer logic."));
      }
    }
  }
};


// Δημιουργία καθολικού αντικειμένου για τη διαχείριση της λειτουργίας Bluetooth.
BluetoothHandler bleHandler;

// Δηλώσεις συναρτήσεων (Function prototypes) που ορίζονται παρακάτω στο αρχείο.
void waitForValidTime();
void printCurrentTime();
String formatTimestamp(unsigned long timestamp);

/**
 * @brief Συνάρτηση αρχικοποίησης. Εκτελείται μία φορά κατά την εκκίνηση ή το reset του Arduino.
 *
 * Αρχικοποιεί:
 * - Τη σειριακή επικοινωνία για debugging.
 * - Τη σύνδεση με το Arduino IoT Cloud και τις Cloud μεταβλητές.
 * - Τον BLE server μέσω του αντικειμένου bleHandler.
 * - Προσπαθεί να συγχρονίσει την τοπική ώρα με αυτή του IoT Cloud.
 */
void setup() {
  // Έναρξη σειριακής επικοινωνίας για debugging και μηνύματα κατάστασης.
  Serial.begin(9600);
  // Μικρή καθυστέρηση για να προλάβει να αρχικοποιηθεί η σειριακή οθόνη (αν χρειάζεται).
  delay(2000); // 2 δευτερόλεπτα

  Serial.println(F("\n[SETUP] Booting up device..."));

  // Έναρξη σύνδεσης με το Arduino IoT Cloud χρησιμοποιώντας την προτιμώμενη μέθοδο σύνδεσης (π.χ., Wi-Fi).
  ArduinoCloud.begin(ArduinoIoTPreferredConnection);
  // Αρχικοποίηση όλων των Cloud μεταβλητών που ορίστηκαν στο thingProperties.h.
  // Αυτή η συνάρτηση καλεί επίσης τις onXXXChange συναρτήσεις για τις μεταβλητές που έχουν οριστεί ως READ_WRITE.
  initProperties();
  Serial.println(F("[SETUP] Initialized Thing Properties."));

  Serial.println(F("[SETUP] Attempting to connect to Arduino IoT Cloud..."));
  // Ορισμός χρονικού ορίου για την προσπάθεια σύνδεσης στο IoT Cloud (30 δευτερόλεπτα).
  unsigned long cloudConnectTimeout = millis() + 30000;
  // Βρόχος αναμονής για τη σύνδεση στο IoT Cloud.
  while (!ArduinoCloud.connected() && millis() < cloudConnectTimeout) {
    ArduinoCloud.update(); // Απαραίτητη κλήση για την επεξεργασία των λειτουργιών του cloud.
    delay(500);            // Μικρή καθυστέρηση μεταξύ των προσπαθειών.
    Serial.print(F("."));
  }
  Serial.println(); // Νέα γραμμή μετά τις τελείες της αναμονής.

  // Έλεγχος αποτελέσματος σύνδεσης στο IoT Cloud.
  if (!ArduinoCloud.connected()) {
    Serial.println(F("[SETUP] WARNING: Failed to connect to IoT Cloud within timeout."));
    // Εδώ θα μπορούσε να προστεθεί λογική για εναλλακτική λειτουργία ή ένδειξη σφάλματος.
  } else {
    Serial.println(F("[SETUP] Successfully connected to Arduino IoT Cloud!"));
  }

  Serial.println(F("[SETUP] Waiting for initial IoT Cloud Time Sync (5s delay)..."));
  // Μικρή καθυστέρηση για να δοθεί χρόνος στο Cloud να είναι έτοιμο για συγχρονισμό ώρας.
  delay(5000);

  // Έναρξη του BLE server με το όνομα "BoxerServer".
  // Η μέθοδος `begin` της `bleHandler` αρχικοποιεί το BLE stack και διαφημίζει τη συσκευή.
  bleHandler.begin("BoxerServer"); // Το όνομα που θα φαίνεται στις BLE scans.
  Serial.println(F("[SETUP] BLE server started. Advertising as 'BoxerServer'."));

  // Εμφάνιση κατάστασης Wi-Fi και τοπικής IP (αν η σύνδεση είναι μέσω Wi-Fi).
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(F("[SETUP] Connected to Wi-Fi."));
    Serial.print(F("[SETUP] Local IP Address: "));
    Serial.println(WiFi.localIP());
  } else {
    Serial.println(F("[SETUP] WARNING: Wi-Fi not connected. IoT Cloud functionality might be affected if Wi-Fi is the preferred connection."));
  }

  // Καθυστέρηση για σταθεροποίηση πριν τον τελικό συγχρονισμό ώρας.
  delay(2000);
  // Κλήση της συνάρτησης για συγχρονισμό της τοπικής ώρας με το IoT Cloud.
  waitForValidTime();

  Serial.println(F("[SETUP] Device setup complete. Entering main loop."));
}

/**
 * @brief Κύρια συνάρτηση βρόχου. Εκτελείται επαναληπτικά μετά την ολοκλήρωση του setup().
 *
 * Κύριες λειτουργίες εντός του loop:
 * - Ενημέρωση της κατάστασης του Arduino IoT Cloud (κρίσιμο για συγχρονισμό).
 * - Επεξεργασία γεγονότων BLE (νέα μηνύματα, συνδέσεις/αποσυνδέσεις).
 * - Ανάγνωση και επεξεργασία εισερχόμενων μηνυμάτων JSON από το BLE.
 */
void loop() {
  // Ενημέρωση της κατάστασης και των λειτουργιών του Arduino IoT Cloud.
  // Αυτή η κλήση είναι κρίσιμη για τη διατήρηση της σύνδεσης, τον συγχρονισμό
  // των Cloud μεταβλητών και την εκτέλεση των onXXXChange callbacks.
  ArduinoCloud.update();

  // Επεξεργασία των λειτουργιών του BLE (π.χ., έλεγχος για νέα μηνύματα, διαχείριση συνδέσεων).
  // Η `poll()` πρέπει να καλείται τακτικά.
  bleHandler.poll();

  // Ανάγνωση τυχόν εισερχόμενου μηνύματος από τη συνδεδεμένη BLE client συσκευή.
  String incomingMessage = bleHandler.readMessage();

  // Έλεγχος αν υπάρχει κάποιο νέο, μη κενό μήνυμα.
  if (incomingMessage.length() > 0) {
    Serial.print(F("[LOOP] Received raw BLE message: "));
    Serial.println(incomingMessage);

    // Καθαρισμός του buffer του εισερχόμενου μηνύματος στον BluetoothHandler
    // ώστε να είναι έτοιμος να δεχτεί το επόμενο μήνυμα.
    bleHandler.clearMessage();

    // Έλεγχος αν το εισερχόμενο μήνυμα πιθανόν να είναι ένα αντικείμενο JSON
    // (απλός έλεγχος αν ξεκινά με '{').
    // Μια πιο ανθεκτική προσέγγιση θα μπορούσε να περιλαμβάνει και έλεγχο για `[`
    // αν υποστηρίζονται JSON arrays ως κύρια δομή μηνύματος.
    if (incomingMessage.startsWith("{")) {
      Serial.println(F("[LOOP] Message starts with '{', attempting JSON parse..."));
      // Κλήση της στατικής μεθόδου parseIncoming της κλάσης JsonHandler
      // για την επεξεργασία του JSON και την ενημέρωση των Cloud Variables.
      JsonHandler::parseIncoming(incomingMessage);

      // (Προαιρετικό) Επιβεβαίωση των τιμών των Cloud Variables στη σειριακή οθόνη μετά το parsing.
      // Αφαιρέστε τα σχόλια για ενεργοποίηση.
      /*
      Serial.println(F("[LOOP] Current Cloud Variable values after parse:"));
      Serial.print(F("  deviceThatGotHit: ")); Serial.println(deviceThatGotHit);
      Serial.print(F("  boxerThatScoresThePoint: ")); Serial.println(boxerThatScoresThePoint);
      Serial.print(F("  punchScore: ")); Serial.println(punchScore);
      Serial.print(F("  timeStampOfThePunch: ")); Serial.println(timeStampOfThePunch);
      Serial.print(F("  sensorValue: ")); Serial.println(sensorValue);
      Serial.print(F("  blueBoxer_punchCount: ")); Serial.println(blueBoxer_punchCount);
      Serial.print(F("  redBoxer_punchCount: ")); Serial.println(redBoxer_punchCount);
      */
    } else {
      Serial.println(F("[LOOP] Incoming message does not start with '{'. Not treated as JSON."));
    }
  }
  // Μικρή καθυστέρηση για αποφυγή υπερβολικής χρήσης CPU και για σταθερότητα, αν χρειάζεται.
  // delay(10); // Για παράδειγμα, 10ms. Προσαρμόστε ανάλογα με τις απαιτήσεις απόκρισης.
}

/**
 * @brief Μετατρέπει ένα Unix timestamp (δευτερόλεπτα από την Epoch 1/1/1970)
 * σε μια μορφοποιημένη συμβολοσειρά ημερομηνίας και ώρας.
 *
 * @param timestamp Το Unix timestamp (unsigned long) προς μετατροπή.
 * @return String Η μορφοποιημένη ημερομηνία και ώρα σε μορφή "DD/MM/YYYY HH:MM:SS".
 */
String formatTimestamp(unsigned long timestamp) {
  tmElements_t tm; // Δομή από τη TimeLib.h για την αποθήκευση των στοιχείων της ώρας.
  breakTime(timestamp, tm); // Συνάρτηση από τη TimeLib.h για τη μετατροπή του timestamp σε tmElements_t.

  // Buffer για τη μορφοποιημένη συμβολοσειρά. Πρέπει να είναι αρκετά μεγάλος
  // για να χωρέσει την ημερομηνία/ώρα και τον null terminator (π.χ., "DD/MM/YYYY HH:MM:SS\0" -> 20 chars).
  char buffer[20];
  // Μορφοποίηση της ημερομηνίας και ώρας.
  // Το tm.Year είναι έτη από το 1970, οπότε προσθέτουμε 1970 για το πλήρες έτος.
  sprintf(buffer, "%02d/%02d/%04d %02d:%02d:%02d",
          tm.Day, tm.Month, tm.Year + 1970,
          tm.Hour, tm.Minute, tm.Second);
  return String(buffer); // Επιστροφή ως αντικείμενο String του Arduino.
}

/**
 * @brief Αναμένει μέχρι η τοπική ώρα να συγχρονιστεί με το Arduino IoT Cloud.
 *
 * Προσπαθεί να λάβει την ώρα από το cloud για ένα συγκεκριμένο χρονικό διάστημα (timeout).
 * Εμφανίζει κατάλληλα μηνύματα για την επιτυχία ή αποτυχία του συγχρονισμού.
 * Η `ArduinoCloud.getLocalTime()` επιστρέφει Unix timestamp (δευτερόλεπτα από 1/1/1970)
 * ή 0 αν η ώρα δεν είναι ακόμα διαθέσιμη.
 */
void waitForValidTime() {
  Serial.print(F("[TIME] Waiting for IoT Cloud time sync..."));
  // Ορισμός χρονικού ορίου για την προσπάθεια συγχρονισμού ώρας (30 δευτερόλεπτα).
  unsigned long timeSyncTimeout = millis() + 30000;

  // Βρόχος αναμονής μέχρι να ληφθεί έγκυρη ώρα (διαφορετική του 0) ή να λήξει το χρονικό όριο.
  while (ArduinoCloud.getLocalTime() == 0 && millis() < timeSyncTimeout) {
    Serial.print(F("."));
    delay(1000);            // Αναμονή ενός δευτερολέπτου.
    ArduinoCloud.update();  // Απαραίτητο για την ενημέρωση της ώρας από το cloud.
  }
  Serial.println(); // Νέα γραμμή μετά τις τελείες.

  // Έλεγχος αποτελέσματος συγχρονισμού ώρας.
  if (ArduinoCloud.getLocalTime() == 0) {
    Serial.println(F("[TIME] ERROR: IoT Cloud time sync failed after timeout!"));
    // Εδώ θα μπορούσε να προστεθεί λογική για χρήση μιας προεπιλεγμένης ώρας,
    // ή ένδειξη ότι η ώρα δεν είναι συγχρονισμένη.
  } else {
    Serial.print(F("[TIME] IoT Cloud time sync successful! "));
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
    Serial.println(F("[TIME] Current time not available from IoT Cloud yet."));
  } else {
    Serial.print(F("[TIME] Current Time (Cloud Sync - Unix Timestamp): "));
    Serial.println(currentTime);
    // Μετατροπή του timestamp σε αναγνώσιμη μορφή DD/MM/YYYY HH:MM:SS.
    String humanReadableTime = formatTimestamp(currentTime);
    Serial.print(F("[TIME] Human Readable Time: "));
    Serial.println(humanReadableTime);
  }
}