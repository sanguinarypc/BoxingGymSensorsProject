// lib/screens/rounds_of_match_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/widgets/display_row.dart';
import 'package:box_sensors/widgets/match_data_table.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class RoundsOfMatchScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> match;
  final String eventId;

  const RoundsOfMatchScreen({
    super.key,
    required this.match,
    required this.eventId,
  });

  @override
  ConsumerState<RoundsOfMatchScreen> createState() =>
      _RoundsOfMatchScreenState();
}

class _RoundsOfMatchScreenState extends ConsumerState<RoundsOfMatchScreen> {
  late final DatabaseHelper dbHelper;
  List<Map<String, dynamic>> roundsList = [];
  Map<String, dynamic>? selectedRound;
  Future<List<Map<String, dynamic>>>? _futureMessages;

  @override
  void initState() {
    super.initState();
    dbHelper = ref.read(databaseHelperProvider);
    _loadRounds();
  }

  Future<void> _loadRounds() async {
    try {
      final allRounds = await dbHelper.fetchRounds();
      if (!mounted) return;
      final filtered =
          allRounds
              .where(
                (r) =>
                    r['matchId'] == widget.match['id'] &&
                    r['eventId'] == widget.eventId,
              )
              .toList()
            ..sort((a, b) => (a['round'] as int).compareTo(b['round'] as int));

      setState(() {
        roundsList = filtered;
        selectedRound = filtered.isNotEmpty ? filtered.first : null;
        _futureMessages =
            selectedRound != null
                ? dbHelper.fetchMessagesByRoundId(selectedRound!['id'])
                : Future.value([]);
      });
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        roundsList = [];
        selectedRound = null;
        _futureMessages = Future.value([]);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tableWidth = screenWidth * 0.95 < 350.0 ? 350.0 : screenWidth * 0.95;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DisplayRow(
              title: 'Game Rounds',
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
                  onPressed: _loadRounds,
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            DisplayRow(
              fontSize: 14,
              title: 'Rounds for ${widget.match['matchName']}',
            ),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: roundsList.length,
                itemBuilder: (context, index) {
                  final round = roundsList[index];
                  final isSelected = selectedRound?['id'] == round['id'];
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                        foregroundColor:
                            isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                      ),
                      onPressed: () {
                        if (!mounted) return;
                        setState(() {
                          selectedRound = round;
                          _futureMessages = dbHelper.fetchMessagesByRoundId(
                            round['id'],
                          );
                        });
                      },
                      child: Text(
                        'Round ${round['round']}',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child:
                  _futureMessages == null
                      ? const Center(child: CircularProgressIndicator())
                      : FutureBuilder<List<Map<String, dynamic>>>(
                        future: _futureMessages,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final data = snapshot.data ?? [];

                          // ── NEW: compute per‑round punch counts ──
                          final counts = <String, int>{
                            'BlueBoxer': 0,
                            'RedBoxer': 0,
                          };
                          for (var msg in data) {
                            final who = msg['punchBy'] as String?;
                            if (who == 'BlueBoxer') {
                              counts['BlueBoxer'] = counts['BlueBoxer']! + 1;
                            } else if (who == 'RedBoxer') {
                              counts['RedBoxer'] = counts['RedBoxer']! + 1;
                            }
                          }

                          final rows =
                              data.reversed
                                  .map(
                                    (message) => DataRow(
                                      cells: [
                                        DataCell(Text(message['device'] ?? '')),
                                        DataCell(
                                          Text(message['punchBy'] ?? ''),
                                        ),
                                        DataCell(
                                          Text(
                                            '${message['punchCount'] ?? ''}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(message['timestamp'] ?? ''),
                                        ),
                                        DataCell(
                                          Text(
                                            '${message['sensorValue'] ?? ''}',
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList();

                          // ── INSERTED: show per‑round punch summary ──
                          return Column(
                            children: [                              
                                DisplayRow(
                                  fontSize: 14,
                                  title:
                                      'Punches ➜ '
                                      'BlueBoxer: ${counts['BlueBoxer']} - '
                                      'RedBoxer: ${counts['RedBoxer']}',
                                ),
                              Expanded(
                                child: MatchDataTable(
                                  tableStream: Stream.value(rows),
                                  tableWidthProvider: () => tableWidth,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}







// // lib/screens/rounds_of_match_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:box_sensors/services/database_helper.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:box_sensors/widgets/match_data_table.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

// class RoundsOfMatchScreen extends ConsumerStatefulWidget {
//   final Map<String, dynamic> match;
//   final String eventId;

//   const RoundsOfMatchScreen({
//     super.key,
//     required this.match,
//     required this.eventId,
//   });

//   @override
//   ConsumerState<RoundsOfMatchScreen> createState() => _RoundsOfMatchScreenState();
// }

// class _RoundsOfMatchScreenState extends ConsumerState<RoundsOfMatchScreen> {
//   late final DatabaseHelper dbHelper;
//   List<Map<String, dynamic>> roundsList = [];
//   Map<String, dynamic>? selectedRound;
//   Future<List<Map<String, dynamic>>>? _futureMessages;

//   @override
//   void initState() {
//     super.initState();
//     dbHelper = ref.read(databaseHelperProvider);
//     _loadRounds();
//   }

//   Future<void> _loadRounds() async {
//     try {
//       final allRounds = await dbHelper.fetchRounds();
//       if (!mounted) return;
//       final filtered = allRounds
//           .where((r) => r['matchId'] == widget.match['id'] && r['eventId'] == widget.eventId)
//           .toList()
//         ..sort((a, b) => (a['round'] as int).compareTo(b['round'] as int));

//       setState(() {
//         roundsList = filtered;
//         selectedRound = filtered.isNotEmpty ? filtered.first : null;
//         _futureMessages = selectedRound != null
//             ? dbHelper.fetchMessagesByRoundId(selectedRound!['id'])
//             : Future.value([]);
//       });
//     } catch (e, stackTrace) {
//       Sentry.captureException(e, stackTrace: stackTrace);
//       if (!mounted) return;
//       setState(() {
//         roundsList = [];
//         selectedRound = null;
//         _futureMessages = Future.value([]);
//       });
//     }
//   }

//   @override
//   void dispose() {
//     // Dispose controllers or listeners here if you add them in the future.
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final tableWidth = screenWidth * 0.95 < 350.0 ? 350.0 : screenWidth * 0.95;
//     final theme = Theme.of(context);

//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             DisplayRow(
//               title: 'Game Rounds',
//               actions: [
//                 IconButton(
//                   icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
//                   onPressed: _loadRounds,
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//             DisplayRow(fontSize: 14, title: 'Rounds for ${widget.match['matchName']}'),
//             SizedBox(
//               height: 48,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: roundsList.length,
//                 itemBuilder: (context, index) {
//                   final round = roundsList[index];
//                   final isSelected = selectedRound?['id'] == round['id'];
//                   return Padding(
//                     padding: const EdgeInsets.all(4.0),
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: isSelected
//                             ? theme.colorScheme.primary
//                             : theme.colorScheme.surface,
//                         foregroundColor: isSelected
//                             ? theme.colorScheme.onPrimary
//                             : theme.colorScheme.onSurface,
//                       ),
//                       onPressed: () {
//                         if (!mounted) return;
//                         setState(() {
//                           selectedRound = round;
//                           _futureMessages =
//                               dbHelper.fetchMessagesByRoundId(round['id']);
//                         });
//                       },
//                       child: Text(
//                         'Round ${round['round']}',
//                         style: TextStyle(
//                           fontWeight:
//                               isSelected ? FontWeight.bold : FontWeight.normal,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Expanded(
//               child: _futureMessages == null
//                   ? const Center(child: CircularProgressIndicator())
//                   : FutureBuilder<List<Map<String, dynamic>>>(
//                       future: _futureMessages,
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState == ConnectionState.waiting) {
//                           return const Center(
//                               child: CircularProgressIndicator());
//                         }
//                         final data = snapshot.data ?? [];
//                         final rows = data.reversed
//                             .map(
//                               (message) => DataRow(cells: [
//                                 DataCell(Text(message['device'] ?? '')),
//                                 DataCell(Text(message['punchBy'] ?? '')),
//                                 DataCell(Text('${message['punchCount'] ?? ''}')),
//                                 DataCell(Text(message['timestamp'] ?? '')),
//                                 DataCell(Text('${message['sensorValue'] ?? ''}')),
//                               ]),
//                             )
//                             .toList();

//                         return MatchDataTable(
//                           tableStream: Stream.value(rows),
//                           tableWidthProvider: () => tableWidth,
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }













// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:box_sensors/services/database_helper.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:box_sensors/widgets/match_data_table.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

// class RoundsOfMatchScreen extends ConsumerStatefulWidget {
//   final Map<String, dynamic> match;
//   final String eventId;

//   const RoundsOfMatchScreen({
//     super.key,
//     required this.match,
//     required this.eventId,
//   });

//   @override
//   ConsumerState<RoundsOfMatchScreen> createState() => _RoundsOfMatchScreenState();
// }

// class _RoundsOfMatchScreenState extends ConsumerState<RoundsOfMatchScreen> {
//   late final DatabaseHelper dbHelper;
//   List<Map<String, dynamic>> roundsList = [];
//   Map<String, dynamic>? selectedRound;
//   Future<List<Map<String, dynamic>>>? _futureMessages;
//   bool _disposed = false;

//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) setState(fn);
//   }

//   @override
//   void initState() {
//     super.initState();
//     dbHelper = ref.read(databaseHelperProvider);
//     _loadRounds();
//   }

//   Future<void> _loadRounds() async {
//     try {
//       final all = await dbHelper.fetchRounds();
//       final filtered = all
//         .where((r) => r['matchId'] == widget.match['id'] && r['eventId'] == widget.eventId)
//         .toList()
//       ..sort((a, b) => (a['round'] as int).compareTo(b['round'] as int));

//       _safeSetState(() {
//         roundsList = filtered;
//         selectedRound = filtered.isNotEmpty ? filtered.first : null;
//         _futureMessages = selectedRound != null
//           ? dbHelper.fetchMessagesByRoundId(selectedRound!['id'])
//           : Future.value([]);
//       });
//     } catch (e, st) {
//       Sentry.captureException(e, stackTrace: st);
//       _safeSetState(() {
//         roundsList = [];
//         selectedRound = null;
//         _futureMessages = Future.value([]);
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final double tableWidth = screenWidth * 0.95 < 350.0
//       ? 350.0
//       : screenWidth * 0.95;
//     final theme = Theme.of(context);

//     return Scaffold(                
//       body: SafeArea(
//         child: Column(
//           children: [
//              DisplayRow(
//               title: "Game Rounds",
//               actions: [
//                 IconButton(
//                   icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
//                   onPressed: _loadRounds,
//                 ),
//                 IconButton(
//                   icon: Icon(
//                     Icons.arrow_back,
//                     color: theme.colorScheme.onSurface,
//                   ),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//             DisplayRow(
//               fontSize: 14,
//               title: 'Rounds for ${widget.match['matchName']}',
//             ),
//             SizedBox(
//               height: 48,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: roundsList.length,
//                 itemBuilder: (context, index) {
//                   final round = roundsList[index];
//                   final bool isSelected = selectedRound?['id'] == round['id'];
//                   return Padding(
//                     padding: const EdgeInsets.all(4.0),
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: isSelected
//                           ? theme.colorScheme.primary
//                           : theme.colorScheme.surface,
//                         foregroundColor: isSelected
//                           ? theme.colorScheme.onPrimary
//                           : theme.colorScheme.onSurface,
//                       ),
//                       onPressed: () {
//                         _safeSetState(() {
//                           selectedRound = round;
//                           _futureMessages =
//                             dbHelper.fetchMessagesByRoundId(round['id']);
//                         });
//                       },
//                       child: Text(
//                         'Round ${round['round']}',
//                         style: TextStyle(
//                           fontWeight: isSelected
//                             ? FontWeight.bold
//                             : FontWeight.normal,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             //const Divider(thickness: 1),
//             Expanded(
//               child: _futureMessages == null
//                 ? const Center(child: CircularProgressIndicator())
//                 : FutureBuilder<List<Map<String, dynamic>>>(
//                     future: _futureMessages,
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return const Center(child: CircularProgressIndicator());
//                       }
//                       final data = snapshot.data ?? [];
//                       final rows = data.reversed.map((message) => DataRow(cells: [  //Descending order
//                         DataCell(Text(message['device'] ?? '')),
//                         DataCell(Text(message['punchBy'] ?? '')),
//                         DataCell(Text('${message['punchCount'] ?? ''}')),
//                         DataCell(Text(message['timestamp'] ?? '')),
//                         DataCell(Text('${message['sensorValue'] ?? ''}')),
//                       ])).toList();
        
//                       return MatchDataTable(
//                         tableStream: Stream.value(rows),
//                         tableWidthProvider: () => tableWidth,
//                       );
//                     },
//                   ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }





// // lib/screens/match_round_screen.dart
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:flutter/material.dart';
// import 'package:box_sensors/services/database_helper.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class RoundsOfMatchScreen extends ConsumerStatefulWidget {
//   final Map<String, dynamic> match;
//   final String eventId;

//   const RoundsOfMatchScreen({
//     super.key,
//     required this.match,
//     required this.eventId,
//   });

//   @override
//   ConsumerState<RoundsOfMatchScreen> createState() => _RoundsOfMatchScreenState();
// }

// class _RoundsOfMatchScreenState extends ConsumerState<RoundsOfMatchScreen> {
//   // Instead of instantiating DatabaseHelper directly, use the provider.
//   late final DatabaseHelper dbHelper;

//   List<Map<String, dynamic>> roundsList = [];
//   Map<String, dynamic>? selectedRound;
//   Future<List<Map<String, dynamic>>>? _futureMessages;
//   bool _disposed = false;

//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) setState(fn);
//   }

//   @override
//   void initState() {
//     super.initState();
//     // Get the DatabaseHelper instance from Riverpod.
//     dbHelper = ref.read(databaseHelperProvider);
//     _loadRounds();
//   }

//   Future<void> _loadRounds() async {
//     try {
//       // Fetch all rounds from the database.
//       List<Map<String, dynamic>> allRounds = await dbHelper.fetchRounds();
//       // Filter rounds belonging to the current match and event.
//       List<Map<String, dynamic>> filteredRounds =
//           allRounds.where((round) {
//             return round['matchId'] == widget.match['id'] &&
//                 round['eventId'] == widget.eventId;
//           }).toList();

//       // Sort rounds by their number.
//       filteredRounds.sort(
//         (a, b) => (a['round'] as int).compareTo(b['round'] as int),
//       );

//       _safeSetState(() {
//         roundsList = filteredRounds;
//         // Select the first round (if any) or keep the existing selected round.
//         selectedRound = roundsList.isNotEmpty ? roundsList.first : null;
//         // If a round is selected, cache the Future to fetch its messages.
//         _futureMessages =
//             selectedRound != null ? _fetchMessagesForRound() : null;
//       });
//     } catch (e, stackTrace) {
//       debugPrint("Error loading rounds: $e\n$stackTrace");
//       _safeSetState(() {
//         roundsList = [];
//         selectedRound = null;
//         _futureMessages = Future.value([]);
//       });
//     }
//   }

//   //   Future<void> _loadRounds() async {
//   //   try {
//   //     // 1️⃣ fetch all rounds…
//   //     final allRounds = await dbHelper.fetchRounds();

//   //     // 2️⃣ filter to just the match & event you care about
//   //     final filtered = allRounds.where((r) {
//   //       return r['matchId'] == widget.match!['id']
//   //           && r['eventId'] == widget.eventId;
//   //     }).toList();

//   //     // 3️⃣ sort by the round number
//   //     filtered.sort((a, b) => (a['round'] as int).compareTo(b['round'] as int));

//   //     // 4️⃣ now dedupe: only keep the first occurrence of each round number
//   //     final seen = <int>{};
//   //     final distinctRounds = filtered.where((r) {
//   //       return seen.add(r['round'] as int);
//   //     }).toList();

//   //     // 5️⃣ stick it in state
//   //     _safeSetState(() {
//   //       roundsList = distinctRounds;
//   //       selectedRound = distinctRounds.isNotEmpty ? distinctRounds.first : null;
//   //       _futureMessages = selectedRound != null
//   //         ? _fetchMessagesForRound()
//   //         : Future.value([]);
//   //     });
//   //   } catch (e, st) {
//   //     debugPrint("Error loading rounds: $e\n$st");
//   //     _safeSetState(() {
//   //       roundsList = [];
//   //       selectedRound = null;
//   //       _futureMessages = Future.value([]);
//   //     });
//   //   }
//   // }

//   Future<List<Map<String, dynamic>>> _fetchMessagesForRound() async {
//     if (selectedRound == null) return [];
//     try {
//       return await dbHelper.fetchMessagesByRoundId(selectedRound!['id']);
//     } catch (e, stackTrace) {
//       debugPrint("Error fetching messages: $e\n$stackTrace");
//       return [];
//     }
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     super.dispose();
//   }

//   Widget _headerCell(String text, ThemeData theme) {
//     return Expanded(
//       flex: 1,
//       child: Container(
//         color: theme.colorScheme.primary, //primary
//         child: Center(
//           child: Text(
//             text,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 12.0,
//               color: theme.colorScheme.onPrimary, // onPrimary
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _dataCell(String? text) {
//     return Expanded(
//       flex: 1,
//       child: Center(
//         child: Text(text ?? "", style: const TextStyle(fontSize: 12)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     double tableWidth = screenWidth * 0.95;
//     if (tableWidth < 350) tableWidth = 350;
//     final theme = Theme.of(context);

//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             DisplayRow(
//               title: "Game Rounds",
//               actions: [
//                 IconButton(
//                   icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
//                   onPressed: _loadRounds,
//                 ),
//                 IconButton(
//                   icon: Icon(
//                     Icons.arrow_back,
//                     color: theme.colorScheme.onSurface,
//                   ),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//             DisplayRow(
//               fontSize: 14,
//               title: 'Rounds for ${widget.match['matchName']}',
//             ),
//             Container(
//               height: 50,
//               padding: const EdgeInsets.symmetric(horizontal: 8),
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: roundsList.length,
//                 itemBuilder: (context, index) {
//                   final round = roundsList[index];
//                   final roundLabel = "Round ${round['round']}";
//                   final isSelected =
//                       selectedRound != null &&
//                       selectedRound!['id'] == round['id'];
//                   //
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 4,
//                       vertical: 4,
//                     ),
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor:
//                             isSelected
//                                 ? theme.colorScheme.primary
//                                 : theme.colorScheme.inversePrimary,
//                         foregroundColor:
//                             isSelected
//                                 ? theme.colorScheme.onPrimary
//                                 : theme.colorScheme.onSurface,
//                         minimumSize: const Size(78, 40),
//                         maximumSize: const Size(120, 40),
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         elevation: isSelected ? 8 : 2,
//                       ),
//                       onPressed: () {
//                         _safeSetState(() {
//                           selectedRound = round;
//                           _futureMessages = _fetchMessagesForRound();
//                         });
//                       },
//                       child: AnimatedDefaultTextStyle(
//                         duration: const Duration(milliseconds: 200),
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight:
//                               isSelected ? FontWeight.bold : FontWeight.w500,
//                           color:
//                               isSelected
//                                   ? theme.colorScheme.onPrimary
//                                   : theme.colorScheme.onSurface,
//                         ),
//                         child: Text(roundLabel),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minWidth: tableWidth),
//                 child: Container(
//                   width: tableWidth,
//                   color: theme.colorScheme.primaryContainer,
//                   child: Row(
//                     children: [
//                       _headerCell("Device", theme),
//                       _headerCell("PunchBy", theme),
//                       _headerCell("PunchCount", theme),
//                       _headerCell("Timestamp", theme),
//                       _headerCell("Sensor", theme),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             const Divider(height: 1, thickness: 1),
//             Expanded(
//               child: Scrollbar(
//                 child: SingleChildScrollView(
//                   scrollDirection: Axis.vertical,
//                   child: SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: ConstrainedBox(
//                       constraints: BoxConstraints(minWidth: tableWidth),
//                       child: SizedBox(
//                         width: tableWidth,
//                         child:
//                             _futureMessages == null
//                                 ? const SizedBox()
//                                 : FutureBuilder<List<Map<String, dynamic>>>(
//                                   future: _futureMessages,
//                                   builder: (context, snapshot) {
//                                     if (snapshot.connectionState ==
//                                         ConnectionState.waiting) {
//                                       return const Center(
//                                         child: CircularProgressIndicator(),
//                                       );
//                                     } else if (snapshot.hasError) {
//                                       return Center(
//                                         child: Text("Error: ${snapshot.error}"),
//                                       );
//                                     } else if (!snapshot.hasData ||
//                                         snapshot.data!.isEmpty) {
//                                       return Container(
//                                         height: 300,
//                                         alignment: Alignment.center,
//                                         child: const Text(
//                                           "No punches recorded for this round.",
//                                           style: TextStyle(fontSize: 16.0),
//                                         ),
//                                       );
//                                     }
//                                     final messages = snapshot.data!;
//                                     return SingleChildScrollView(
//                                       scrollDirection: Axis.vertical,
//                                       child: Column(
//                                         children:
//                                             messages.map((message) {
//                                               return Row(
//                                                 children: [
//                                                   _dataCell(message['device']),
//                                                   _dataCell(message['punchBy']),
//                                                   _dataCell(
//                                                     message['punchCount'],
//                                                   ),
//                                                   _dataCell(message['timestamp']),
//                                                   _dataCell(
//                                                     message['sensorValue'],
//                                                   ),
//                                                 ],
//                                               );
//                                             }).toList(),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
