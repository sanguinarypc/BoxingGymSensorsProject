// lib/services/database_helper.dart
import 'dart:io'; // Provides File and Directory classes for working with the file system.
import 'package:sqflite/sqflite.dart'; // The sqflite plugin for SQLite database interaction.
import 'package:path/path.dart'; // Provides utilities for manipulating file paths.
import 'package:path_provider/path_provider.dart'; // Plugin for finding commonly used locations on the filesystem.
import 'package:uuid/uuid.dart'; // Plugin for generating UUIDs (Universally Unique Identifiers).
import 'package:box_sensors/utils/device_config.dart';

// Helper class for managing SQLite database operations.
// Implements a singleton pattern to ensure only one instance handles the database.
class DatabaseHelper {
  // The filename of the on-device SQLite database: 'messages.db'
  // Defines the constant name for the database file.

  // Singleton instance of DatabaseHelper.
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  // Static Database object, lazily initialized.
  static Database? _database;
  // Stores the current date and time in ISO 8601 format. (Note: this value is set once at class initialization and does not update automatically afterwards)
  String currentDateTime = DateTime.now()
      .toIso8601String(); // e.g., "2024-06-08T12:45:00.000"

  // Private internal constructor for the singleton pattern.
  DatabaseHelper._internal();

  // Factory constructor that returns the singleton instance.
  factory DatabaseHelper() => _instance;

  // Public getter for the database instance.
  // Initializes the database if it hasn't been already or if it was closed.
  Future<Database> get database async {
    // Check if the database instance exists and is currently open.
    if (_database != null && _database!.isOpen) {
      return _database!; // Return the existing open database.
    }
    // If not, initialize (or re-initialize) the database.
    _database = await _initDatabase();
    return _database!; // Return the newly initialized database.
  }

  // Initializes the SQLite database.
  // Creates the database file and the necessary tables if they don't exist.
  Future<Database> _initDatabase() async {
    // Get the application's documents directory where the database file will be stored.
    final directory = await getApplicationDocumentsDirectory();
    // Construct the full path to the database file using the 'join' utility from the path package.
    final path = join(directory.path, 'messages.db'); // Path to database file

    // Open the database at the specified path.
    return await openDatabase(
      path,
      // Set the database version. Used for schema migrations if the schema changes in future versions.
      version: 2,
      // Callback executed when the database is opened.
      onOpen: (db) async {
        // Ensure foreign key constraints are enabled every time the database is opened.
        // This is crucial for maintaining relational integrity.
        await db.execute("PRAGMA foreign_keys = ON");
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add webServerUrl column to settings table
          // Default valid is DeviceConfig.webServerUrl
          await db.execute(
            "ALTER TABLE settings ADD COLUMN webServerUrl TEXT DEFAULT '${DeviceConfig.webServerUrl}'",
          );
        }
      },
      // Callback executed only when the database is first created (i.e., the db file doesn't exist).
      onCreate: (db, version) async {
        // Enable foreign key constraints upon creation as well.
        await db.execute("PRAGMA foreign_keys = ON");

        // Create the 'matches' table to store information about each match.
        await db.execute(''' 
          CREATE TABLE matches(
            id INTEGER PRIMARY KEY AUTOINCREMENT,        /* Unique identifier for each match */
            matchName TEXT,                            /* User-defined name for the match */
            matchDate TEXT,                            /* Date the match occurred or is scheduled */
            rounds INTEGER,                            /* Total number of rounds planned for the match */
            finishedAtRound INTEGER,                   /* The round number at which the match actually finished (if not all rounds were completed) */
            totalTime TEXT,                            /* Total duration of the match (e.g., "HH:MM:SS") */
            roundTime INTEGER,                         /* Duration of each round in seconds or minutes */
            breakTime INTEGER                          /* Duration of break time between rounds in seconds */
          )
        ''');

        // Create the 'events' table to store event details, linked to matches.
        // An event typically represents a single instance of a boxing match being conducted.
        await db.execute(''' 
          CREATE TABLE events(
            id TEXT PRIMARY KEY,                       /* Unique UUID for each event session */           
            timestamp INTEGER,                         /* Timestamp (milliseconds since epoch) when the event was created/started */
            matchId INTEGER,                           /* Foreign key referencing the 'matches' table */
            winner TEXT,                               /* Name or identifier of the winner of this event/match session */
            FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE /* If a match is deleted, corresponding events are also deleted */
          )
        ''');

        // Create the 'rounds' table to store details for each round within an event.
        await db.execute(''' 
          CREATE TABLE rounds(
            id INTEGER PRIMARY KEY AUTOINCREMENT,      /* Unique identifier for each round record */
            eventId TEXT,                              /* Foreign key referencing the 'events' table */
            punchCount INTEGER,                        /* Aggregate punch count for this round (may be updated later) */
            matchId INTEGER,                           /* Foreign key referencing the 'matches' table (denormalized for easier queries, or could be derived via eventId) */
            round INTEGER,                             /* The sequential number of the round (e.g., 1, 2, 3) */                     
            timestamp INTEGER,                         /* Timestamp (milliseconds since epoch) when this round's data was recorded or the round started */
            FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE,
            FOREIGN KEY (eventId) REFERENCES events(id) ON DELETE CASCADE,
            UNIQUE(eventId, round)                     /* Ensures that for any given event, each round number is unique */
          )
        ''');

        // Create the 'messages' table to store individual punch/sensor data received during a match.
        await db.execute(''' 
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,      /* Unique identifier for each message/punch */
            device TEXT,                               /* Identifier of the device that sent the message (e.g., DeviceConfig.blueBoxer, DeviceConfig.redBoxer) */
            punchBy TEXT,                              /* Identifier of the boxer who was punched (e.g., DeviceConfig.redBoxer, DeviceConfig.blueBoxer) */
            punchCount TEXT,                           /* Punch count at the time of this message (could be cumulative for the device or round) */
            timestamp TEXT,                            /* Timestamp of the message/punch, often from the device */
            sensorValue TEXT,                          /* Raw sensor value associated with the punch/event */
            roundId INTEGER,                           /* Foreign key linking to the 'rounds' table */
            matchId INTEGER,                           /* Foreign key linking to the 'matches' table */
            FOREIGN KEY (roundId) REFERENCES rounds(id) ON DELETE CASCADE,
            FOREIGN KEY (matchId) REFERENCES matches(id) ON DELETE CASCADE
          )
        ''');

        // Create the 'settings' table to store application-wide configurations.
        await db.execute(''' 
          CREATE TABLE settings(
            id INTEGER PRIMARY KEY,                    /* Primary key, should always be 1 for the single settings row */
            fsrSensitivity INTEGER,                    /* FSR (Force Sensitive Resistor) sensitivity setting */
            fsrThreshold INTEGER,                      /* FSR threshold for detecting a valid punch */
            roundTime INTEGER,                         /* Default duration of a round (e.g., in seconds or minutes) */
            breakTime INTEGER,                         /* Default duration of a break between rounds (e.g., in seconds) */
            secondsBeforeRoundBegins INTEGER,          /* Countdown time before a round officially begins */
            rounds INTEGER,                            /* Default number of rounds for a match */
            webServerUrl TEXT                          /* Dashboard Web Server URL */
          )
        ''');

        // Insert a default row of settings with ID=1 into the 'settings' table upon database creation.
        await db.insert('settings', {
          'id': 1,
          'fsrSensitivity': 800,
          'fsrThreshold': 200,
          'roundTime': 3, // Example: 3 minutes per round
          'breakTime': 120, // Example: 120 seconds (2 minutes) break
          'secondsBeforeRoundBegins': 5,
          'rounds': 3, // Default to 3 rounds
          'webServerUrl': DeviceConfig.webServerUrl,
        });
      },
    );
  }

  /// Closes the underlying SQLite database.
  // It's important to close the database when it's no longer needed to free resources.
  Future<void> close() async {
    final db = _database; // Get the current database instance.
    // Check if the database instance exists and is currently open.
    if (db != null && db.isOpen) {
      await db.close(); // Close the database.
      _database =
          null; // Set to null so it can be re-initialized by the getter if needed.
    } else if (db != null && !db.isOpen) {
      // If the database object exists but is already closed, just ensure _database is null for consistency.
      _database = null;
    }
    // If db is null, there's nothing to do.
  }

  // ------------------- Messages Table Methods -------------------
  /// Inserts a new message into the 'messages' table.
  // Each message typically represents a punch event or sensor reading from a device.
  Future<void> insertMessage(
    String
    device, // Name of the device sending the data (e.g., DeviceConfig.blueBoxer).
    oppositeDevice, // Name of the device/boxer being punched (e.g., DeviceConfig.redBoxer). Implicitly dynamic.
    String punchCount, // Current punch count string as reported by the device.
    String timestamp, // Timestamp of the message, usually from the device.
    String sensorValue, // Sensor reading string.
    roundId, // ID of the round this message belongs to. Implicitly dynamic.
    matchId, // ID of the match this message belongs to. Implicitly dynamic.
  ) async {
    final db = await database; // Get a reference to the database.
    // Insert the new message record into the 'messages' table.
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

  /// Fetches all messages from the 'messages' table, ordered by descending ID (newest messages first).
  Future<List<Map<String, dynamic>>> fetchMessages() async {
    final db = await database; // Get a reference to the database.
    // Query the 'messages' table, ordering by 'id' in descending order.
    return await db.query('messages', orderBy: 'id DESC');
  }

  /// Fetches all messages from the 'messages' table for a specific `matchId`, ordered by descending ID.
  Future<List<Map<String, dynamic>>> fetchMessagesByMatchId(int matchId) async {
    final db = await database; // Get a reference to the database.
    // Query the 'messages' table with a WHERE clause for the given matchId.
    return await db.query(
      'messages',
      where: 'matchId = ?', // SQL placeholder for matchId.
      whereArgs: [matchId], // Arguments for the WHERE clause.
      orderBy: 'id DESC', // Order results by ID, newest first.
    );
  }

  /// Fetches all messages from the 'messages' table for a specific `roundId`, ordered by descending ID.
  Future<List<Map<String, dynamic>>> fetchMessagesByRoundId(int roundId) async {
    final db = await database; // Get a reference to the database.
    // Query the 'messages' table with a WHERE clause for the given roundId.
    return await db.query(
      'messages',
      where: 'roundId = ?', // SQL placeholder for roundId.
      whereArgs: [roundId], // Arguments for the WHERE clause.
      orderBy: 'id DESC', // Order results by ID, newest first.
    );
  }

  /// Clears all messages from the 'messages' table.
  Future<void> clearMessages() async {
    final db = await database; // Get a reference to the database.
    // Delete all records from the 'messages' table.
    await db.delete('messages');
  }

  /// Deletes a match from the 'matches' table by its ID.
  /// Due to 'ON DELETE CASCADE' foreign key constraints, this will also delete:
  /// - All associated events from the 'events' table.
  /// - All associated rounds from the 'rounds' table.
  /// - All associated messages from the 'messages' table that reference this match or its rounds/events.
  Future<void> deleteMatch(int id) async {
    final db = await database; // Get a reference to the database.
    // Delete the match with the specified ID from the 'matches' table.
    await db.delete('matches', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------- Settings Table Methods -------------------
  /// Inserts or updates settings in the 'settings' table.
  /// This method uses an "upsert" logic: it tries to update the existing settings row (id=1),
  /// and if it doesn't exist (e.g., first run or after clearing settings), it inserts a new row.
  Future<void> upsertSettings({
    required int fsrSensitivity, // FSR sensitivity value.
    required int fsrThreshold, // FSR threshold value.
    required int rounds, // Number of rounds.
    required int roundTime, // Duration of each round.
    required int breakTime, // Duration of breaks between rounds.
    required int
    secondsBeforeRoundBegins, // Countdown duration before a round starts.
    required String webServerUrl, // NEW: Web Server URL
  }) async {
    final db = await database; // Get a reference to the database.

    // Attempt to update the settings row where id=1.
    int count = await db.update(
      'settings', // Table name.
      {
        // Data to update.
        'fsrSensitivity': fsrSensitivity,
        'fsrThreshold': fsrThreshold,
        'rounds': rounds,
        'roundTime': roundTime,
        'breakTime': breakTime,
        'secondsBeforeRoundBegins': secondsBeforeRoundBegins,
        'webServerUrl': webServerUrl,
      },
      where: 'id = ?', // Condition for the update: target the row with id=1.
      whereArgs: [1], // Argument for the condition.
    );

    // If no row was updated (i.e., count is 0, meaning no row with id=1 existed), insert a new one.
    if (count == 0) {
      await db.insert('settings', {
        'id': 1, // Explicitly set id to 1 for the new settings row.
        'fsrSensitivity': fsrSensitivity,
        'fsrThreshold': fsrThreshold,
        'rounds': rounds, // Ensure 'rounds' is included in the insert.
        'roundTime': roundTime,
        'breakTime': breakTime,
        'secondsBeforeRoundBegins': secondsBeforeRoundBegins,
        'webServerUrl': webServerUrl,
      });
    }
  }

  /// Fetches settings from the 'settings' table.
  /// Returns a map representing the settings if found (should be the row with id=1), otherwise null.
  Future<Map<String, dynamic>?> fetchSettings() async {
    final db = await database; // Get a reference to the database.
    // Query the 'settings' table for the row with id=1.
    final List<Map<String, dynamic>> settings = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
    );

    // If settings are found (list is not empty), return the first (and presumably only) row.
    if (settings.isNotEmpty) {
      return settings.first;
    } else {
      return null; // No settings found, which might indicate an issue or that they were cleared.
    }
  }

  /// Clears the settings from the 'settings' table by deleting the row with id=1.
  /// This might be used to reset settings to a default state if the application re-inserts defaults.
  Future<void> clearSettings() async {
    final db = await database; // Get a reference to the database.
    // Delete the settings row with id=1.
    await db.delete('settings', where: 'id = ?', whereArgs: [1]);
  }

  // ------------------- Matches Table Methods -------------------
  /// Inserts a new match into the 'matches' table with provided details.
  Future<void> insertMatch({
    required String matchName, // Name for the new match.
    required int rounds, // Number of rounds for this match.
    required String matchDate, // Date of the match.
    required int roundTime, // Duration of each round for this match.
    required int breakTime, // Duration of breaks for this match.
  }) async {
    final db = await database; // Get a reference to the database.
    // Insert the new match record into the 'matches' table.
    await db.insert('matches', {
      'matchName': matchName,
      'rounds': rounds,
      'matchDate': matchDate,
      'roundTime': roundTime,
      'breakTime': breakTime,
    });
  }

  /// Updates an existing match's details in the 'matches' table.
  /// This is used, for example, when editing match parameters or recording its outcome.
  Future<void> updateEditMatch({
    required String matchName,
    required String matchDate,
    required int rounds,
    required int
    finishedAtRound, // The round number at which the match concluded.
    required String
    totalTime, // Total duration of the match (e.g., formatted string).
    required int roundTime,
    required int breakTime,
    required int id, // The ID of the match to be updated.
  }) async {
    final db = await database; // Get a reference to the database.

    // Update the specified match record in the 'matches' table.
    await db.update(
      'matches', // Table name.
      {
        // Data to update.
        'matchName': matchName,
        'matchDate': matchDate,
        'rounds': rounds,
        'finishedAtRound': finishedAtRound,
        'totalTime': totalTime,
        'roundTime': roundTime,
        'breakTime': breakTime,
      },
      where:
          'id = ?', // Condition for the update: target the row with the given id.
      whereArgs: [id], // Argument for the condition.
    );
  }

  /// Fetches all matches from the 'matches' table, ordered by ascending ID (oldest matches first).
  Future<List<Map<String, dynamic>>> fetchMatches() async {
    final db = await database; // Get a reference to the database.
    // Query all records from 'matches', ordered by 'id' ascending.
    return await db.query(
      'matches',
      orderBy:
          'id ASC', // Order by ID ascending. Could be 'id DESC' for newest first.
    );
  }

  /// Clears all matches from the 'matches' table.
  /// Note: This will also trigger cascading deletes for related events, rounds, and messages
  /// due to the 'ON DELETE CASCADE' foreign key constraints defined in the schema.
  Future<void> clearMatches() async {
    final db = await database; // Get a reference to the database.
    // Delete all records from the 'matches' table.
    await db.delete('matches');
  }

  // Inserts a predefined list of sample matches into the database.
  // Useful for testing, development, or providing initial data.
  Future<void> insertSampleMatches() async {
    final db = await database; // Get a reference to the database.

    // A list of maps, where each map represents a sample match's data.
    List<Map<String, dynamic>> sampleMatches = [
      {
        'matchName': '1 Round Practice Match',
        'matchDate': '2025-03-20',
        'rounds': 1,
        'finishedAtRound':
            0, // Default/placeholder, can be updated when match concludes.
        'totalTime': '00:00', // Default/placeholder.
        'roundTime': 1, // Example: 1 unit of time (e.g., minute).
        'breakTime': 10, // Example: 10 units of time (e.g., seconds).
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

    // Iterate through the list of sample matches and insert each one into the 'matches' table.
    for (var match in sampleMatches) {
      await db.insert('matches', match);
    }
  }

  // ------------------- Event Table Methods -------------------
  /// Inserts a new event into the 'events' table and returns the generated UUID for the event.
  /// An event is typically created at the start of a match session to group all rounds and data for that session.
  /// Accepts an optional `winner` parameter, which can be null.
  Future<String> insertEvent({required int matchId, String? winner}) async {
    final db = await database; // Get a reference to the database.
    var uuid = Uuid(); // Create a Uuid generator instance.
    String eventId = uuid
        .v4(); // Generate a new v4 (random) UUID for the event ID.
    // Insert the new event record into the 'events' table.
    await db.insert('events', {
      'id': eventId, // The generated UUID as the primary key.
      'timestamp': DateTime.now()
          .millisecondsSinceEpoch, // Current time as milliseconds since epoch.
      'matchId': matchId, // The ID of the match this event belongs to.
      'winner':
          winner ??
          '', // Store the winner's name, or an empty string if winner is null.
    });
    return eventId; // Return the generated event ID so it can be used to link rounds.
  }

  /// Fetches **all** events from the 'events' table, ordered by descending timestamp (newest events first).
  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final db = await database; // Get a reference to the database.
    // Query all records from 'events', ordered by 'timestamp' in descending order.
    return await db.query('events', orderBy: 'timestamp DESC');
  }

  /// Fetches only events associated with a specific `matchId`, ordered by descending timestamp.
  Future<List<Map<String, dynamic>>> fetchEventsByMatchId(int matchId) async {
    final db = await database; // Get a reference to the database.
    // Query the 'events' table with a WHERE clause for the given matchId.
    return await db.query(
      'events',
      where: 'matchId = ?', // SQL placeholder for matchId.
      whereArgs: [matchId], // Argument for the placeholder.
      orderBy: 'timestamp DESC', // Order newest events first.
    );
  }

  /// Clears all events from the 'events' table.
  /// Note: This will also trigger cascading deletes for related rounds if 'ON DELETE CASCADE'
  /// is correctly set for the 'eventId' foreign key in the 'rounds' table.
  Future<void> clearEvents() async {
    final db = await database; // Get a reference to the database.
    // Delete all records from the 'events' table.
    await db.delete('events');
  }

  // Updates the 'winner' field for a specific event identified by `eventId`.
  Future<void> updateCurrentEventWinner(String eventId, String winner) async {
    final db = await database; // Get a reference to the database.
    // Update the 'winner' field for the event with the given 'eventId'.
    await db.update(
      'events', // Table name.
      {'winner': winner}, // Data to update: only the winner field.
      where:
          'id = ?', // Condition for the update: target the row with the given eventId.
      whereArgs: [eventId], // Argument for the condition.
    );
  }

  // ------------------- Round Table Methods -------------------
  /// Inserts a new row into the 'rounds' table, representing a single round within a match/event.
  /// Returns the ID of the newly inserted round.
  Future<int> insertRound({
    required int matchId, // ID of the parent match.
    required int round, // The round number (e.g., 1, 2, 3).
    required String?
    eventId, // ID of the parent event; can be null if rounds are not directly tied to events in some contexts.
  }) async {
    final db = await database; // Get a reference to the database.
    // Insert the new round record.
    return await db.insert('rounds', {
      'matchId': matchId,
      'round': round,
      'eventId': eventId,
      'timestamp': DateTime.now()
          .millisecondsSinceEpoch, // Store current time as Unix timestamp (milliseconds since epoch).
    });
  }

  // Fetches all rounds from the 'rounds' table, ordered by descending ID (newest rounds first).
  // It also converts the stored integer timestamp for each round into a human-readable string format.
  Future<List<Map<String, dynamic>>> fetchRounds() async {
    final db = await database; // Get a reference to the database.
    // Query all records from 'rounds', ordered by 'id' in descending order.
    List<Map<String, dynamic>> rounds = await db.query(
      'rounds',
      orderBy: 'id DESC',
    );
    // Map over the results to add a 'humanReadableTimestamp' field to each round.
    return rounds.map((round) {
      // Convert the integer timestamp (milliseconds since epoch) to a DateTime object.
      var date = DateTime.fromMillisecondsSinceEpoch(round['timestamp'] as int);
      // Create a mutable copy of the round map to allow adding a new key-value pair.
      var mutableRound = Map<String, dynamic>.from(round);
      // Add the formatted human-readable timestamp string.
      mutableRound['humanReadableTimestamp'] =
          "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}:${date.second}";
      return mutableRound; // Return the modified map.
    }).toList(); // Convert the iterable of maps back to a list.
  }

  /// Clears all rounds from the 'rounds' table.
  /// Note: This will also trigger cascading deletes for related messages if 'ON DELETE CASCADE'
  /// is correctly set for the 'roundId' foreign key in the 'messages' table.
  Future<void> clearRounds() async {
    final db = await database; // Get a reference to the database.
    // Delete all records from the 'rounds' table.
    await db.delete('rounds');
  }

  /// Fetches a single match from the 'matches' table by its unique ID.
  /// Returns a map representing the match if found, otherwise returns null.
  Future<Map<String, dynamic>?> fetchMatchById(int id) async {
    final db = await database; // Get a reference to the database.
    // Query the 'matches' table for a specific ID, limiting the result to 1 row.
    final result = await db.query(
      'matches',
      where: 'id = ?', // SQL placeholder for the ID.
      whereArgs: [id], // Argument for the placeholder.
      limit: 1, // Ensure only one row is returned at most.
    );
    // If a result is found (the list is not empty), return the first (and only) map.
    if (result.isNotEmpty) {
      return result.first;
    }
    return null; // Otherwise, if no match is found with that ID, return null.
  }

  /// Calculates and returns a map of total punches per boxer for a given `eventId`.
  /// This method performs the aggregation in Dart by:
  /// 1. Fetching all rounds.
  /// 2. Filtering rounds by the given `eventId`.
  /// 3. For each of these rounds, fetching all associated messages.
  /// 4. Iterating through messages and tallying counts based on the 'punchBy' field.
  /// Note: The interpretation of 'punchBy' is critical. If 'punchBy' is who RECEIVED the punch,
  /// this counts punches received. If the intention is to count punches THROWN by each boxer,
  /// the logic might need to consider the 'device' field or an inverse relation.
  /// The current implementation counts based on the 'punchBy' field as it appears in the data.
  Future<Map<String, int>> getEventPunchCounts(String eventId) async {
    // 1️⃣ Fetch all rounds from the database, then filter them to get only rounds belonging to the specified eventId.
    final allRounds =
        await fetchRounds(); // Assumes fetchRounds() gets all rounds from the DB.
    final myRounds = allRounds.where((r) => r['eventId'] == eventId).toList();

    // 2️⃣ Initialize punch counters for BlueBoxer and RedBoxer.
    //    Iterate through each round of the event.
    //    For each round, fetch all associated messages.
    //    For each message, identify the 'punchBy' value (who received the punch) and increment the respective counter.
    int blue = 0, red = 0; // Initialize counters.
    for (final round in myRounds) {
      // ✔️ Ensure 'id' from the round map is correctly cast to 'int' for `fetchMessagesByRoundId`.
      final roundId = round['id'] as int;
      final messages = await fetchMessagesByRoundId(
        roundId,
      ); // Fetch messages for the current round.
      for (final msg in messages) {
        final who =
            msg['punchBy']
                as String?; // Get the value of 'punchBy' from the message.
        if (who == DeviceConfig.blueBoxer) {
          // If 'punchBy' is DeviceConfig.blueBoxer, increment 'blue' counter.
          blue++;
        } else if (who == DeviceConfig.redBoxer) {
          // If 'punchBy' is DeviceConfig.redBoxer, increment 'red' counter.
          red++;
        }
      }
    }
    // Returns a map with the aggregated counts for DeviceConfig.blueBoxer and DeviceConfig.redBoxer based on the 'punchBy' field.
    return {DeviceConfig.blueBoxer: blue, DeviceConfig.redBoxer: red};
  }

  // Exports the current SQLite database to a file with the given `fileName` in a temporary directory.
  // This can be used for backups or sharing the database file.
  // Returns the path to the exported file if successful, otherwise rethrows the error.
  Future<String?> exportDatabaseToFile(String fileName) async {
    try {
      final db =
          await database; // Ensure the database is initialized and get its instance.
      final originalFile = File(
        db.path,
      ); // Create a File object for the current database path.

      // Check if the original database file actually exists at the expected path.
      if (!await originalFile.exists()) {
        // If the database file doesn't exist, throw an exception.
        throw Exception('Local DB not found at ${db.path}');
      }

      // Get the system's temporary directory for storing the exported file.
      final tempDir = await getTemporaryDirectory();
      // Construct the full path for the exported database file within the temporary directory.
      final exportPath = join(tempDir.path, fileName);

      // Copy the original database file to the new export path.
      await originalFile.copy(exportPath);
      return exportPath; // Return the path of the successfully exported file.
    } catch (e) {
      // Optionally, one could log the error here for debugging, e.g.:
      // debugPrint('Export DB error: $e');
      rethrow; // Rethrow the caught exception to let the calling code handle it (e.g., display an error message to the user).
    }
  }
}





























// // lib/services/database_helper.dart
// import 'dart:io';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:uuid/uuid.dart';

// class DatabaseHelper {
//   // The filename of the on-device SQLite database: 'messages.db'
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
//     // Check if the database exists and is open
//     if (_database != null && _database!.isOpen) {
//       return _database!;
//     }
//     // Otherwise, initialize (or re-initialize) the database
//     _database = await _initDatabase();
//     return _database!;
//   }

//   // Initialize the database
//   Future<Database> _initDatabase() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final path = join(directory.path, 'messages.db'); // Path to database file

//     return await openDatabase(
//       path,
//       // Set version to 1
//       version: 1,
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
//     );
//   }

//   /// Closes the underlying sqlite database.
//   Future<void> close() async {
//     final db = _database;
//     // Check if the database exists and is open before closing it
//     if (db != null && db.isOpen) {
//       await db.close();
//       _database = null; // Important to be re-initialized by the getter
//     } else if (db != null && !db.isOpen) {
//       // If the database exists but is already closed, just make sure _database is null
//       _database = null;
//     }
    
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

//   /// Deletes a match from the 'matches' table by ID.
//   /// This will also delete all related rounds and messages due to foreign key constraints.
//   Future<void> deleteMatch(int id) async {
//     final db = await database;
//     await db.delete('matches', where: 'id = ?', whereArgs: [id]);
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
//         'rounds': rounds,
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

//   /// Fetch only events for a specific match.
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

//   /// Fetch a single match by its ID. Returns null if not found.
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
//         if (who == DeviceConfig.blueBoxer) {
//           blue++;
//         } else if (who == DeviceConfig.redBoxer) {
//           red++;
//         }
//       }
//     }

//     return {DeviceConfig.blueBoxer: blue, DeviceConfig.redBoxer: red};
//   }

//   Future<String?> exportDatabaseToFile(String fileName) async {
//     try {
//       final db = await database;
//       final originalFile = File(db.path);
//       if (!await originalFile.exists()) {
//         throw Exception('Local DB not found at ${db.path}');
//       }

//       final tempDir = await getTemporaryDirectory();
//       final exportPath = join(tempDir.path, fileName);

//       await originalFile.copy(exportPath);
//       return exportPath;
//     } catch (e) {
//       // You can also do debugPrint('Export DB error: $e');
//       rethrow; // you let your UI code handle it
//     }
//   }
// }
