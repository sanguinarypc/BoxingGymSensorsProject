// lib/screens_widgets/match_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/screens/edit_match_screen.dart';
import 'package:box_sensors/screens/detail_match_screen.dart';
import 'package:box_sensors/screens/select_match_event_type_screen.dart';

/// A single “slidable + card + tile” row for one match.
class MatchListItem extends StatelessWidget {
  final Map<String, dynamic> match;
  final DatabaseHelper dbHelper;
  final VoidCallback onRefresh;
 
  const MatchListItem({
    super.key,
    required this.match,
    required this.dbHelper,
    required this.onRefresh, 
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(match['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.78,
        children: [
          // View events
          SlidableAction(
            onPressed: (_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SelectMatchEventTypeScreen(match: match),
                ),
              );
            },
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.event,
            label: 'Events',
          ),

          // Edit
          SlidableAction(
            onPressed: (_) async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditMatchScreen(match: match),
                ),
              );
              if (updated != null) {
                onRefresh();
              }
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),

          // Delete
          SlidableAction(
            onPressed: (_) async {
              // Capture messenger BEFORE the await
              final messenger = ScaffoldMessenger.of(context);
              try {
                await dbHelper.deleteMatch(match['id']);
                onRefresh();
              } catch (e, st) {
                debugPrint('Error deleting match: $e\n$st');
                messenger.showSnackBar(
                  const SnackBar(content: Text('Failed to delete match.')),
                );
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        color: theme.cardColor,
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            'Match Name:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          subtitle: Text(
            '${match['matchName']}',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
          ),

          // Tap to see details
          onTap: () async {
            final result = await Navigator.push<bool?>(
              context,
              MaterialPageRoute(
                builder: (_) => DetailMatchScreen(match: match),
              ),
            );
            if (result == true) {
              onRefresh();
            }
          },

          trailing: IconButton(
            icon: Icon(Icons.event, color: theme.colorScheme.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SelectMatchEventTypeScreen(match: match),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
