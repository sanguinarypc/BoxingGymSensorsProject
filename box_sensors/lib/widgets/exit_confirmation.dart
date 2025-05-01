import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

enum _ExitAction { exit, minimize, cancel }

class ExitConfirmation {
  static const MethodChannel _channel = MethodChannel('app.exit.channel');

  static Future<void> show(BuildContext context) async {
    final choice = await showDialog<_ExitAction>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'What now?',
              style: const TextStyle(
                fontSize: 22, // ← your desired size
                fontWeight: FontWeight.bold, // optional
              ),
            ),

            // tighten up the default padding so your items sit nicely
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            // build the entire list in the content area
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, // full width
              children: [
                const Text(
                  'Exit app, minimize it, or stay?',
                  style: TextStyle(
                    fontSize: 16, // ← your desired size
                    fontWeight: FontWeight.bold, // optional
                  ),
                ),
                const SizedBox(height: 16),

                // A helper row for each choice
                _buildOption(
                  ctx,
                  Icons.exit_to_app,
                  'Exit App',
                  _ExitAction.exit,
                ),
                _buildOption(
                  ctx,
                  Icons.arrow_circle_down_outlined, //minimize
                  'Minimize App',
                  _ExitAction.minimize,
                ),
                _buildOption(ctx, Icons.cancel, 'Cancel', _ExitAction.cancel),
              ],
            ),
          ),
    );

    switch (choice) {
      case _ExitAction.exit:
        await _channel.invokeMethod('exitApp');
        break;
      case _ExitAction.minimize:
        SystemNavigator.pop();
        break;
      case _ExitAction.cancel:
      default:
        break;
    }
  }

  // outside your show() method, add:
  static Widget _buildOption(
    BuildContext ctx,
    IconData icon,
    String text,
    _ExitAction result,
  ) {
    return InkWell(
      onTap: () => Navigator.of(ctx).pop(result),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 16),
            Text(text, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
