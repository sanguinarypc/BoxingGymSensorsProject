// lib/screens_widgets/match_detail_info_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MatchDetailInfoCard extends StatelessWidget {
  final Map<String, dynamic> matchData;
  const MatchDetailInfoCard({super.key, required this.matchData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // parse & reformat date
    String date = matchData['matchDate'] ?? 'Unknown Date';
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(matchData['matchDate']);
      date = DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {}

    return Card(
      color: theme.cardColor,
      elevation: 6,
      // **only** vertical margin – horizontal is 0 so it touches the 12px padding above
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelValue('Match Name:', matchData['matchName'] ?? 'Unknown', theme),
            const SizedBox(height: 16),
            _labelValue('Match Date:', date, theme),
            const SizedBox(height: 8),
            _labelValue('Rounds:', '${matchData['rounds']}', theme),
            const SizedBox(height: 8),
            _labelValue('Finished at Round:', '${matchData['finishedAtRound']}', theme),
            const SizedBox(height: 8),
            _labelValue('Total Time:', matchData['totalTime'] ?? 'Unknown', theme),
            const SizedBox(height: 8),
            _labelValue('Round Time:', '${matchData['roundTime']} minute(s)', theme),
            const SizedBox(height: 8),
            _labelValue('Break Time:', '${matchData['breakTime']} second(s)', theme),
          ],
        ),
      ),
    );
  }

  Widget _labelValue(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary,
        )),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
          fontSize: 16, color: theme.colorScheme.onSurface,
        )),
      ],
    );
  }
}
