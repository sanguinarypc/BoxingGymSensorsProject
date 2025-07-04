// lib/services/database_helper.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // Import the uuid package
// import 'package:flutter/foundation.dart';

class DatabaseHelper {
  // The filename of the on-device SQLite database:
  // static const _dbName = 'messages.db';
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  String currentDateTime =
      DateTime.now().toIso8601String(); // e.g., "2024-06-08T12:45:00.000"

  // Private constructor
  DatabaseHelper._internal();

  // Factory constructor to return the same instance
  factory DatabaseHelper() => _instance;

  // Getter to access the database
  Future<Database> get database async {
    // Έλεγξε αν η βάση υπάρχει ΚΑΙ είναι ανοιχτή
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    // Αλλιώς, αρχικοποίησε (ή ξανα-αρχικοποίησε) τη βάση
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'messages.db'); // Path to database file

    return await openDatabase(
      path,
      // Bump version to 7 so onUpgrade gets called if user is on an older DB
      version: 1,
      onOpen: (db) async {
        // Ensure foreign keys are enabled every time the database is opened
        await db.execute("PRAGMA foreign_keys = ON");
      },
      onCreate: (db, version) async {
        await db.execute("PRAGMA foreign_keys = ON");

        // Create 'matches' table without the winner field
        await db.execute(''' 
          CREATE TABLE matches(
            id INTEGER PRIMARY KEY AUTOINCREMENT,            
            matchName TEXT,
            matchDate TEXT,
            rounds INTEGER,
            finishedAtRound INTEGER,
            totalTime TEXT,
            roundTime INTEGER,
            breakTime INTEGER
          )
        ''');

        // Create 'events' table with an additional winner field
        await db.execute(''' 
          CREATE TABLE events(
            id TEXT PRIMARY KEY,            
            timestamp INTEGER,
            matchId INTEGER,
            winner TEXT,
            FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE
          )
        ''');

        // Create 'rounds' table
        await db.execute(''' 
          CREATE TABLE rounds(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            eventId TEXT,
            punchCount INTEGER,
            matchId INTEGER,
            round INTEGER,                    
            timestamp INTEGER,
            FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE,
            FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE,
            UNIQUE(eventId, round)    -- ← here’s the uniqueness constraint
          )
        ''');

        // Create 'messages' table
        await db.execute(''' 
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device TEXT,
            punchBy TEXT,
            punchCount TEXT,
            timestamp TEXT,
            sensorValue TEXT,
            roundId INTEGER,
            matchId INTEGER,
            FOREIGN KEY (roundId) REFERENCES rounds(id) ON DELETE CASCADE,
            FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE
          )
        ''');

        // Create 'settings' table with all columns including 'rounds'
        await db.execute(''' 
          CREATE TABLE settings(
            id INTEGER PRIMARY KEY,
            fsrSensitivity INTEGER,
            fsrThreshold INTEGER,
            roundTime INTEGER,
            breakTime INTEGER,
            secondsBeforeRoundBegins INTEGER,
            rounds INTEGER
          )
        ''');

        // Insert default settings row with id=1 (including default 'rounds')
        await db.insert('settings', {
          'id': 1,
          'fsrSensitivity': 800,
          'fsrThreshold': 200,
          'roundTime': 3,
          'breakTime': 120,
          'secondsBeforeRoundBegins': 5,
          'rounds': 3,
        });
      },
    );
  }

  /// Closes the underlying sqlite database.
  Future<void> close() async {
    final db = _database;
    // Έλεγξε αν η βάση υπάρχει ΚΑΙ είναι ανοιχτή πριν την κλείσεις
    if (db != null && db.isOpen) {
      await db.close();
      _database = null; // Σημαντικό για να ξανα-αρχικοποιηθεί από τον getter
    } else if (db != null && !db.isOpen) {
      // Αν η βάση υπάρχει αλλά είναι ήδη κλειστή, απλά σιγουρέψου ότι το _database είναι null
      _database = null;
    }
    // Αν το db είναι null, δεν χρειάζεται να κάνουμε τίποτα
  }

  // ------------------- Messages Table Methods -------------------
  /// Inserts a new message into the 'messages' table.
  Future<void> insertMessage(
    String device,
    oppositeDevice,
    String punchCount,
    String timestamp,
    String sensorValue,
    roundId,
    matchId,
  ) async {
    final db = await database;
    await db.insert('messages', {
      'device': device,
      'punchBy': oppositeDevice,
      'punchCount': punchCount,
      'timestamp': timestamp,
      'sensorValue': sensorValue,
      'roundId': roundId,
      'matchId': matchId,
    });
  }

  /// Fetches all messages from the 'messages' table, ordered by descending ID.
  Future<List<Map<String, dynamic>>> fetchMessages() async {
    final db = await database;
    return await db.query('messages', orderBy: 'id DESC');
  }

  /// Fetches all messages from the 'messages' table based on a specific matchId.
  Future<List<Map<String, dynamic>>> fetchMessagesByMatchId(int matchId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'matchId = ?',
      whereArgs: [matchId],
      orderBy: 'id DESC',
    );
  }

  /// Fetches all messages from the 'messages' table based on a specific roundId.
  Future<List<Map<String, dynamic>>> fetchMessagesByRoundId(int roundId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'roundId = ?',
      whereArgs: [roundId],
      orderBy: 'id DESC',
    );
  }

  /// Clears all messages from the 'messages' table.
  Future<void> clearMessages() async {
    final db = await database;
    await db.delete('messages');
  }

  /// Deletes a match from the 'matches' table by ID.
  /// This will also delete all related rounds and messages due to foreign key constraints.
  Future<void> deleteMatch(int id) async {
    final db = await database;
    await db.delete('matches', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------- Settings Table Methods -------------------
  /// Inserts or updates settings in the 'settings' table.
  /// Ensures only one row exists with id=1.
  Future<void> upsertSettings({
    required int fsrSensitivity,
    required int fsrThreshold,
    required int rounds,
    required int roundTime,
    required int breakTime,
    required int secondsBeforeRoundBegins,
  }) async {
    final db = await database;

    // Update the settings row where id=1
    int count = await db.update(
      'settings',
      {
        'fsrSensitivity': fsrSensitivity,
        'fsrThreshold': fsrThreshold,
        'rounds': rounds, // NEW field for rounds
        'roundTime': roundTime,
        'breakTime': breakTime,
        'secondsBeforeRoundBegins': secondsBeforeRoundBegins,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    if (count == 0) {
      // If no row was updated, insert a new row with id=1
      await db.insert('settings', {
        'id': 1,
        'fsrSensitivity': fsrSensitivity,
        'fsrThreshold': fsrThreshold,
        'rounds': rounds, // Insert rounds
        'roundTime': roundTime,
        'breakTime': breakTime,
        'secondsBeforeRoundBegins': secondsBeforeRoundBegins,
      });
    }
  }

  /// Fetches settings from the 'settings' table.
  /// Returns a map of settings if found, otherwise null.
  Future<Map<String, dynamic>?> fetchSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> settings = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (settings.isNotEmpty) {
      return settings.first;
    } else {
      return null; // No settings found
    }
  }

  /// Clears the settings from the 'settings' table by deleting the row with id=1.
  Future<void> clearSettings() async {
    final db = await database;
    await db.delete('settings', where: 'id = ?', whereArgs: [1]);
  }

  // ------------------- Matches Table Methods -------------------
  /// Inserts a new match into the 'matches' table.
  Future<void> insertMatch({
    required String matchName,
    required int rounds,
    required String matchDate,
    required int roundTime,
    required int breakTime,
  }) async {
    final db = await database;
    await db.insert('matches', {
      'matchName': matchName,
      'rounds': rounds,
      'matchDate': matchDate,
      'roundTime': roundTime,
      'breakTime': breakTime,
    });
  }

  /// Updates a match and its associated winner in the events table.
  Future<void> updateEditMatch({
    required String matchName,
    required String matchDate,
    required int rounds,
    required int finishedAtRound,
    required String totalTime,
    required int roundTime,
    required int breakTime,
    required int id, // match ID
  }) async {
    final db = await database;

    // Update the match (removed 'winner' from matches update)
    await db.update(
      'matches', // Table name
      {
        'matchName': matchName,
        'matchDate': matchDate,
        'rounds': rounds,
        'finishedAtRound': finishedAtRound,
        'totalTime': totalTime,
        'roundTime': roundTime,
        'breakTime': breakTime,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Fetches all matches from the 'matches' table, ordered by descending ID.
  Future<List<Map<String, dynamic>>> fetchMatches() async {
    final db = await database;
    return await db.query(
      'matches',
      orderBy: 'id ASC',
    ); // Order by ID descending 'id DESC' 'id ASC'
  }

  /// Clears all matches from the 'matches' table.
  Future<void> clearMatches() async {
    final db = await database;
    await db.delete('matches');
  }

  Future<void> insertSampleMatches() async {
    final db = await database;

    // List of sample matches with winner field.
    List<Map<String, dynamic>> sampleMatches = [
      {
        'matchName': '1 Round Practice Match',
        'matchDate': '2025-03-20',
        'rounds': 1,
        'finishedAtRound': 0,
        'totalTime': '00:00',
        'roundTime': 1,
        'breakTime': 10,
      },
      {
        'matchName': '2 Rounds Practice Match',
        'matchDate': '2024-11-20',
        'rounds': 2,
        'finishedAtRound': 0,
        'totalTime': '00:00',
        'roundTime': 1,
        'breakTime': 10,
      },
      {
        'matchName': '5 Rounds Practice Match',
        'matchDate': '2024-11-20',
        'rounds': 5,
        'finishedAtRound': 0,
        'totalTime': '00:00',
        'roundTime': 3,
        'breakTime': 120,
      },
      {
        'matchName': 'Test Quick Match',
        'matchDate': '2025-03-07',
        'rounds': 2,
        'finishedAtRound': 0,
        'totalTime': '00:00',
        'roundTime': 1,
        'breakTime': 10,
      },
      {
        'matchName': 'Championship Match',
        'matchDate': '2024-11-28',
        'rounds': 12,
        'finishedAtRound': 0,
        'totalTime': '00:00',
        'roundTime': 3,
        'breakTime': 120,
      },
      {
        'matchName': 'BlueBoxer vs RedBoxer',
        'matchDate': '2025-03-07',
        'rounds': 3,
        'finishedAtRound': 0,
        'totalTime': '00:00',
        'roundTime': 3,
        'breakTime': 120,
      },
      {
        'matchName': 'Themis vs Nick',
        'matchDate': '2025-03-07',
        'rounds': 5,
        'finishedAtRound': 0,
        'totalTime': '00:00',
        'roundTime': 3,
        'breakTime': 120,
      },
      {
        'matchName': 'Themis vs Panos',
        'matchDate': '2024-11-25',
        'rounds': 7,
        'finishedAtRound': 0,
        'totalTime': '00:00',
        'roundTime': 3,
        'breakTime': 120,
      },
    ];

    // Insert each sample match without handling a winner.
    for (var match in sampleMatches) {
      await db.insert('matches', match);
    }
  }

  // ------------------- Event Table Methods -------------------
  /// Inserts a new event into the 'events' table and returns the generated UUID.
  /// Now accepts an optional winner parameter.
  Future<String> insertEvent({required int matchId, String? winner}) async {
    final db = await database;
    var uuid = Uuid();
    String eventId = uuid.v4();
    await db.insert('events', {
      'id': eventId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'matchId': matchId,
      'winner': winner ?? '',
    });
    return eventId;
  }

  /// Fetches **all** events from the 'events' table, ordered by descending timestamp.
  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final db = await database;
    return await db.query('events', orderBy: 'timestamp DESC');
  }

  /// NEW: Fetch only events for a specific match.
  Future<List<Map<String, dynamic>>> fetchEventsByMatchId(int matchId) async {
    final db = await database;
    return await db.query(
      'events',
      where: 'matchId = ?',
      whereArgs: [matchId],
      orderBy: 'timestamp DESC',
    );
  }

  /// Clears all events from the 'events' table.
  Future<void> clearEvents() async {
    final db = await database;
    await db.delete('events');
  }

  Future<void> updateCurrentEventWinner(String eventId, String winner) async {
    final db = await database;
    await db.update(
      'events',
      {'winner': winner},
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  // ------------------- Round Table Methods -------------------
  /// Inserts a new row into the 'rounds' table.
  Future<int> insertRound({
    required int matchId,
    required int round,
    required String? eventId,
  }) async {
    final db = await database;
    return await db.insert('rounds', {
      'matchId': matchId,
      'round': round,
      'eventId': eventId,
      'timestamp':
          DateTime.now().millisecondsSinceEpoch, // Store as Unix timestamp
    });
  }

  Future<List<Map<String, dynamic>>> fetchRounds() async {
    final db = await database;
    List<Map<String, dynamic>> rounds = await db.query(
      'rounds',
      orderBy: 'id DESC',
    );
    return rounds.map((round) {
      var date = DateTime.fromMillisecondsSinceEpoch(round['timestamp'] as int);
      // Create a mutable copy of the round map.
      var mutableRound = Map<String, dynamic>.from(round);
      mutableRound['humanReadableTimestamp'] =
          "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}:${date.second}";
      return mutableRound;
    }).toList();
  }

  /// Clears all matches from the 'rounds' table.
  Future<void> clearRounds() async {
    final db = await database;
    await db.delete('rounds');
  }

  /// NEW: Fetch a single match by its ID. Returns null if not found.
  Future<Map<String, dynamic>?> fetchMatchById(int id) async {
    final db = await database;
    final result = await db.query(
      'matches',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  /// Returns a map of total punches per boxer for the given eventId
  /// by doing the work in Dart rather than a single raw SQL query.
  Future<Map<String, int>> getEventPunchCounts(String eventId) async {
    // 1️⃣ fetch all rounds, then filter to just this event
    final allRounds = await fetchRounds();
    final myRounds = allRounds.where((r) => r['eventId'] == eventId).toList();

    // 2️⃣ walk every message in each round and tally by punchBy
    int blue = 0, red = 0;
    for (final round in myRounds) {
      // ✔️ cast the round id to int, not String
      final roundId = round['id'] as int;
      final messages = await fetchMessagesByRoundId(roundId);
      for (final msg in messages) {
        final who = msg['punchBy'] as String?;
        if (who == 'BlueBoxer') {
          blue++;
        } else if (who == 'RedBoxer') {
          red++;
        }
      }
    }

    return {'BlueBoxer': blue, 'RedBoxer': red};
  }

  Future<String?> exportDatabaseToFile(String fileName) async {
    try {
      final db = await database;
      final originalFile = File(db.path);
      if (!await originalFile.exists()) {
        throw Exception('Local DB not found at ${db.path}');
      }

      final tempDir = await getTemporaryDirectory();
      final exportPath = join(tempDir.path, fileName);

      await originalFile.copy(exportPath);
      return exportPath;
    } catch (e) {
      // Μπορείς να κάνεις και debugPrint('Export DB error: $e');
      rethrow; // αφήνεις τον UI κώδικά σου να το πιάσει
    }
  }
}
