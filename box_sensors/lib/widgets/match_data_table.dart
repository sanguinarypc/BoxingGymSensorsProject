// lib/widgets/match_data_table.dart
import 'package:flutter/material.dart';
import 'package:box_sensors/models/sensor_data.dart';

class MatchDataTable extends StatelessWidget {
  final List<SensorData> rows;
  final double Function() tableWidthProvider;

  const MatchDataTable({
    super.key,
    required this.rows,
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
              child: Builder(
                builder: (context) {
                  if (rows.isEmpty) {
                    return const Center(child: Text('No Sensor(s) data.'));
                  }
                  return Scrollbar(
                    child: ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, thickness: 1),
                      itemBuilder: (ctx, i) =>
                          _buildRow(rows[rows.length - 1 - i], cellWidth),
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

  Widget _buildRow(SensorData data, double w) {
    final cells = [
      data.device,
      data.punchBy,
      data.punchCount,
      data.timestamp,
      data.sensorValue,
    ];

    return Row(
      children: cells.map((text) {
        return SizedBox(
          width: w,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  overflow: TextOverflow.visible,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
