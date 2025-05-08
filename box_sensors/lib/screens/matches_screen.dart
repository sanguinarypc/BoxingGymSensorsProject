// lib/screens/matches_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/widgets/display_row.dart';
import 'package:box_sensors/screens_widgets/match_list_item.dart';

/// This is your public interface so ConnectHome can call reloadMatches()
abstract class MatchesReloadable extends ConsumerState<MatchesScreen> {
  void reloadMatches();
}

class MatchesScreen extends ConsumerStatefulWidget {
  final void Function(int)? onTabChange;
  const MatchesScreen({super.key, this.onTabChange});

  @override
  // Return a State that implements MatchesReloadable:
  MatchesReloadable createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    implements MatchesReloadable {
  @override
  void reloadMatches() {
    // ignore: unused_result // simply re-invalidate & re-fetch
    ref.refresh(matchesFutureProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncMatches = ref.watch(matchesFutureProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onTabChange?.call(0);
      },
      child: SafeArea(
        child: Column(
          children: [
            DisplayRow(
              title: 'Games',
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
                  onPressed: reloadMatches,
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => widget.onTabChange?.call(0),
                ),
              ],
            ),
            Expanded(
              child: asyncMatches.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (matches) {
                  if (matches.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matches found.\nPlease add a match to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  }
                  return Scrollbar(
                    child: ListView.builder(
                      itemCount: matches.length,
                      itemBuilder:
                          (_, i) => MatchListItem(
                            match: matches[i],
                            dbHelper: ref.read(databaseHelperProvider),
                            onRefresh: reloadMatches,
                          ),
                    ),
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
