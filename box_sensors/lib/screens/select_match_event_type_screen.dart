// lib/screens/select_match_event_type_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/widgets/display_row.dart';
import 'package:box_sensors/screens/rounds_of_match_screen.dart';

class SelectMatchEventTypeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> match;
  const SelectMatchEventTypeScreen({super.key, required this.match});

  @override
  ConsumerState<SelectMatchEventTypeScreen> createState() =>
      _MatchEventTypesScreenState();
}

class _MatchEventTypesScreenState
    extends ConsumerState<SelectMatchEventTypeScreen> {
  late final DatabaseHelper dbHelper;
  late Future<List<Map<String, dynamic>>> _futureEvents;

  @override
  void initState() {
    super.initState();
    dbHelper = ref.read(databaseHelperProvider);
    _futureEvents = _fetchEvents();
  }

  Future<List<Map<String, dynamic>>> _fetchEvents() async {
  try {
    // 1️⃣ load the raw events
    final rawEvents = await dbHelper.fetchEventsByMatchId(widget.match['id']);

    // 2️⃣ for each sqflite‑returned map (which is read‑only), make a mutable copy
    final enriched = <Map<String, dynamic>>[];
    for (final event in rawEvents) {
      // copy into a new, modifiable map
      final copy = Map<String, dynamic>.from(event);

      // ✔️ pass the event id (a String) into getEventPunchCounts
      final counts = await dbHelper.getEventPunchCounts(
        copy['id'] as String,
      );

      copy['punchCounts'] = counts;
      enriched.add(copy);
    }

    return enriched;
  } catch (e, st) {
    debugPrint('Error fetching events: $e\n$st');
    return [];
  }
}

  /// Safely calls setState if the widget is still mounted.
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          DisplayRow(
            title: 'Game Events',
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
                onPressed: () {
                  _safeSetState(() {
                    _futureEvents = _fetchEvents();
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          DisplayRow(fontSize: 14, title: '${widget.match['matchName']} Event'),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureEvents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error fetching events:\n${snapshot.error}",
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return const Center(child: Text('No events found'));
                }
                return Scrollbar(
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final date = DateTime.fromMillisecondsSinceEpoch(event['timestamp']);
                      final formattedDate =
                          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
                          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
                      final counts = event['punchCounts'] as Map<String, int>?;
                  
                      return Card(
                        color: theme.cardColor,
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.colorScheme.outline, width: 1),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoundsOfMatchScreen(
                                  match: widget.match,
                                  eventId: event['id'],
                                ),
                              ),
                            );
                          },
                          title: Text(
                            'Match Game played:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Time played: $formattedDate',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  children: [
                                    TextSpan(
                                      text: 'Winner:  ',
                                      style: TextStyle(color: theme.colorScheme.primary),
                                    ),
                                    TextSpan(
                                      text: "${event['winner'] ?? 'No winner yet'}",
                                      style: TextStyle(color: theme.colorScheme.surfaceTint),
                                    ),
                                  ],
                                ),
                              ),
                              if (counts != null)
                                Text(
                                  'Punches ➜ BlueBoxer: ${counts['BlueBoxer'] ?? 0} - '
                                  'RedBoxer: ${counts['RedBoxer'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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
