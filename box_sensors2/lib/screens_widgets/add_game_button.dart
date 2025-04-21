// lib/screens/add_game_button.dart
import 'package:flutter/material.dart';
import 'package:box_sensors2/widgets/common_buttons.dart';

class AddGameButton extends StatelessWidget {
  final VoidCallback onSave;
  const AddGameButton({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CommonButtons.buildRoundControlButton(
      context,
      'Add Game',
      onSave,
      theme,
    );
  }
}

