// lib/widgets/match_data_table.dart
import 'package:flutter/material.dart';

class MatchDataTable extends StatelessWidget {
  final Stream<List<DataRow>> tableStream;
  final double Function() tableWidthProvider;

  const MatchDataTable({
    super.key,
    required this.tableStream,
    required this.tableWidthProvider,
  });

  @override
  Widget build(BuildContext context) {
    final totalWidth = tableWidthProvider();
    // assume 5 columns; you can compute this from your header list too
    final colCount = 5;
    final cellWidth = totalWidth / colCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
        child: Column(
          children: [
            _header(context, cellWidth),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: StreamBuilder<List<DataRow>>(
                stream: tableStream,
                builder: (ctx, snap) {
                  final rows = snap.data ?? [];
                  if (rows.isEmpty) {
                    return const Center(child: Text('No Sensor(s) data.'));
                  }
                  final reversed = rows.reversed.toList();
                  return Scrollbar(
                    child: ListView.separated(
                      itemCount: reversed.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, thickness: 1),
                      itemBuilder: (ctx, i) =>
                          _buildRow(reversed[i], cellWidth),
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

  Widget _header(BuildContext ctx, double w) {
    final theme = Theme.of(ctx);
    final headers = ['Device', 'PunchBy', 'PunchCount', 'Timestamp', 'Sensor'];

    return Container(
      color: theme.colorScheme.surfaceTint,
      child: Row(
        children: headers.map((h) {
          return SizedBox(
            width: w,
            child: Container(
              color: theme.colorScheme.primary,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                h,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: theme.colorScheme.onPrimary,
                ),
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRow(DataRow row, double w) {
    return Row(
      children: row.cells.map((c) {
        return SizedBox(
          width: w,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Center(
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  fontSize: 14,
                  overflow: TextOverflow.visible,
                  // you could also use ellipsis: TextOverflow.ellipsis
                ),
                child: c.child,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
