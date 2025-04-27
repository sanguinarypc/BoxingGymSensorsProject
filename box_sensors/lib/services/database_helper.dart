import 'dart:math'; // Needed for random sample data
import 'package:flutter/material.dart'; // Needed for debugPrint
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // Import the uuid package

// Helper function to check if a column exists (remains the same)
Future<bool> _columnExists(Database db, String table, String columnName) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  for (final col in columns) {
    if (col['name'] == columnName) {
      return true;
    }
  }
  return false;
}

class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final Uuid _uuid = const Uuid(); // Instantiate Uuid generator
  final Random _random = Random(); // Instantiate Random generator

  // Private constructor
  DatabaseHelper._internal();

  // Factory constructor to return the same instance
  factory DatabaseHelper() => _instance;

  // Getter to access the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // --- Database Initialization and Schema ---
  // _initDatabase, _onCreate, table creation helpers, _insertDefaultSettings, _onUpgrade
  // ... (These methods remain the same as the previous version) ...
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'messages.db');
    return await openDatabase( path, version: 7, onOpen: (db) async { await db.execute("PRAGMA foreign_keys = ON"); }, onCreate: _onCreate, onUpgrade: _onUpgrade, );
  }
  Future<void> _onCreate(Database db, int version) async {
    await db.execute("PRAGMA foreign_keys = ON"); debugPrint("Running _onCreate for database version $version");
    await _createMatchesTable(db); await _createEventsTable(db); await _createRoundsTable(db);
    await _createMessagesTable(db); await _createTrainingDataTable(db); await _createSettingsTable(db);
    await _insertDefaultSettings( db, ); debugPrint("_onCreate complete.");
  }
  Future<void> _createMatchesTable(Database db) async { await db.execute(''' CREATE TABLE matches( id INTEGER PRIMARY KEY AUTOINCREMENT, matchName TEXT, matchDate TEXT, rounds INTEGER, finishedAtRound INTEGER, totalTime TEXT, roundTime INTEGER, breakTime INTEGER ) '''); debugPrint("Table 'matches' created."); }
  Future<void> _createEventsTable(Database db) async { await db.execute(''' CREATE TABLE events( id TEXT PRIMARY KEY, timestamp INTEGER, matchId INTEGER, winner TEXT, FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE ) '''); debugPrint("Table 'events' created."); }
  Future<void> _createRoundsTable(Database db) async { await db.execute(''' CREATE TABLE rounds( id INTEGER PRIMARY KEY AUTOINCREMENT, eventId TEXT, punchCount INTEGER, matchId INTEGER, round INTEGER, timestamp INTEGER, FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE, FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE, UNIQUE(eventId, round) ) '''); debugPrint("Table 'rounds' created."); }
  Future<void> _createMessagesTable(Database db) async { await db.execute(''' CREATE TABLE messages( id INTEGER PRIMARY KEY AUTOINCREMENT, device TEXT, punchBy TEXT, punchCount TEXT, timestamp TEXT, sensorValue TEXT, roundId INTEGER, matchId INTEGER, FOREIGN KEY (roundId) REFERENCES rounds(id) ON DELETE CASCADE, FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE ) '''); debugPrint("Table 'messages' created."); }
  Future<void> _createTrainingDataTable(Database db) async { await db.execute(''' CREATE TABLE trainingdata( id INTEGER PRIMARY KEY AUTOINCREMENT, device TEXT, punchBy TEXT, punchCount TEXT, timestamp TEXT, sensorValue TEXT, roundId INTEGER ) '''); debugPrint("Table 'trainingdata' created."); }
  Future<void> _createSettingsTable(Database db) async { await db.execute(''' CREATE TABLE settings( id INTEGER PRIMARY KEY, fsrSensitivity INTEGER, fsrThreshold INTEGER, roundTime INTEGER, breakTime INTEGER, secondsBeforeRoundBegins INTEGER, rounds INTEGER ) '''); debugPrint("Table 'settings' created."); }
  Future<void> _insertDefaultSettings(Database db) async { await db.insert( 'settings', { 'id': 1, 'fsrSensitivity': 800, 'fsrThreshold': 200, 'roundTime': 180, 'breakTime': 60, 'secondsBeforeRoundBegins': 5, 'rounds': 3, }, conflictAlgorithm: ConflictAlgorithm.replace, ); debugPrint("Default settings inserted/replaced."); }
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async { debugPrint("Upgrading database from version $oldVersion to $newVersion"); if (oldVersion < 4) { if (!await _columnExists(db, 'messages', 'device')) { await db.execute('ALTER TABLE messages ADD COLUMN device TEXT'); debugPrint("Added 'device' column to messages table."); } } if (oldVersion < 5) { if (!await _columnExists(db, 'settings', 'fsrThreshold')) { await db.execute('ALTER TABLE settings ADD COLUMN fsrThreshold INTEGER DEFAULT 200'); debugPrint("Added 'fsrThreshold' column to settings table."); } if (!await _columnExists(db, 'settings', 'roundTime')) { await db.execute('ALTER TABLE settings ADD COLUMN roundTime INTEGER DEFAULT 180'); debugPrint("Added 'roundTime' column to settings table."); } if (!await _columnExists(db, 'settings', 'breakTime')) { await db.execute('ALTER TABLE settings ADD COLUMN breakTime INTEGER DEFAULT 60'); debugPrint("Added 'breakTime' column to settings table."); } if (!await _columnExists(db, 'settings', 'secondsBeforeRoundBegins')) { await db.execute('ALTER TABLE settings ADD COLUMN secondsBeforeRoundBegins INTEGER DEFAULT 5'); debugPrint("Added 'secondsBeforeRoundBegins' column to settings table."); } } if (oldVersion < 6) { if (!await _columnExists(db, 'messages', 'punchBy')) { await db.execute('ALTER TABLE messages ADD COLUMN punchBy TEXT'); debugPrint("Added 'punchBy' column to messages table."); } } if (oldVersion < 7) { if (!await _columnExists(db, 'settings', 'rounds')) { await db.execute('ALTER TABLE settings ADD COLUMN rounds INTEGER DEFAULT 3'); debugPrint("Added 'rounds' column to settings table."); } } debugPrint("Database upgrade complete."); }


  // --- Sample Data Insertion ---

  /// Clears all data from relevant tables. Call before inserting sample data.
  Future<void> _clearAllData() async {
    final db = await database;
    debugPrint("Clearing existing data...");
    await db.delete('messages'); await db.delete('trainingdata');
    await db.delete('rounds'); await db.delete('events');
    await db.delete('matches');
    debugPrint("Data cleared.");
  }

  /// **NEW HELPER:** Formats total seconds into HH:MM:SS string.
  String _formatSecondsToTimeString(int totalSeconds) {
     if (totalSeconds < 0) totalSeconds = 0; // Ensure non-negative
     int s = totalSeconds % 60;
     int m = (totalSeconds ~/ 60) % 60;
     int h = totalSeconds ~/ 3600;
     return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  /// Inserts a comprehensive set of sample data for testing.
  Future<void> insertComprehensiveSampleData() async {
    final db = await database;
    await _clearAllData();
    await _insertDefaultSettings(db);

    debugPrint("Inserting comprehensive sample data...");

    int round1_1 = 0, round2_1 = 0, round2_2 = 0, round2_3 = 0;
    int round3_1 = 0, round3_2 = 0, round3_3 = 0, round3_4 = 0, round3_5 = 0;
    int shortR1 = 0, shortR2 = 0;
    List<int> allInsertedRoundIds = [];


    try {
      // 1. Insert Sample Matches (Store data locally to access roundTime later)
      List<Map<String, dynamic>> sampleMatchesData = [
         { 'matchName': 'Quick Spar (1 Round)', 'matchDate': '2025-04-27', 'rounds': 1, 'finishedAtRound': 1, 'totalTime': '03:15', 'roundTime': 180, 'breakTime': 60, }, // 3 min round
         { 'matchName': 'Standard Bout (3 Rounds)', 'matchDate': '2025-04-27', 'rounds': 3, 'finishedAtRound': 3, 'totalTime': '11:00', 'roundTime': 180, 'breakTime': 60, }, // 3 min rounds
         { 'matchName': 'Short Rounds (2 Rounds)', 'matchDate': '2025-04-26', 'rounds': 2, 'finishedAtRound': 0, 'totalTime': '00:00', 'roundTime': 60, 'breakTime': 30, }, // <<< 1 min (60s) rounds >>>
         { 'matchName': 'Endurance Test (5 Rounds)', 'matchDate': '2025-04-25', 'rounds': 5, 'finishedAtRound': 5, 'totalTime': '19:00', 'roundTime': 180, 'breakTime': 60, }, // 3 min rounds
      ];
      List<int> matchIds = [];
      List<Map<String, dynamic>> insertedMatchesDetails = []; // Store details with ID

      for (var matchData in sampleMatchesData) {
        final id = await insertMatch( /* ... details ... */
           matchName: matchData['matchName'], rounds: matchData['rounds'], matchDate: matchData['matchDate'],
           roundTime: matchData['roundTime'], breakTime: matchData['breakTime'] );
        matchIds.add(id);
        insertedMatchesDetails.add({...matchData, 'id': id});
        if (matchData['finishedAtRound'] > 0) { await updateEditMatch( id: id, /* ... rest ... */
             matchName: matchData['matchName'], matchDate: matchData['matchDate'], rounds: matchData['rounds'],
             finishedAtRound: matchData['finishedAtRound'], totalTime: matchData['totalTime'],
             roundTime: matchData['roundTime'], breakTime: matchData['breakTime'] ); }
      }
      debugPrint("Inserted ${matchIds.length} sample matches.");

      // 2. Insert Sample Events
      List<String> eventIds = [];
      if (matchIds.length >= 4) {
        String event1Id = await insertEvent( matchId: matchIds[0], winner: 'BlueBoxer', ); eventIds.add(event1Id);
        String event2Id = await insertEvent( matchId: matchIds[1], winner: 'RedBoxer', ); eventIds.add(event2Id);
        String eventShortround = await insertEvent(matchId: matchIds[2], winner: null); eventIds.add(eventShortround);
        String event3Id = await insertEvent( matchId: matchIds[3], winner: 'Draw', ); eventIds.add(event3Id);
        debugPrint("Inserted ${eventIds.length} sample events.");
      } else { /* Warning */ }

      // 3. Insert Sample Rounds
       if (eventIds.length >= 4 && matchIds.length >= 4) {
         round1_1 = await insertRound( matchId: matchIds[0], eventId: eventIds[0], round: 1, ); if (round1_1 > 0) allInsertedRoundIds.add(round1_1);
         round2_1 = await insertRound( matchId: matchIds[1], eventId: eventIds[1], round: 1, ); if (round2_1 > 0) allInsertedRoundIds.add(round2_1);
         round2_2 = await insertRound( matchId: matchIds[1], eventId: eventIds[1], round: 2, ); if (round2_2 > 0) allInsertedRoundIds.add(round2_2);
         round2_3 = await insertRound( matchId: matchIds[1], eventId: eventIds[1], round: 3, ); if (round2_3 > 0) allInsertedRoundIds.add(round2_3);
         shortR1 = await insertRound(matchId: matchIds[2], eventId: eventIds[2], round: 1); if(shortR1 > 0) allInsertedRoundIds.add(shortR1);
         shortR2 = await insertRound(matchId: matchIds[2], eventId: eventIds[2], round: 2); if(shortR2 > 0) allInsertedRoundIds.add(shortR2);
         round3_1 = await insertRound( matchId: matchIds[3], eventId: eventIds[3], round: 1, ); if (round3_1 > 0) allInsertedRoundIds.add(round3_1);
         round3_2 = await insertRound( matchId: matchIds[3], eventId: eventIds[3], round: 2, ); if (round3_2 > 0) allInsertedRoundIds.add(round3_2);
         round3_3 = await insertRound( matchId: matchIds[3], eventId: eventIds[3], round: 3, ); if (round3_3 > 0) allInsertedRoundIds.add(round3_3);
         round3_4 = await insertRound( matchId: matchIds[3], eventId: eventIds[3], round: 4, ); if (round3_4 > 0) allInsertedRoundIds.add(round3_4);
         round3_5 = await insertRound( matchId: matchIds[3], eventId: eventIds[3], round: 5, ); if (round3_5 > 0) allInsertedRoundIds.add(round3_5);
       } else { /* Warning */ }
       debugPrint("Inserted ${allInsertedRoundIds.length} sample rounds.");


      // 4. Insert Sample Messages for some Rounds
      int messagesInserted = 0;

      // ---> Messages for Round 1 of Match 0 (roundTime = 180s) <---
      if (round1_1 > 0 && insertedMatchesDetails.isNotEmpty) {
        final matchDetails = insertedMatchesDetails.firstWhere((m) => m['id'] == matchIds[0]);
        int roundTimeSeconds = matchDetails['roundTime'] as int;
        int currentSecondsInRound = 0; // Start time for this round
        debugPrint("Inserting messages for round1_1 (Match 0), Round Time: $roundTimeSeconds seconds");

        // Loop for BlueBoxer punches
        int bluePunchCount = 15 + _random.nextInt(10);
        for (int i = 1; i <= bluePunchCount; i++) {
          int increment = 1 + _random.nextInt(5); // Advance time by 1-5 seconds
          currentSecondsInRound += increment;
          if (currentSecondsInRound >= roundTimeSeconds) break; // Stop if round time exceeded

          String timeString = _formatSecondsToTimeString(currentSecondsInRound); // <<< Use Helper
          await insertMessage( 'BlueBoxer', 'RedBoxer', i.toString(), timeString,
             (_random.nextInt(500) + 300).toString(), round1_1, matchIds[0],
          ); messagesInserted++;
        }

        // Loop for RedBoxer punches (reset time or continue?) Let's interleave roughly - use same counter
        int redPunchCount = 10 + _random.nextInt(8);
         for (int i = 1; i <= redPunchCount; i++) {
           int increment = 1 + _random.nextInt(6); // Advance time slightly differently
           currentSecondsInRound += increment;
           if (currentSecondsInRound >= roundTimeSeconds) break; // Stop if round time exceeded

           String timeString = _formatSecondsToTimeString(currentSecondsInRound); // <<< Use Helper
          await insertMessage( 'RedBoxer', 'BlueBoxer', i.toString(), timeString,
            (_random.nextInt(400) + 250).toString(), round1_1, matchIds[0],
          ); messagesInserted++;
        }
      }

      // ---> Messages for Round 2 of Match 1 (roundTime = 180s) <---
      if (round2_2 > 0 && insertedMatchesDetails.length >= 2) {
         final matchDetails = insertedMatchesDetails.firstWhere((m) => m['id'] == matchIds[1]);
         int roundTimeSeconds = matchDetails['roundTime'] as int;
         int currentSecondsInRound = 0; // Start time for this round
         debugPrint("Inserting messages for round2_2 (Match 1), Round Time: $roundTimeSeconds seconds");

        int bluePunchCount = 20 + _random.nextInt(15);
        for (int i = 1; i <= bluePunchCount; i++) {
           int increment = 1 + _random.nextInt(4);
           currentSecondsInRound += increment;
           if (currentSecondsInRound >= roundTimeSeconds) break;
           String timeString = _formatSecondsToTimeString(currentSecondsInRound); // <<< Use Helper
          await insertMessage( 'BlueBoxer', 'RedBoxer', i.toString(), timeString,
             (_random.nextInt(600) + 350).toString(), round2_2, matchIds[1],
          ); messagesInserted++;
        }

        int redPunchCount = 25 + _random.nextInt(10);
        for (int i = 1; i <= redPunchCount; i++) {
            int increment = 1 + _random.nextInt(5);
            currentSecondsInRound += increment;
            if (currentSecondsInRound >= roundTimeSeconds) break;
            String timeString = _formatSecondsToTimeString(currentSecondsInRound); // <<< Use Helper
          await insertMessage( 'RedBoxer', 'BlueBoxer', i.toString(), timeString,
             (_random.nextInt(550) + 400).toString(), round2_2, matchIds[1],
          ); messagesInserted++;
        }
      }

      // ---> Messages for Round 1 of Short Round Match (Match 2, roundTime = 60s) <---
      if (shortR1 > 0 && insertedMatchesDetails.length >= 3) {
           final matchDetails = insertedMatchesDetails.firstWhere((m) => m['id'] == matchIds[2]);
           int roundTimeSeconds = matchDetails['roundTime'] as int; // Should be 60
           int currentSecondsInRound = 0; // Start time for this round
           debugPrint("Inserting messages for shortR1 (Match 2), Round Time: $roundTimeSeconds seconds");

            int bluePunchCount = 8 + _random.nextInt(7);
            for (int i = 1; i <= bluePunchCount; i++) {
              int increment = 1 + _random.nextInt(3); // Smaller increments
              currentSecondsInRound += increment;
              if (currentSecondsInRound >= roundTimeSeconds) break;
              String timeString = _formatSecondsToTimeString(currentSecondsInRound); // <<< Use Helper
              await insertMessage('BlueBoxer', 'RedBoxer', i.toString(), timeString,
                (_random.nextInt(400) + 200).toString(), shortR1, matchIds[2],
              ); messagesInserted++;
           }

           int redPunchCount = 7 + _random.nextInt(8);
           for (int i = 1; i <= redPunchCount; i++) {
               int increment = 1 + _random.nextInt(4);
               currentSecondsInRound += increment;
               if (currentSecondsInRound >= roundTimeSeconds) break;
               String timeString = _formatSecondsToTimeString(currentSecondsInRound); // <<< Use Helper
              await insertMessage('RedBoxer', 'BlueBoxer', i.toString(), timeString,
                (_random.nextInt(350) + 250).toString(), shortR1, matchIds[2],
              ); messagesInserted++;
           }
      }


       // ---> Messages for Round 3 of Match 3 (Endurance Test, roundTime = 180s) <---
      if (round3_3 > 0 && insertedMatchesDetails.length >= 4) {
         final matchDetails = insertedMatchesDetails.firstWhere((m) => m['id'] == matchIds[3]);
         int roundTimeSeconds = matchDetails['roundTime'] as int;
         int currentSecondsInRound = 0; // Start time for this round
         debugPrint("Inserting messages for round3_3 (Match 3), Round Time: $roundTimeSeconds seconds");

         int bluePunchCount = 18 + _random.nextInt(12);
         for (int i = 1; i <= bluePunchCount; i++) {
             int increment = 1 + _random.nextInt(5);
             currentSecondsInRound += increment;
             if (currentSecondsInRound >= roundTimeSeconds) break;
             String timeString = _formatSecondsToTimeString(currentSecondsInRound); // <<< Use Helper
            await insertMessage( 'BlueBoxer', 'RedBoxer', i.toString(), timeString,
              (_random.nextInt(500) + 320).toString(), round3_3, matchIds[3],
            ); messagesInserted++;
         }

          int redPunchCount = 16 + _random.nextInt(10);
          for (int i = 1; i <= redPunchCount; i++) {
              int increment = 1 + _random.nextInt(6);
              currentSecondsInRound += increment;
              if (currentSecondsInRound >= roundTimeSeconds) break;
              String timeString = _formatSecondsToTimeString(currentSecondsInRound); // <<< Use Helper
             await insertMessage( 'RedBoxer', 'BlueBoxer', i.toString(), timeString,
               (_random.nextInt(520) + 380).toString(), round3_3, matchIds[3],
             ); messagesInserted++;
          }
      }
      debugPrint("Inserted $messagesInserted sample messages.");


      // 5. Insert Sample Training Data (Timestamp remains fully random HH:MM:SS)
      int trainingDataInserted = 0;
      for (int i = 0; i < 50; i++) {
        String device = _random.nextBool() ? 'BlueBoxer' : 'RedBoxer';
        String punchBy = device == 'BlueBoxer' ? 'RedBoxer' : 'BlueBoxer';
         // Keep timestamp fully random (00:00:00 to 23:59:59) for training data
         String timeString = "${_random.nextInt(24).toString().padLeft(2, '0')}:${_random.nextInt(60).toString().padLeft(2, '0')}:${_random.nextInt(60).toString().padLeft(2, '0')}";
        await insertTrainingData(
          device, punchBy, (i + 1).toString(), timeString,
          (_random.nextInt(800) + 100).toString(),
        );
        trainingDataInserted++;
      }
      debugPrint("Inserted $trainingDataInserted sample training data records.");


      debugPrint("Comprehensive sample data insertion COMPLETE.");

    } catch (e, stacktrace) {
       debugPrint("Error inserting sample data: $e");
       debugPrint("Stacktrace: $stacktrace");
    }
  }


  // --- METHOD SIGNATURES AND UTILITY METHODS --- (No changes needed below this line)
  // Messages
  Future<void> insertMessage( String device, String oppositeDevice, String punchCount, String timestamp, String sensorValue, int roundId, int matchId, ) async { final db = await database; await db.insert('messages', { 'device': device, 'punchBy': oppositeDevice, 'punchCount': punchCount, 'timestamp': timestamp, 'sensorValue': sensorValue, 'roundId': roundId, 'matchId': matchId, }); }
  Future<List<Map<String, dynamic>>> fetchMessages() async { final db = await database; return await db.query('messages', orderBy: 'id DESC'); }
  Future<List<Map<String, dynamic>>> fetchMessagesByMatchId(int matchId) async { final db = await database; return await db.query('messages', where: 'matchId = ?', whereArgs: [matchId], orderBy: 'id DESC'); }
  Future<List<Map<String, dynamic>>> fetchMessagesByRoundId(int roundId) async { final db = await database; return await db.query('messages', where: 'roundId = ?', whereArgs: [roundId], orderBy: 'id DESC'); }
  Future<void> clearMessages() async { final db = await database; await db.delete('messages'); debugPrint("Cleared messages table."); }
  // Training Data
  Future<void> insertTrainingData( String device, String punchBy, String punchCount, String timestamp, String sensorValue, ) async { final db = await database; await db.insert('trainingdata', { 'device': device, 'punchBy': punchBy, 'punchCount': punchCount, 'timestamp': timestamp, 'sensorValue': sensorValue, }); }
  Future<List<Map<String, dynamic>>> fetchTrainingData() async { final db = await database; return await db.query('trainingdata', orderBy: 'id DESC');}
  Future<void> clearTrainingData() async { final db = await database; await db.delete('trainingdata'); debugPrint("Cleared trainingdata table.");}
  // Settings
  Future<void> upsertSettings({ required int fsrSensitivity, required int fsrThreshold, required int rounds, required int roundTime, required int breakTime, required int secondsBeforeRoundBegins, }) async { final db = await database; await db.insert('settings', { 'id': 1, 'fsrSensitivity': fsrSensitivity, 'fsrThreshold': fsrThreshold, 'rounds': rounds, 'roundTime': roundTime, 'breakTime': breakTime, 'secondsBeforeRoundBegins': secondsBeforeRoundBegins, }, conflictAlgorithm: ConflictAlgorithm.replace, ); debugPrint("Settings upserted."); }
  Future<Map<String, dynamic>?> fetchSettings() async { final db = await database; final List<Map<String, dynamic>> settings = await db.query( 'settings', where: 'id = ?', whereArgs: [1], limit: 1, ); if (settings.isNotEmpty) { return settings.first; } else { debugPrint("Warning: Settings not found, returning null."); return null; } }
  Future<void> clearSettings() async { final db = await database; await _insertDefaultSettings(db); debugPrint("Settings reset to default."); }
  // Matches
  Future<int> insertMatch({ required String matchName, required int rounds, required String matchDate, required int roundTime, required int breakTime, }) async { final db = await database; final Map<String, dynamic> matchData = { 'matchName': matchName, 'rounds': rounds, 'matchDate': matchDate, 'roundTime': roundTime, 'breakTime': breakTime, 'finishedAtRound': 0, 'totalTime': '00:00', }; final id = await db.insert('matches', matchData); debugPrint("Inserted match with ID: $id"); return id; }
  Future<void> updateEditMatch({ required int id, required String matchName, required String matchDate, required int rounds, required int finishedAtRound, required String totalTime, required int roundTime, required int breakTime, }) async { final db = await database; await db.update( 'matches', { 'matchName': matchName, 'matchDate': matchDate, 'rounds': rounds, 'finishedAtRound': finishedAtRound, 'totalTime': totalTime, 'roundTime': roundTime, 'breakTime': breakTime, }, where: 'id = ?', whereArgs: [id], ); debugPrint("Updated match with ID: $id"); }
  Future<List<Map<String, dynamic>>> fetchMatches() async { final db = await database; return await db.query('matches', orderBy: 'id ASC'); }
  Future<void> deleteMatch(int id) async { final db = await database; int count = await db.delete('matches', where: 'id = ?', whereArgs: [id]); if (count > 0) { debugPrint("Deleted match with ID: $id and related data."); } else { debugPrint("Match with ID: $id not found for deletion."); } }
  Future<Map<String, dynamic>?> fetchMatchById(int id) async { final db = await database; final result = await db.query( 'matches', where: 'id = ?', whereArgs: [id], limit: 1, ); return result.isNotEmpty ? result.first : null; }
  Future<void> clearMatches() async { final db = await database; await db.delete('matches'); debugPrint("Cleared matches table and related data."); }
  Future<void> insertSampleMatchesOnly() async { debugPrint("Inserting sample matches ONLY..."); List<Map<String, dynamic>> sampleMatches = [ { 'matchName': 'Basic 1', 'rounds': 1, 'matchDate': '2025-01-01', 'roundTime': 60, 'breakTime': 10 }, { 'matchName': 'Basic 2', 'rounds': 3, 'matchDate': '2025-01-02', 'roundTime': 180, 'breakTime': 60 }, ]; int count = 0; for (var match in sampleMatches) { await insertMatch( matchName: match['matchName'], rounds: match['rounds'], matchDate: match['matchDate'], roundTime: match['roundTime'], breakTime: match['breakTime']); count++; } debugPrint("Inserted $count sample matches only."); }
  // Events
   Future<String> insertEvent({required int matchId, String? winner}) async { final db = await database; String eventId = _uuid.v4(); await db.insert('events', { 'id': eventId, 'timestamp': DateTime.now().millisecondsSinceEpoch, 'matchId': matchId, 'winner': winner, }); debugPrint("Inserted event $eventId for Match ID $matchId"); return eventId; }
   Future<List<Map<String, dynamic>>> fetchEvents() async { final db = await database; return await db.query('events', orderBy: 'timestamp DESC'); }
   Future<List<Map<String, dynamic>>> fetchEventsByMatchId(int matchId) async { final db = await database; return await db.query( 'events', where: 'matchId = ?', whereArgs: [matchId], orderBy: 'timestamp DESC', ); }
   Future<void> clearEvents() async { final db = await database; await db.delete('events'); debugPrint("Cleared events table."); }
   Future<void> updateCurrentEventWinner(String eventId, String? winner) async { final db = await database; await db.update( 'events', {'winner': winner}, where: 'id = ?', whereArgs: [eventId], ); debugPrint("Updated winner for event $eventId"); }
  // Rounds
  Future<int> insertRound({ required int matchId, required int round, required String? eventId, }) async { final db = await database; final roundData = { 'matchId': matchId, 'round': round, 'eventId': eventId, 'timestamp': DateTime.now().millisecondsSinceEpoch, }; int id = 0; try { id = await db.insert('rounds', roundData); debugPrint("Inserted round $round for Event $eventId, Round ID: $id"); } on DatabaseException catch (e) { if (e.isUniqueConstraintError()) { debugPrint("Error: Round $round for Event $eventId already exists."); } else { debugPrint("Database error inserting round: $e"); } } return id; }
  Future<List<Map<String, dynamic>>> fetchRounds() async { final db = await database; List<Map<String, dynamic>> rounds = await db.query( 'rounds', orderBy: 'id DESC', ); return rounds.map((round) { final timestamp = round['timestamp']; String humanReadableTimestamp = "N/A"; if (timestamp != null && timestamp is int) { try { var date = DateTime.fromMillisecondsSinceEpoch(timestamp); humanReadableTimestamp = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}"; } catch (e) { debugPrint("Error formatting timestamp $timestamp: $e"); } } var mutableRound = Map<String, dynamic>.from(round); mutableRound['humanReadableTimestamp'] = humanReadableTimestamp; return mutableRound; }).toList(); }
  Future<void> clearRounds() async { final db = await database; await db.delete('rounds'); debugPrint("Cleared rounds table."); }
  // Utilities
  Future<Map<String, int>> getEventPunchCounts(String eventId) async { final db = await database; final eventRounds = await db.query( 'rounds', columns: ['id'], where: 'eventId = ?', whereArgs: [eventId] ); if (eventRounds.isEmpty) { return {'BlueBoxer': 0, 'RedBoxer': 0}; } final roundIds = eventRounds.map((r) => r['id'] as int).toList(); final messages = await db.query( 'messages', columns: ['punchBy'], where: 'roundId IN (${List.filled(roundIds.length, '?').join(',')})', whereArgs: roundIds ); int blue = 0; int red = 0; for (final msg in messages) { final who = msg['punchBy'] as String?; if (who == 'BlueBoxer') { blue++; } else if (who == 'RedBoxer') { red++; } } return {'BlueBoxer': blue, 'RedBoxer': red}; }
  Future<Map<String, int>> getRoundPunchCounts(int roundId) async { final db = await database; final messages = await db.query( 'messages', columns: ['punchBy'], where: 'roundId = ?', whereArgs: [roundId], ); int blue = 0; int red = 0; for (final msg in messages) { final who = msg['punchBy'] as String?; if (who == 'BlueBoxer') { blue++; } else if (who == 'RedBoxer') { red++; } } return {'BlueBoxer': blue, 'RedBoxer': red}; }

} // End of DatabaseHelper class


































// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:uuid/uuid.dart'; // Import the uuid package

// // 1) Add a small helper function to check if a column exists.
// Future<bool> _columnExists(Database db, String table, String columnName) async {
//   final columns = await db.rawQuery('PRAGMA table_info($table)');
//   for (final col in columns) {
//     if (col['name'] == columnName) {
//       return true;
//     }
//   }
//   return false;
// }

// class DatabaseHelper {
//   // Singleton instance
//   static final DatabaseHelper _instance = DatabaseHelper._internal();
//   static Database? _database;
//   String currentDateTime =
//       DateTime.now().toIso8601String(); // e.g., "2024-06-08T12:45:00.000"

//   // Private constructor
//   DatabaseHelper._internal();

//   // Factory constructor to return the same instance
//   factory DatabaseHelper() => _instance;

//   // Getter to access the database
//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     _database = await _initDatabase();
//     return _database!;
//   }

//   // Initialize the database
//   Future<Database> _initDatabase() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final path = join(directory.path, 'messages.db'); // Path to database file

//     return await openDatabase(
//       path,
//       // Bump version to 7 so onUpgrade gets called if user is on an older DB
//       version: 7,
//       onOpen: (db) async {
//         // Ensure foreign keys are enabled every time the database is opened
//         await db.execute("PRAGMA foreign_keys = ON");
//       },
//       onCreate: (db, version) async {
//         await db.execute("PRAGMA foreign_keys = ON");

//         // Create 'matches' table without the winner field
//         await db.execute(''' 
//           CREATE TABLE matches(
//             id INTEGER PRIMARY KEY AUTOINCREMENT,            
//             matchName TEXT,
//             matchDate TEXT,
//             rounds INTEGER,
//             finishedAtRound INTEGER,
//             totalTime TEXT,
//             roundTime INTEGER,
//             breakTime INTEGER
//           )
//         ''');

//         // Create 'events' table with an additional winner field
//         await db.execute(''' 
//           CREATE TABLE events(
//             id TEXT PRIMARY KEY,            
//             timestamp INTEGER,
//             matchId INTEGER,
//             winner TEXT,
//             FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE
//           )
//         ''');

//         // Create 'rounds' table
//         await db.execute(''' 
//           CREATE TABLE rounds(
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             eventId TEXT,
//             punchCount INTEGER,
//             matchId INTEGER,
//             round INTEGER,                    
//             timestamp INTEGER,
//             FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE,
//             FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE,
//             UNIQUE(eventId, round)    -- ← here’s the uniqueness constraint
//           )
//         ''');

//         // Create 'messages' table
//         await db.execute(''' 
//           CREATE TABLE messages(
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             device TEXT,
//             punchBy TEXT,
//             punchCount TEXT,
//             timestamp TEXT,
//             sensorValue TEXT,
//             roundId INTEGER,
//             matchId INTEGER,
//             FOREIGN KEY (roundId) REFERENCES rounds(id) ON DELETE CASCADE,
//             FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE
//           )
//         ''');

//         // Create 'trainingdata' table exactly similar to 'messages' but without the foreign key constraint
//         await db.execute(''' 
//           CREATE TABLE trainingdata(
//             id INTEGER PRIMARY KEY AUTOINCREMENT,
//             device TEXT,
//             punchBy TEXT,
//             punchCount TEXT,
//             timestamp TEXT,
//             sensorValue TEXT,
//             roundId INTEGER
//           )
//         ''');

//         // Create 'settings' table with all columns including 'rounds'
//         await db.execute(''' 
//           CREATE TABLE settings(
//             id INTEGER PRIMARY KEY,
//             fsrSensitivity INTEGER,
//             fsrThreshold INTEGER,
//             roundTime INTEGER,
//             breakTime INTEGER,
//             secondsBeforeRoundBegins INTEGER,
//             rounds INTEGER
//           )
//         ''');

//         // Insert default settings row with id=1 (including default 'rounds')
//         await db.insert('settings', {
//           'id': 1,
//           'fsrSensitivity': 800,
//           'fsrThreshold': 200,
//           'roundTime': 3,
//           'breakTime': 120,
//           'secondsBeforeRoundBegins': 5,
//           'rounds': 3,
//         });
//       },
//       onUpgrade: (db, oldVersion, newVersion) async {
//         // Original if block for oldVersion < 4:
//         if (oldVersion < 4) {
//           // 2) Check if 'device' column already exists before adding it
//           final hasDevice = await _columnExists(db, 'messages', 'device');
//           if (!hasDevice) {
//             await db.execute('ALTER TABLE messages ADD COLUMN device TEXT');
//           }
//         }

//         // If user was on version 4 or lower, add the missing columns:
//         if (oldVersion < 5) {
//           // 3) Check if each column already exists before adding
//           final hasFsrThreshold = await _columnExists(
//             db,
//             'settings',
//             'fsrThreshold',
//           );
//           if (!hasFsrThreshold) {
//             await db.execute(
//               'ALTER TABLE settings ADD COLUMN fsrThreshold INTEGER DEFAULT 200',
//             );
//           }

//           final hasRoundTime = await _columnExists(db, 'settings', 'roundTime');
//           if (!hasRoundTime) {
//             await db.execute(
//               'ALTER TABLE settings ADD COLUMN roundTime INTEGER DEFAULT 3',
//             );
//           }

//           final hasBreakTime = await _columnExists(db, 'settings', 'breakTime');
//           if (!hasBreakTime) {
//             await db.execute(
//               'ALTER TABLE settings ADD COLUMN breakTime INTEGER DEFAULT 120',
//             );
//           }
//         }

//         // If user was on version 5 or lower, add the new 'punchBy' column.
//         if (oldVersion < 6) {
//           final hasPunchBy = await _columnExists(db, 'messages', 'punchBy');
//           if (!hasPunchBy) {
//             await db.execute('ALTER TABLE messages ADD COLUMN punchBy TEXT');
//           }
//         }

//         // Now for version < 7, add the new 'rounds' column to settings if needed
//         if (oldVersion < 7) {
//           final hasRounds = await _columnExists(db, 'settings', 'rounds');
//           if (!hasRounds) {
//             await db.execute(
//               'ALTER TABLE settings ADD COLUMN rounds INTEGER DEFAULT 3',
//             );
//           }
//         }
//       },
//     );
//   }

//   // ------------------- Messages Table Methods -------------------
//   /// Inserts a new message into the 'messages' table.
//   Future<void> insertMessage(
//     String device,
//     oppositeDevice,
//     String punchCount,
//     String timestamp,
//     String sensorValue,
//     roundId,
//     matchId,
//   ) async {
//     final db = await database;
//     await db.insert('messages', {
//       'device': device,
//       'punchBy': oppositeDevice,
//       'punchCount': punchCount,
//       'timestamp': timestamp,
//       'sensorValue': sensorValue,
//       'roundId': roundId,
//       'matchId': matchId,
//     });
//   }

//   /// Fetches all messages from the 'messages' table, ordered by descending ID.
//   Future<List<Map<String, dynamic>>> fetchMessages() async {
//     final db = await database;
//     return await db.query('messages', orderBy: 'id DESC');
//   }

//   /// Fetches all messages from the 'messages' table based on a specific matchId.
//   Future<List<Map<String, dynamic>>> fetchMessagesByMatchId(int matchId) async {
//     final db = await database;
//     return await db.query(
//       'messages',
//       where: 'matchId = ?',
//       whereArgs: [matchId],
//       orderBy: 'id DESC',
//     );
//   }

//   /// Fetches all messages from the 'messages' table based on a specific roundId.
//   Future<List<Map<String, dynamic>>> fetchMessagesByRoundId(int roundId) async {
//     final db = await database;
//     return await db.query(
//       'messages',
//       where: 'roundId = ?',
//       whereArgs: [roundId],
//       orderBy: 'id DESC',
//     );
//   }

//   /// Clears all messages from the 'messages' table.
//   Future<void> clearMessages() async {
//     final db = await database;
//     await db.delete('messages');
//   }

//   // ------------------- Trainingdata Table Methods -------------------
//   /// Inserts a new record into the 'trainingdata' table.
//   Future<void> insertTrainingData(
//     String device,
//     oppositeDevice,
//     String punchCount,
//     String timestamp,
//     String sensorValue,
//   ) async {
//     final db = await database;
//     await db.insert('trainingdata', {
//       'device': device,
//       'punchBy': oppositeDevice,
//       'punchCount': punchCount,
//       'timestamp': timestamp,
//       'sensorValue': sensorValue,
//     });
//   }

//   /// Deletes a match from the 'matches' table by ID.
//   /// This will also delete all related rounds and messages due to foreign key constraints.
//   Future<void> deleteMatch(int id) async {
//     final db = await database;
//     await db.delete('matches', where: 'id = ?', whereArgs: [id]);
//   }

//   /// Fetches all records from the 'trainingdata' table, ordered by descending ID.
//   Future<List<Map<String, dynamic>>> fetchTrainingData() async {
//     final db = await database;
//     return await db.query('trainingdata', orderBy: 'id DESC');
//   }

//   /// Clears all records from the 'trainingdata' table.
//   Future<void> clearTrainingData() async {
//     final db = await database;
//     await db.delete('trainingdata');
//   }

//   // ------------------- Settings Table Methods -------------------
//   /// Inserts or updates settings in the 'settings' table.
//   /// Ensures only one row exists with id=1.
//   Future<void> upsertSettings({
//     required int fsrSensitivity,
//     required int fsrThreshold,
//     required int rounds,
//     required int roundTime,
//     required int breakTime,
//     required int secondsBeforeRoundBegins,
//   }) async {
//     final db = await database;

//     // Update the settings row where id=1
//     int count = await db.update(
//       'settings',
//       {
//         'fsrSensitivity': fsrSensitivity,
//         'fsrThreshold': fsrThreshold,
//         'rounds': rounds, // NEW field for rounds
//         'roundTime': roundTime,
//         'breakTime': breakTime,
//         'secondsBeforeRoundBegins': secondsBeforeRoundBegins,
//       },
//       where: 'id = ?',
//       whereArgs: [1],
//     );

//     if (count == 0) {
//       // If no row was updated, insert a new row with id=1
//       await db.insert('settings', {
//         'id': 1,
//         'fsrSensitivity': fsrSensitivity,
//         'fsrThreshold': fsrThreshold,
//         'rounds': rounds, // Insert rounds
//         'roundTime': roundTime,
//         'breakTime': breakTime,
//         'secondsBeforeRoundBegins': secondsBeforeRoundBegins,
//       });
//     }
//   }

//   /// Fetches settings from the 'settings' table.
//   /// Returns a map of settings if found, otherwise null.
//   Future<Map<String, dynamic>?> fetchSettings() async {
//     final db = await database;
//     final List<Map<String, dynamic>> settings = await db.query(
//       'settings',
//       where: 'id = ?',
//       whereArgs: [1],
//     );

//     if (settings.isNotEmpty) {
//       return settings.first;
//     } else {
//       return null; // No settings found
//     }
//   }

//   /// Clears the settings from the 'settings' table by deleting the row with id=1.
//   Future<void> clearSettings() async {
//     final db = await database;
//     await db.delete('settings', where: 'id = ?', whereArgs: [1]);
//   }

//   // ------------------- Matches Table Methods -------------------
//   /// Inserts a new match into the 'matches' table.
//   Future<void> insertMatch({
//     required String matchName,
//     required int rounds,
//     required String matchDate,
//     required int roundTime,
//     required int breakTime,
//   }) async {
//     final db = await database;
//     await db.insert('matches', {
//       'matchName': matchName,
//       'rounds': rounds,
//       'matchDate': matchDate,
//       'roundTime': roundTime,
//       'breakTime': breakTime,
//     });
//   }

//   /// Updates a match and its associated winner in the events table.
//   Future<void> updateEditMatch({
//     required String matchName,
//     required String matchDate,
//     required int rounds,
//     required int finishedAtRound,
//     required String totalTime,
//     required int roundTime,
//     required int breakTime,
//     required int id, // match ID
//   }) async {
//     final db = await database;

//     // Update the match (removed 'winner' from matches update)
//     await db.update(
//       'matches', // Table name
//       {
//         'matchName': matchName,
//         'matchDate': matchDate,
//         'rounds': rounds,
//         'finishedAtRound': finishedAtRound,
//         'totalTime': totalTime,
//         'roundTime': roundTime,
//         'breakTime': breakTime,
//       },
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//   }

//   /// Fetches all matches from the 'matches' table, ordered by descending ID.
//   Future<List<Map<String, dynamic>>> fetchMatches() async {
//     final db = await database;
//     return await db.query(
//       'matches',
//       orderBy: 'id ASC',
//     ); // Order by ID descending 'id DESC' 'id ASC'
//   }

//   /// Clears all matches from the 'matches' table.
//   Future<void> clearMatches() async {
//     final db = await database;
//     await db.delete('matches');
//   }

//   Future<void> insertSampleMatches() async {
//     final db = await database;

//     // List of sample matches with winner field.
//     List<Map<String, dynamic>> sampleMatches = [
//       {
//         'matchName': '1 Round Practice Match',
//         'matchDate': '2025-03-20',
//         'rounds': 1,
//         'finishedAtRound': 0,
//         'totalTime': '00:00',
//         'roundTime': 1,
//         'breakTime': 10,
//       },
//       {
//         'matchName': '2 Rounds Practice Match',
//         'matchDate': '2024-11-20',
//         'rounds': 2,
//         'finishedAtRound': 0,
//         'totalTime': '00:00',
//         'roundTime': 1,
//         'breakTime': 10,
//       },
//       {
//         'matchName': '5 Rounds Practice Match',
//         'matchDate': '2024-11-20',
//         'rounds': 5,
//         'finishedAtRound': 0,
//         'totalTime': '00:00',
//         'roundTime': 3,
//         'breakTime': 120,
//       },
//       {
//         'matchName': 'Test Quick Match',
//         'matchDate': '2025-03-07',
//         'rounds': 2,
//         'finishedAtRound': 0,
//         'totalTime': '00:00',
//         'roundTime': 1,
//         'breakTime': 10,
//       },
//       {
//         'matchName': 'Championship Match',
//         'matchDate': '2024-11-28',
//         'rounds': 12,
//         'finishedAtRound': 0,
//         'totalTime': '00:00',
//         'roundTime': 3,
//         'breakTime': 120,
//       },
//       {
//         'matchName': 'BlueBoxer vs RedBoxer',
//         'matchDate': '2025-03-07',
//         'rounds': 3,
//         'finishedAtRound': 0,
//         'totalTime': '00:00',
//         'roundTime': 3,
//         'breakTime': 120,
//       },
//       {
//         'matchName': 'Themis vs Nick',
//         'matchDate': '2025-03-07',
//         'rounds': 5,
//         'finishedAtRound': 0,
//         'totalTime': '00:00',
//         'roundTime': 3,
//         'breakTime': 120,
//       },
//       {
//         'matchName': 'Themis vs Panos',
//         'matchDate': '2024-11-25',
//         'rounds': 7,
//         'finishedAtRound': 0,
//         'totalTime': '00:00',
//         'roundTime': 3,
//         'breakTime': 120,
//       },
//     ];

//     // Insert each sample match without handling a winner.
//     for (var match in sampleMatches) {
//       await db.insert('matches', match);
//     }
//   }

//   // ------------------- Event Table Methods -------------------
//   /// Inserts a new event into the 'events' table and returns the generated UUID.
//   /// Now accepts an optional winner parameter.
//   Future<String> insertEvent({required int matchId, String? winner}) async {
//     final db = await database;
//     var uuid = Uuid();
//     String eventId = uuid.v4();
//     await db.insert('events', {
//       'id': eventId,
//       'timestamp': DateTime.now().millisecondsSinceEpoch,
//       'matchId': matchId,
//       'winner': winner ?? '',
//     });
//     return eventId;
//   }

//   /// Fetches **all** events from the 'events' table, ordered by descending timestamp.
//   Future<List<Map<String, dynamic>>> fetchEvents() async {
//     final db = await database;
//     return await db.query('events', orderBy: 'timestamp DESC');
//   }

//   /// NEW: Fetch only events for a specific match.
//   Future<List<Map<String, dynamic>>> fetchEventsByMatchId(int matchId) async {
//     final db = await database;
//     return await db.query(
//       'events',
//       where: 'matchId = ?',
//       whereArgs: [matchId],
//       orderBy: 'timestamp DESC',
//     );
//   }

//   /// Clears all events from the 'events' table.
//   Future<void> clearEvents() async {
//     final db = await database;
//     await db.delete('events');
//   }

//   Future<void> updateCurrentEventWinner(String eventId, String winner) async {
//     final db = await database;
//     await db.update(
//       'events',
//       {'winner': winner},
//       where: 'id = ?',
//       whereArgs: [eventId],
//     );
//   }

//   // ------------------- Round Table Methods -------------------
//   /// Inserts a new row into the 'rounds' table.
//   Future<int> insertRound({
//     required int matchId,
//     required int round,
//     required String? eventId,
//   }) async {
//     final db = await database;
//     return await db.insert('rounds', {
//       'matchId': matchId,
//       'round': round,
//       'eventId': eventId,
//       'timestamp':
//           DateTime.now().millisecondsSinceEpoch, // Store as Unix timestamp
//     });
//   }

//   Future<List<Map<String, dynamic>>> fetchRounds() async {
//     final db = await database;
//     List<Map<String, dynamic>> rounds = await db.query(
//       'rounds',
//       orderBy: 'id DESC',
//     );
//     return rounds.map((round) {
//       var date = DateTime.fromMillisecondsSinceEpoch(round['timestamp'] as int);
//       // Create a mutable copy of the round map.
//       var mutableRound = Map<String, dynamic>.from(round);
//       mutableRound['humanReadableTimestamp'] =
//           "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}:${date.second}";
//       return mutableRound;
//     }).toList();
//   }

//   /// Clears all matches from the 'rounds' table.
//   Future<void> clearRounds() async {
//     final db = await database;
//     await db.delete('rounds');
//   }

//   /// NEW: Fetch a single match by its ID. Returns null if not found.
//   Future<Map<String, dynamic>?> fetchMatchById(int id) async {
//     final db = await database;
//     final result = await db.query(
//       'matches',
//       where: 'id = ?',
//       whereArgs: [id],
//       limit: 1,
//     );
//     if (result.isNotEmpty) {
//       return result.first;
//     }
//     return null;
//   }

//   /// Returns a map of total punches per boxer for the given eventId
//   /// by doing the work in Dart rather than a single raw SQL query.
//   Future<Map<String, int>> getEventPunchCounts(String eventId) async {
//     // 1️⃣ fetch all rounds, then filter to just this event
//     final allRounds = await fetchRounds();
//     final myRounds = allRounds.where((r) => r['eventId'] == eventId).toList();

//     // 2️⃣ walk every message in each round and tally by punchBy
//     int blue = 0, red = 0;
//     for (final round in myRounds) {
//       // ✔️ cast the round id to int, not String
//       final roundId = round['id'] as int;
//       final messages = await fetchMessagesByRoundId(roundId);
//       for (final msg in messages) {
//         final who = msg['punchBy'] as String?;
//         if (who == 'BlueBoxer') {
//           blue++;
//         } else if (who == 'RedBoxer') {
//           red++;
//         }
//       }
//     }

//     return {'BlueBoxer': blue, 'RedBoxer': red};
//   }
// }
