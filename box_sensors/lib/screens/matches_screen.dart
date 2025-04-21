import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/widgets/display_row.dart';
import 'package:box_sensors/screens_widgets/match_list_item.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  late final DatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = ref.read(databaseHelperProvider);
  }

  Future<List<Map<String, dynamic>>> _loadMatches() {
    return dbHelper.fetchMatches();
  }

  void _refreshMatches() {
    if (mounted) {
      // simple empty setState to re-trigger FutureBuilder
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          DisplayRow(
            title: 'Games',
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
                onPressed: _refreshMatches,
              ),
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadMatches(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                } else if (snap.data == null || snap.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matches found.\nPlease add a match to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                  );
                }
                final matches = snap.data!;
                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (_, i) => MatchListItem(
                    match: matches[i],
                    dbHelper: dbHelper,
                    onRefresh: _refreshMatches,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}






// // lib/screens/matches_screen.dart
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:box_sensors/services/database_helper.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:box_sensors/screens_widgets/match_list_item.dart';

// class MatchesScreen extends ConsumerStatefulWidget {
//   const MatchesScreen({super.key});

//   @override
//   ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
// }

// class _MatchesScreenState extends ConsumerState<MatchesScreen> {
//   late final DatabaseHelper dbHelper;
//   bool _disposed = false;

//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) setState(fn);
//   }

//   void _refreshMatches() => _safeSetState(() {});

//   Future<List<Map<String, dynamic>>> _loadMatches() => dbHelper.fetchMatches();

//   @override
//   void initState() {
//     super.initState();
//     dbHelper = ref.read(databaseHelperProvider);
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       body: Column(
//         children: [
//           DisplayRow(
//             title: 'Games',
//             actions: [
//               IconButton(
//                 icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
//                 onPressed: _refreshMatches,
//               ),
//               IconButton(
//                 icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ],
//           ),
//           Expanded(
//             child: FutureBuilder<List<Map<String, dynamic>>>(
//               future: _loadMatches(),
//               builder: (context, snap) {
//                 if (snap.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (snap.hasError) {
//                   return Center(child: Text('Error: ${snap.error}'));
//                 } else if (snap.data == null || snap.data!.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       'No matches found.\nPlease add a match to continue.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 20),
//                     ),
//                   );
//                 }
//                 final matches = snap.data!;
//                 return ListView.builder(
//                   itemCount: matches.length,
//                   itemBuilder: (_, i) => MatchListItem(
//                     match: matches[i],
//                     dbHelper: dbHelper,
//                     onRefresh: _refreshMatches,
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }







// // lib/screens/matches_screen.dart
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:flutter/material.dart';
// import 'package:box_sensors/services/database_helper.dart';
// import 'package:box_sensors/screens/match_detail_screen.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';
// import 'package:box_sensors/screens/edit_match_screen.dart';
// import 'package:box_sensors/screens/match_event_types_screen.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:box_sensors/services/providers.dart';

// class MatchesScreen extends ConsumerStatefulWidget {
//   const MatchesScreen({super.key});

//   @override
//   ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
// }

// class _MatchesScreenState extends ConsumerState<MatchesScreen> {
//   // Instead of directly instantiating DatabaseHelper, obtain it via the provider.
//   late final DatabaseHelper dbHelper;
//   bool _disposed = false;

//   /// Safely call setState only if the widget is still mounted.
//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) {
//       setState(fn);
//     }
//   }

//   /// Refresh the matches list.
//   void refreshMatches() {
//     _safeSetState(() {});
//   }

//   /// Fetch matches from the database.
//   Future<List<Map<String, dynamic>>> _fetchMatchesAfterInserts() async {
//     return dbHelper.fetchMatches();
//   }

//   @override
//   void initState() {
//     super.initState();
//     // Get the singleton DatabaseHelper instance via Riverpod.
//     dbHelper = ref.read(databaseHelperProvider);
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       body: Column(
//         children: [
//           // Top row with title and actions.
//           DisplayRow(
//             title: 'Games',
//             actions: [
//               IconButton(
//                 icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
//                 onPressed: refreshMatches,
//               ),
//               IconButton(
//                 icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ],
//           ),
//           // List of matches loaded via FutureBuilder.
//           Expanded(
//             child: FutureBuilder<List<Map<String, dynamic>>>(
//               future: _fetchMatchesAfterInserts(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       'No matches found.\nPlease add a match to continue.',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 20.0),
//                     ),
//                   );
//                 }
//                 final matches = snapshot.data!;
//                 return ListView.builder(
//                   itemCount: matches.length,
//                   itemBuilder: (context, index) {
//                     final match = matches[index];
//                     return Slidable(
//                       key: ValueKey(match['id']),
//                       endActionPane: ActionPane(
//                         motion: const ScrollMotion(),
//                         extentRatio: 0.78,
//                         children: [
//                           // Action: View Events.
//                           SlidableAction(
//                             onPressed: (context) {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       MatchEventTypesScreen(match: match),
//                                 ),
//                               );
//                             },
//                             backgroundColor: Colors.green,
//                             foregroundColor: Colors.white,
//                             icon: Icons.event,
//                             label: 'Events',
//                           ),
//                           // Action: Edit.
//                           SlidableAction(
//                             onPressed: (context) async {
//                               final updatedMatch = await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       EditMatchScreen(match: match),
//                                 ),
//                               );
//                               if (updatedMatch != null) {
//                                 refreshMatches();
//                               }
//                             },
//                             backgroundColor: Colors.blue,
//                             foregroundColor: Colors.white,
//                             icon: Icons.edit,
//                             label: 'Edit',
//                           ),
//                           // Action: Delete.
//                           SlidableAction(
//                             onPressed: (_) async {
//                               try {
//                                 await dbHelper.deleteMatch(match['id']);
//                                 if (!mounted) return;
//                                 refreshMatches();
//                               } catch (e, stackTrace) {
//                                 debugPrint('Error deleting match: $e\n$stackTrace');
//                                 if (!mounted) return;
//                                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                                   if (mounted) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(
//                                         content: Text('Failed to delete match.'),
//                                       ),
//                                     );
//                                   }
//                                 });
//                               }
//                             },
//                             backgroundColor: Colors.red,
//                             foregroundColor: Colors.white,
//                             icon: Icons.delete,
//                             label: 'Delete',
//                           ),
//                         ],
//                       ),
//                       child: Card(
//                         color: theme.cardColor,
//                         elevation: 6,
//                         margin: const EdgeInsets.symmetric(
//                           vertical: 4,
//                           horizontal: 12,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           side: BorderSide(
//                             color: theme.colorScheme.outline,
//                             width: 1,
//                           ),
//                         ),
//                         child: ListTile(
//                           dense: true,
//                           contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//                           title: Text(
//                             'Match Name:',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: theme.colorScheme.primary,
//                             ),
//                           ),
//                           subtitle: Text(
//                             '${match['matchName']}',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.normal,
//                               color: theme.colorScheme.onSurface,
//                             ),
//                           ),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => MatchDetailScreen(match: match),
//                               ),
//                             ).then((value) {
//                               if (value == true) {
//                                 refreshMatches();
//                               }
//                             });
//                           },
//                           trailing: IconButton(
//                             icon: Icon(
//                               Icons.event,
//                               color: theme.colorScheme.primary,
//                             ),
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => MatchEventTypesScreen(match: match),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
