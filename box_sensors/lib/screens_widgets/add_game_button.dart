// lib/screens_widgets/add_game_button.dart
import 'package:material_ui/material_ui.dart';
import 'package:box_sensors/widgets/common_buttons.dart';

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
