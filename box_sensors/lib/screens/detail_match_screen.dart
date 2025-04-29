// lib/screens/match_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:box_sensors/widgets/display_row.dart';
import 'package:box_sensors/screens_widgets/match_detail_info_card.dart';
import 'package:box_sensors/screens_widgets/match_detail_actions.dart';
import 'package:box_sensors/screens/edit_match_screen.dart';
import 'package:box_sensors/screens/add_match_screen.dart';
import 'package:box_sensors/screens/start_match_screen.dart';

class DetailMatchScreen extends StatefulWidget {
  final Map<String, dynamic> match;
  const DetailMatchScreen({required this.match, super.key});

  @override
  State<DetailMatchScreen> createState() => _DetailMatchScreenState();
}

class _DetailMatchScreenState extends State<DetailMatchScreen> {
  late Map<String, dynamic> matchData;

  // No _disposed flag any more.
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    // Make a mutable copy if you prefer, otherwise this reference works too:
    matchData = Map<String, dynamic>.from(widget.match);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          DisplayRow(
            title: 'Game Details',
            actions: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop<bool>(context, true), // or false if you want to indicate no changes
              ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                // keep your 12px horizontal gutter
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MatchDetailInfoCard(matchData: matchData),

                    MatchDetailActions(
                      onEdit: () async {
                        final updated = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditMatchScreen(match: matchData),
                          ),
                        );
                        if (updated != null) {
                          _safeSetState(() => matchData = updated);
                        }
                      },
                      onAdd: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddMatchScreen()),
                        ).then((_) {
                          _safeSetState(() {});
                        });
                      },
                      onStart: () async {
                        final updated = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StartMatchScreen(match: matchData),
                          ),
                        );
                        if (updated != null) {
                          _safeSetState(() => matchData = updated);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




















// lib/screens/match_detail_screen.dart
// import 'package:flutter/material.dart';
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:box_sensors/screens_widgets/match_detail_info_card.dart';
// import 'package:box_sensors/screens_widgets/match_detail_actions.dart';
// import 'package:box_sensors/screens/edit_match_screen.dart';
// import 'package:box_sensors/screens/add_match_screen.dart';
// import 'package:box_sensors/screens/start_match_screen.dart';

// class DetailMatchScreen extends StatefulWidget {
//   final Map<String, dynamic> match;
//   const DetailMatchScreen({required this.match, super.key});

//   @override
//   State<DetailMatchScreen> createState() => _DetailMatchScreenState();
// }

// class _DetailMatchScreenState extends State<DetailMatchScreen> {
//   late Map<String, dynamic> matchData;
//   bool _disposed = false;
//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) setState(fn);
//   }

//   @override
//   void initState() {
//     super.initState();
//     matchData = widget.match;
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
//             title: 'Game Details',
//             actions: [
//               IconButton(
//                 icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
//                 onPressed: () => Navigator.pop(context, true), // matchData
//               )
//             ],
//           ),
//           Expanded(
//             child: SingleChildScrollView(
//               child: Padding(
//                 // <-- this horizontal padding is your 12px gutter
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: Column(
//                   // stretch children to fill width
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     MatchDetailInfoCard(matchData: matchData),
//                     MatchDetailActions(
//                       onEdit: () async {
//                         final updated = await Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => EditMatchScreen(match: matchData),
//                           ),
//                         );
//                         if (updated != null) {
//                           _safeSetState(() => matchData = updated);
//                         }
//                       },
//                       onAdd: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (_) => const AddMatchScreen()),
//                         ).then((_) {
//                           if (mounted) _safeSetState(() {});
//                         });
//                       },
//                       onStart: () async {
//                         final updated = await Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (_) => StartMatchScreen(match: matchData)),
//                         );
//                         if (updated != null) {
//                           _safeSetState(() => matchData = updated);
//                         }
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:box_sensors/screens/add_match_screen.dart';
// import 'package:box_sensors/screens/edit_match_screen.dart';
// import 'package:box_sensors/screens/start_match_screen.dart';
// import 'package:box_sensors/screens_widgets/match_detail_info_card.dart';
// import 'package:box_sensors/screens_widgets/match_detail_actions.dart';

// class DetailMatchScreen extends StatefulWidget {
//   final Map<String, dynamic> match;
//   const DetailMatchScreen({required this.match, super.key});

//   @override
//   State<DetailMatchScreen> createState() => _DetailMatchScreenState();
// }

// class _DetailMatchScreenState extends State<DetailMatchScreen> {
//   late Map<String, dynamic> matchData;
//   bool _disposed = false;

//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) setState(fn);
//   }

//   @override
//   void initState() {
//     super.initState();
//     matchData = widget.match;
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
//             title: 'Game Details',
//             actions: [
//               IconButton(
//                 icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
//                 onPressed: () => Navigator.pop(context, matchData),
//               )
//             ],
//           ),
//           Expanded(
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   // <-- No parent padding here
//                   MatchDetailInfoCard(matchData: matchData),
//                   const SizedBox(height: 16),
//                   // Only the action row gets horizontal padding:
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     child: MatchDetailActions(
//                       onEdit: () async {
//                         final updated = await Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => EditMatchScreen(match: matchData),
//                           ),
//                         );
//                         if (updated != null) {
//                           _safeSetState(() => matchData = updated);
//                         }
//                       },
//                       onAdd: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (_) => const AddMatchScreen()),
//                         ).then((_) {
//                           if (mounted) _safeSetState(() {});
//                         });
//                       },
//                       onStart: () async {
//                         final updated = await Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => StartMatchScreen(match: matchData),
//                           ),
//                         );
//                         if (updated != null) {
//                           _safeSetState(() => matchData = updated);
//                         }
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:box_sensors/screens/add_match_screen.dart';
// import 'package:box_sensors/screens/edit_match_screen.dart';
// import 'package:box_sensors/screens/start_match_screen.dart';

// import 'package:box_sensors/screens_widgets/match_detail_info_card.dart';
// import 'package:box_sensors/screens_widgets/match_detail_actions.dart';

// class DetailMatchScreen extends StatefulWidget {
//   final Map<String, dynamic> match;

//   const DetailMatchScreen({required this.match, super.key});

//   @override
//   State<DetailMatchScreen> createState() => _DetailMatchScreenState();
// }

// class _DetailMatchScreenState extends State<DetailMatchScreen> {
//   late Map<String, dynamic> matchData;
//   bool _disposed = false;

//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) setState(fn);
//   }

//   @override
//   void initState() {
//     super.initState();
//     matchData = widget.match;
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
//             title: 'Game Details',
//             actions: [
//               IconButton(
//                 icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
//                 onPressed: () => Navigator.pop(context, matchData),
//               )
//             ],
//           ),
//           Expanded(
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   MatchDetailInfoCard(matchData: matchData),
//                   const SizedBox(height: 16),
//                   MatchDetailActions(
//                     onEdit: () async {
//                       final updated = await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => EditMatchScreen(match: matchData),
//                         ),
//                       );
//                       if (updated != null) {
//                         _safeSetState(() => matchData = updated);
//                       }
//                     },
//                     onAdd: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const AddMatchScreen()),
//                       ).then((_) {
//                         if (mounted) _safeSetState(() {});
//                       });
//                     },
//                     onStart: () async {
//                       final updated = await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => StartMatchScreen(match: matchData),
//                         ),
//                       );
//                       if (updated != null) {
//                         _safeSetState(() => matchData = updated);
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:box_sensors/screens/add_match_screen.dart';
// import 'package:box_sensors/screens/edit_match_screen.dart';
// import 'package:box_sensors/screens/start_match_screen.dart';
// import 'package:box_sensors/widgets/match_detail_info_card.dart';

// class DetailMatchScreen extends StatefulWidget {
//   final Map<String, dynamic> match;
//   const DetailMatchScreen({required this.match, super.key});

//   @override
//   State<DetailMatchScreen> createState() => _DetailMatchScreenState();
// }

// class _DetailMatchScreenState extends State<DetailMatchScreen> {
//   late Map<String, dynamic> matchData;
//   bool _disposed = false;

//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) setState(fn);
//   }

//   @override
//   void initState() {
//     super.initState();
//     matchData = widget.match;
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
//             title: 'Game Details',
//             actions: [
//               IconButton(
//                 icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
//                 onPressed: () => Navigator.pop(context, matchData),
//               )
//             ],
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     // ←––––– Use your refactored card here
//                     MatchDetailInfoCard(matchData: matchData),

//                     const SizedBox(height: 8),

//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () async {
//                               final updated = await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => EditMatchScreen(match: matchData),
//                                 ),
//                               );
//                               if (updated != null) {
//                                 _safeSetState(() {
//                                   matchData = updated;
//                                 });
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: theme.colorScheme.primary,
//                               foregroundColor: theme.colorScheme.onPrimary,
//                               elevation: 6,
//                               shadowColor: theme.shadowColor,
//                               surfaceTintColor: theme.colorScheme.primaryContainer,
//                             ),
//                             child: const Padding(
//                               padding: EdgeInsets.symmetric(horizontal: 8.0),
//                               child: Text('Edit Game', textAlign: TextAlign.center),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => const AddMatchScreen(),
//                                 ),
//                               ).then((_) => _safeSetState(() {}));
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: theme.colorScheme.primary,
//                               foregroundColor: theme.colorScheme.onPrimary,
//                               elevation: 6,
//                               shadowColor: theme.shadowColor,
//                               surfaceTintColor: theme.colorScheme.primaryContainer,
//                             ),
//                             child: const Padding(
//                               padding: EdgeInsets.symmetric(horizontal: 8.0),
//                               child: Text('Add New Game', textAlign: TextAlign.center),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 8),

//                     ElevatedButton.icon(
//                       onPressed: () async {
//                         final updated = await Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => StartMatchScreen(match: matchData),
//                           ),
//                         );
//                         if (updated != null) _safeSetState(() {
//                           matchData = updated;
//                         });
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: theme.colorScheme.primary,
//                         foregroundColor: theme.colorScheme.onPrimary,
//                         elevation: 6,
//                         shadowColor: theme.shadowColor,
//                         surfaceTintColor: theme.colorScheme.primaryContainer,
//                       ),
//                       icon: Icon(Icons.sports_mma, color: theme.colorScheme.onPrimary),
//                       label: const Text('Start Game', textAlign: TextAlign.center),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



























// Code before refactoring
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:box_sensors/screens/add_match_screen.dart';
// import 'package:box_sensors/screens/edit_match_screen.dart';
// import 'package:box_sensors/screens/start_match_screen.dart';

// class DetailMatchScreen extends StatefulWidget {
//   final Map<String, dynamic> match;

//   const DetailMatchScreen({required this.match, super.key});

//   @override
//   State<DetailMatchScreen> createState() => _DetailMatchScreenState();
// }

// class _DetailMatchScreenState extends State<DetailMatchScreen> {
//   late Map<String, dynamic> matchData;
//   bool _disposed = false;

//   /// Safely call setState only if the widget is still mounted.
//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) {
//       setState(fn);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     matchData = widget.match; // Initialize match data with the provided match
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     // Try parsing the date from match data and reformat it as DD/MM/YYYY
//     String formattedDate = matchData['matchDate'] ?? 'Unknown Date';
//     try {
//       // Assuming match['matchDate'] might be in 'YYYY-MM-DD' format or another standard format
//       DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(formattedDate);
//       formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);
//     } catch (e) {
//       // If parsing fails, retain the original value
//       formattedDate = matchData['matchDate'] ?? 'Unknown Date';
//     }

//     return Scaffold(
//       body: Column(
//         children: [
//           // DisplayRow above the main content
//           DisplayRow(
//             title: 'Game Details',
//             actions: [
//               IconButton(
//                 icon: Icon(
//                   Icons.arrow_back,
//                   color: theme.colorScheme.onSurface,
//                 ),
//                 onPressed: () {
//                   // Instead of passing true, we now pass the updated matchData.
//                   Navigator.pop(context, matchData);
//                 },
//               ),
//             ],
//           ),
//           // Wrap the rest of the content in an Expanded widget to allow scrolling
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     SizedBox(
//                       width: double.infinity, // Ensure the card takes full width
//                       child: Card(
//                         color: theme.cardColor, // Use theme.cardColor
//                         elevation: 6,
//                         margin: const EdgeInsets.symmetric(vertical: 8),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           side: BorderSide(
//                             color: theme.colorScheme.outline,
//                             width: 1,
//                           ),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Match Name:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 matchData['matchName'] ?? 'Unknown',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.normal,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'Match Date:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 formattedDate,
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Rounds:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 '${matchData['rounds'] ?? 'Unknown'}',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Finished at Round:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 '${matchData['finishedAtRound'] ?? 'Unknown'}',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Total Time:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 matchData['totalTime'] ?? 'Unknown',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Round Time:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 '${matchData['roundTime'] ?? 'Unknown'} minute(s)',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Break Time:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 '${matchData['breakTime'] ?? 'Unknown'} second(s)',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 0), // Spacing between card and buttons
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () async {
//                               final updatedMatch = await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       EditMatchScreen(match: matchData),
//                                 ),
//                               );
//                               if (updatedMatch != null) {
//                                 _safeSetState(() {
//                                   matchData = updatedMatch; // Update match data
//                                 });
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: theme.colorScheme.primary,
//                               foregroundColor: theme.colorScheme.onPrimary,
//                               elevation: 6,
//                               shadowColor: theme.shadowColor,
//                               surfaceTintColor: theme.colorScheme.primaryContainer,
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                               child: Text(
//                                 'Edit Game',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: theme.colorScheme.onPrimary,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => const AddMatchScreen(),
//                                 ),
//                               ).then((_) {
//                                 // Refresh the list after returning from the add match screen
//                                 if (mounted) {
//                                   _safeSetState(() {});
//                                 }
//                               });
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: theme.colorScheme.primary,
//                               foregroundColor: theme.colorScheme.onPrimary,
//                               elevation: 6,
//                               shadowColor: theme.shadowColor,
//                               surfaceTintColor: theme.colorScheme.primaryContainer,
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                               child: Text(
//                                 'Add New Game',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: theme.colorScheme.onPrimary,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () async {
//                               final updatedMatch = await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => StartMatchScreen(
//                                     match: matchData,
//                                     // dataTableStream: Stream.empty(), // Replace with actual stream
//                                     //sendMessage: (String message) {}, // Replace with actual function
//                                   ),
//                                 ),
//                               );
//                               if (updatedMatch != null) {
//                                 _safeSetState(() {
//                                   matchData = updatedMatch; // Update match data
//                                 });
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: theme.colorScheme.primary,
//                               foregroundColor: theme.colorScheme.onPrimary,
//                               elevation: 6,
//                               shadowColor: theme.shadowColor,
//                               surfaceTintColor: theme.colorScheme.primaryContainer,
//                             ),
//                             icon: Icon(
//                               Icons.sports_mma,
//                               size: 24,
//                               color: theme.colorScheme.onPrimary,
//                             ),
//                             label: Text(
//                               'Start Game',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: theme.colorScheme.onPrimary,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }












// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:box_sensors/screens/add_match_screen.dart';
// import 'package:box_sensors/screens/edit_match_screen.dart';
// import 'package:box_sensors/screens/start_match_screen.dart';

// class DetailMatchScreen extends StatefulWidget {
//   final Map<String, dynamic> match;

//   const DetailMatchScreen({required this.match, super.key});

//   @override
//   State<DetailMatchScreen> createState() => _DetailMatchScreenState();
// }

// class _DetailMatchScreenState extends State<DetailMatchScreen> {
//   late Map<String, dynamic> matchData;
//   bool _disposed = false;

//   /// Safely call setState only if the widget is still mounted.
//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) {
//       setState(fn);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     matchData = widget.match; // Initialize match data with the provided match
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     // Try parsing the date from match data and reformat it as DD/MM/YYYY
//     String formattedDate = matchData['matchDate'] ?? 'Unknown Date';
//     try {
//       // Assuming match['matchDate'] might be in 'YYYY-MM-DD' format or another standard format
//       DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(formattedDate);
//       formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);
//     } catch (e) {
//       // If parsing fails, retain the original value
//       formattedDate = matchData['matchDate'] ?? 'Unknown Date';
//     }

//     return Scaffold(
//       body: Column(
//         children: [
//           // DisplayRow above the main content
//           DisplayRow(
//             title: 'Game Details',
//             actions: [
//               IconButton(
//                 icon: Icon(
//                   Icons.arrow_back,
//                   color: theme.colorScheme.onSurface,
//                 ),
//                 onPressed: () {
//                   Navigator.pop(context, true); // Pass true to indicate refresh
//                 },
//               ),
//             ],
//           ),
//           // Wrap the rest of the content in an Expanded widget to allow scrolling
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     SizedBox(
//                       width: double.infinity, // Ensure the card takes full width
//                       child: Card(
//                         color: theme.cardColor, // Use theme.cardColor
//                         elevation: 6,
//                         margin: const EdgeInsets.symmetric(vertical: 8),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           side: BorderSide(
//                             color: theme.colorScheme.outline,
//                             width: 1,
//                           ),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Match Name:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 matchData['matchName'] ?? 'Unknown',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.normal,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'Match Date:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 formattedDate,
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Rounds:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 '${matchData['rounds'] ?? 'Unknown'}',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Finished at Round:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 '${matchData['finishedAtRound'] ?? 'Unknown'}',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Total Time:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 matchData['totalTime'] ?? 'Unknown',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Round Time:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 '${matchData['roundTime'] ?? 'Unknown'} minute(s)',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Rest Time:',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               Text(
//                                 '${matchData['restTime'] ?? 'Unknown'} second(s)',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: theme.colorScheme.onSurface,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 0), // Spacing between card and buttons
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () async {
//                               final updatedMatch = await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       EditMatchScreen(match: matchData),
//                                 ),
//                               );
//                               if (updatedMatch != null) {
//                                 _safeSetState(() {
//                                   matchData = updatedMatch; // Update match data
//                                 });
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: theme.colorScheme.primary,
//                               foregroundColor: theme.colorScheme.onPrimary,
//                               elevation: 6,
//                               shadowColor: theme.shadowColor,
//                               surfaceTintColor: theme.colorScheme.primaryContainer,
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                               child: Text(
//                                 'Edit Game',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: theme.colorScheme.onPrimary,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => const AddMatchScreen(),
//                                 ),
//                               ).then((_) {
//                                 // Refresh the list after returning from the add match screen
//                                 if (mounted) {
//                                   _safeSetState(() {});
//                                 }
//                               });
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: theme.colorScheme.primary,
//                               foregroundColor: theme.colorScheme.onPrimary,
//                               elevation: 6,
//                               shadowColor: theme.shadowColor,
//                               surfaceTintColor: theme.colorScheme.primaryContainer,
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                               child: Text(
//                                 'Add New Game',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: theme.colorScheme.onPrimary,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             onPressed: () async {
//                               final updatedMatch = await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => StartMatchScreen(
//                                     match: matchData,
//                                     dataTableStream: Stream.empty(), // Replace with actual stream
//                                     sendMessage: (String message) {}, // Replace with actual function
//                                   ),
//                                 ),
//                               );
//                               if (updatedMatch != null) {
//                                 _safeSetState(() {
//                                   matchData = updatedMatch; // Update match data
//                                 });
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: theme.colorScheme.primary,
//                               foregroundColor: theme.colorScheme.onPrimary,
//                               elevation: 6,
//                               shadowColor: theme.shadowColor,
//                               surfaceTintColor: theme.colorScheme.primaryContainer,
//                             ),
//                             icon: Icon(
//                               Icons.sports_mma,
//                               size: 24,
//                               color: theme.colorScheme.onPrimary,
//                             ),
//                             label: Text(
//                               'Start Game',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: theme.colorScheme.onPrimary,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
