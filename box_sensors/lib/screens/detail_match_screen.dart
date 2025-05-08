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
