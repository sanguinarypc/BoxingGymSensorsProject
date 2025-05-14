/**
 * @file JsonHandler.cpp
 * @author [Nick Dimitrakarakos / 83899]
 * @brief Υλοποίηση της στατικής κλάσης JsonHandler για την επεξεργασία (parsing)
 * εισερχόμενων μηνυμάτων σε μορφή JSON.
 * @version 1.0
 * @date 2025-05-14
 *
 * @copyright Copyright (c) 2025
 *
 * @details
 * Αυτό το αρχείο περιέχει τη λογική για την ανάλυση συμβολοσειρών JSON
 * που λαμβάνονται (π.χ., μέσω BLE). Χρησιμοποιεί τη βιβλιοθήκη ArduinoJson
 * για την αποσειριοποίηση και στη συνέχεια ενημερώνει τις καθολικές (extern)
 * μεταβλητές του Arduino IoT Cloud ανάλογα με το περιεχόμενο του JSON.
 * Υποστηρίζει δύο κύριες δομές JSON: μία για τον έλεγχο της κατάστασης του γύρου
 * (RoundStatusCommand) και μία για τα δεδομένα ενός χτυπήματος (punch data).
 */

#include "JsonHandler.h"    // Ορισμός της κλάσης JsonHandler.
#include <ArduinoJson.h>    // Βιβλιοθήκη για την επεξεργασία JSON (parsing, serialization).

// 1) Συμπερίληψη του ArduinoIoTCloud.h για την αναγνώριση των τύπων Cloud μεταβλητών.
//    Αυτό είναι απαραίτητο ώστε ο compiler να γνωρίζει τους τύπους όπως
//    CloudString, CloudInt, κ.λπ., που χρησιμοποιούνται από τις extern μεταβλητές.
#include <ArduinoIoTCloud.h>
#include "thingProperties.h" // Περιλαμβάνεται για να έχουμε πρόσβαση στις Cloud μεταβλητές.
                             // Στο αρχικό σχόλιο αναφερόταν η χρήση extern, αλλά η συμπερίληψη
                             // του thingProperties.h είναι ο πιο συνηθισμένος τρόπος στο Arduino IoT Cloud
                             // για να γίνουν γνωστές οι Cloud μεταβλητές στο scope.
                             // Αν προκαλεί multiple definitions, τότε η προσέγγιση με extern είναι σωστή,
                             // αλλά πρέπει να διασφαλιστεί ότι οι ορισμοί υπάρχουν ακριβώς μία φορά (συνήθως στο .ino).
                             // Για την απλότητα και τη συνηθισμένη πρακτική, θα το αφήσω έτσι,
                             // αλλά αν υπάρχει πρόβλημα, η λύση με extern είναι η εναλλακτική.

/*
  Σημείωση για τις Cloud Μεταβλητές:
  Οι παρακάτω μεταβλητές είναι οι Cloud Variables που ορίζονται στο Arduino IoT Cloud.
  Η συμπερίληψη του "thingProperties.h" τις καθιστά διαθέσιμες.
  Αντ' αυτού, θα μπορούσαν να δηλωθούν ως 'extern' αν το "thingProperties.h"
  προκαλούσε προβλήματα πολλαπλών ορισμών όταν συμπεριλαμβάνεται σε πολλά αρχεία.
  Για παράδειγμα:
    extern CloudString deviceThatGotHit;
    extern CloudString boxerThatScoresThePoint;
    // ... και ούτω καθεξής για όλες τις Cloud μεταβλητές.
  Αυτή η προσέγγιση (με extern) απαιτεί οι μεταβλητές να έχουν οριστεί (όχι μόνο δηλωθεί)
  σε ένα αρχείο .cpp (συνήθως στο κύριο .ino αρχείο, όπου το thingProperties.h
  ενσωματώνεται αυτόματα).
*/


/**
 * @brief Επεξεργάζεται (parses) μια εισερχόμενη συμβολοσειρά JSON.
 *
 * Αποσειριοποιεί τη συμβολοσειρά JSON χρησιμοποιώντας τη βιβλιοθήκη ArduinoJson.
 * Ανάλογα με τα κλειδιά που περιέχει το JSON, είτε επαναφέρει τις μεταβλητές
 * (αν πρόκειται για "RoundStatusCommand") είτε εξάγει δεδομένα χτυπήματος
 * και ενημερώνει τις αντίστοιχες Cloud μεταβλητές.
 *
 * @param incoming Η συμβολοσειρά (String) που περιέχει τα δεδομένα JSON προς επεξεργασία.
 */
void JsonHandler::parseIncoming(const String &incoming) {
  // Δημιουργία ενός στατικού JSON document. Το μέγεθος (256 bytes) πρέπει να είναι
  // επαρκές για το μεγαλύτερο αναμενόμενο JSON μήνυμα.
  // Αν τα JSON μηνύματα είναι μεγαλύτερα, αυτό το μέγεθος πρέπει να αυξηθεί.
  // Για πιο δυναμική διαχείριση μνήμης, θα μπορούσε να χρησιμοποιηθεί DynamicJsonDocument,
  // αλλά το StaticJsonDocument είναι συνήθως προτιμότερο σε περιβάλλοντα με περιορισμένη μνήμη όπως το Arduino.
  StaticJsonDocument<256> doc;

  // Αποσειριοποίηση της εισερχόμενης συμβολοσειράς JSON.
  DeserializationError error = deserializeJson(doc, incoming);

  // Έλεγχος για σφάλματα κατά την αποσειριοποίηση.
  if (error) {
    Serial.print(F("deserializeJson() failed: ")); // Χρήση F() macro για εξοικονόμηση RAM.
    Serial.println(error.f_str()); // Εκτύπωση του μηνύματος σφάλματος.
    return; // Έξοδος από τη συνάρτηση αν η αποσειριοποίηση απέτυχε.
  }

  // Έλεγχος αν το JSON περιέχει το κλειδί "RoundStatusCommand".
  // Αυτό υποδεικνύει ένα μήνυμα εντολής για την κατάσταση του γύρου.
  if (doc.containsKey("RoundStatusCommand")) {
    // Εξαγωγή της τιμής "Command" από το αντικείμενο "RoundStatusCommand".
    // Η χρήση `| 0` παρέχει μια προεπιλεγμένη τιμή (0) αν το κλειδί "Command" δεν υπάρχει ή δεν είναι αριθμός.
    int cmd = doc["RoundStatusCommand"]["Command"] | 0;

    if (cmd == 1) { // Εντολή 1: Επαναφορά όλων των μεταβλητών.
      Serial.println(F("Received RoundStatusCommand: Resetting all boxing variables."));

      // Επαναφορά των γενικών μεταβλητών κατάστασης χτυπήματος.
      deviceThatGotHit      = "";
      boxerThatScoresThePoint = "";
      punchScore            = 0;
      timeStampOfThePunch   = "";
      sensorValue           = 0;

      // Επαναφορά των μεταβλητών για τον μπλε πυγμάχο.
      blueBoxer_punchCount  = 0;
      blueBoxer_timestamp   = "";
      blueBoxer_sensorValue = 0;

      // Επαναφορά των μεταβλητών για τον κόκκινο πυγμάχο.
      redBoxer_punchCount   = 0;
      redBoxer_timestamp    = "";
      redBoxer_sensorValue  = 0;

      // Ενημέρωση του Arduino IoT Cloud με τις νέες (μηδενισμένες) τιμές.
      // Η ArduinoCloud.update() καλείται στο κυρίως loop, αλλά μια άμεση ενημέρωση
      // θα μπορούσε να γίνει εδώ αν απαιτείται άμεση απόκριση στο Cloud.
      // ArduinoCloud.update(); // Προαιρετικά, για άμεση ενημέρωση.
    } else {
      Serial.print(F("Received RoundStatusCommand with unknown command: "));
      Serial.println(cmd);
    }
  }
  // Αν δεν είναι "RoundStatusCommand", τότε επεξεργασία ως κανονικό μήνυμα δεδομένων χτυπήματος.
  else {
    Serial.println(F("Received punch data JSON. Parsing..."));

    // Εξαγωγή των τιμών από τα πεδία του JSON.
    // Χρήση `doc["key"]` για πρόσβαση στις τιμές.
    // Είναι καλή πρακτική να ελέγχεται αν τα κλειδιά υπάρχουν πριν την πρόσβαση,
    // ή να χρησιμοποιούνται προεπιλεγμένες τιμές.
    const char* devStr   = doc["deviceStr"];      // Η συσκευή που δέχτηκε το χτύπημα (π.χ., "RedBoxer" ή "BlueBoxer")
    const char* oppDev   = doc["oppositeDevice"]; // Η συσκευή που έκανε το χτύπημα (ο αντίπαλος)
    const char* punchStr = doc["punchCount"];     // Ο αριθμός του χτυπήματος (ως string, χρειάζεται μετατροπή σε int)
    const char* timeStr  = doc["timestamp"];      // Η χρονοσφραγίδα του χτυπήματος
    const char* sensor   = doc["sensorValue"];    // Η τιμή του αισθητήρα (ως string, χρειάζεται μετατροπή σε int)

    // Εκχώρηση των τιμών στις γενικές Cloud μεταβλητές.
    // Έλεγχος για nullptr για αποφυγή σφαλμάτων αν κάποιο πεδίο λείπει από το JSON.
    // Αν το πεδίο λείπει, εκχωρείται μια προεπιλεγμένη τιμή (κενή συμβολοσειρά ή 0).
    deviceThatGotHit      = (devStr   != nullptr) ? String(devStr) : "";
    boxerThatScoresThePoint = (oppDev   != nullptr) ? String(oppDev) : "";
    punchScore            = (punchStr != nullptr) ? atoi(punchStr) : 0; // Μετατροπή string σε integer
    timeStampOfThePunch   = (timeStr  != nullptr) ? String(timeStr) : "";
    sensorValue           = (sensor   != nullptr) ? atoi(sensor)   : 0; // Μετατροπή string σε integer

    Serial.print(F("Parsed Generic Data: deviceThatGotHit=")); Serial.print(deviceThatGotHit);
    Serial.print(F(", boxerThatScoresThePoint=")); Serial.print(boxerThatScoresThePoint);
    Serial.print(F(", punchScore=")); Serial.print(punchScore);
    Serial.print(F(", timeStampOfThePunch=")); Serial.print(timeStampOfThePunch);
    Serial.print(F(", sensorValue=")); Serial.println(sensorValue);


    // Ειδική λογική για την ενημέρωση των μεταβλητών του κάθε πυγμάχου.
    // Αν το χτύπημα καταγράφηκε στη συσκευή "RedBoxer", τότε ο "BlueBoxer" έκανε το χτύπημα.
    // Αν το χτύπημα καταγράφηκε στη συσκευή "BlueBoxer", τότε ο "RedBoxer" έκανε το χτύπημα.
    String deviceString = (devStr != nullptr) ? String(devStr) : "";

    if (deviceString == "RedBoxer") {
      // Το χτύπημα καταγράφηκε στον RedBoxer, άρα ο BlueBoxer το προκάλεσε.
      // Ενημέρωση των μεταβλητών του BlueBoxer με τα δεδομένα του χτυπήματος.
      blueBoxer_punchCount  = punchScore; // Ο αριθμός χτυπήματος που πέτυχε ο μπλε.
      blueBoxer_timestamp   = timeStampOfThePunch; // Η χρονοσφραγίδα του χτυπήματος του μπλε.
      blueBoxer_sensorValue = sensorValue;       // Η τιμή του αισθητήρα από το χτύπημα του μπλε.
      Serial.println(F("Data attributed to BlueBoxer (hit on RedBoxer)."));
    }
    else if (deviceString == "BlueBoxer") {
      // Το χτύπημα καταγράφηκε στον BlueBoxer, άρα ο RedBoxer το προκάλεσε.
      // Ενημέρωση των μεταβλητών του RedBoxer με τα δεδομένα του χτυπήματος.
      redBoxer_punchCount   = punchScore; // Ο αριθμός χτυπήματος που πέτυχε ο κόκκινος.
      redBoxer_timestamp    = timeStampOfThePunch; // Η χρονοσφραγίδα του χτυπήματος του κόκκινου.
      redBoxer_sensorValue  = sensorValue;       // Η τιμή του αισθητήρα από το χτύπημα του κόκκινου.
      Serial.println(F("Data attributed to RedBoxer (hit on BlueBoxer)."));
    } else if (devStr != nullptr) {
        Serial.print(F("Unknown deviceStr for boxer-specific logic: "));
        Serial.println(deviceString);
    } else {
        Serial.println(F("deviceStr is null, cannot determine specific boxer logic."));
    }
    // ArduinoCloud.update(); // Προαιρετικά, για άμεση ενημέρωση των Cloud μεταβλητών.
  }
}

