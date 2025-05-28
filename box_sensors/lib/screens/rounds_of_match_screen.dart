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
