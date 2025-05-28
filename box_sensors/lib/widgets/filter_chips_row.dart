// lib/widgets/filter_chips_row.dart
import 'package:flutter/material.dart';

/// The two “Boxer Devices” / “Nearby Devices” chips.
class FilterChipsRow extends StatelessWidget {
  final String filterKeyword;
  final bool chipBusy;
  final VoidCallback onSelectBoxer;
  final VoidCallback onSelectNearby;

  const FilterChipsRow({
    super.key,
    required this.filterKeyword,
    required this.chipBusy,
    required this.onSelectBoxer,
    required this.onSelectNearby,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 176,
            height: 40,
            child: ChoiceChip(
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  "Boxer Devices",
                  style: TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              selected: filterKeyword == "Boxer",
              onSelected: chipBusy ? null : (_) => onSelectBoxer(),
            ),
          ),
          SizedBox(
            width: 176,
            height: 40,
            child: ChoiceChip(
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  "Nearby Devices",
                  style: TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              selected: filterKeyword == "NEARBY",
              onSelected: chipBusy ? null : (_) => onSelectNearby(),
            ),
          ),
        ],
      ),
    );
  }
}
