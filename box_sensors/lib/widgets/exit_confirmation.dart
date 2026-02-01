// lib/widgets/exit_confirmation.dart
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

enum _ExitAction { exit, minimizeKeepAlive, minimizeCloseBT,  cancel }  // minimizeTearDown,

class ExitConfirmation {
  static const MethodChannel _channel = MethodChannel('app.exit.channel');
  
  static Future<void> show(BuildContext context) async {
    final choice = await showDialog<_ExitAction>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            // ① Add a shape with both radius and a side border:
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.grey.shade400, width: 6),
            ),

            title: Text(
              'What now?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0), //(24, 20, 24, 0)
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Exit app, minimize it, or stay?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildOption(
                  ctx,
                  Icons.expand_more,  // expand_less,  // arrow_circle_down_outlined
                  'Minimize App (keep BT)',
                  _ExitAction.minimizeKeepAlive,
                ),
                _buildOption(
                  ctx,
                  Icons.expand_more ,
                  'Minimize App (close BT)',
                  _ExitAction.minimizeCloseBT,
                ),
                _buildOption(
                  ctx,
                  Icons.exit_to_app,
                  'Exit App',
                  _ExitAction.exit,
                ),
                _buildOption(ctx, Icons.cancel, 'Cancel', _ExitAction.cancel),
              ],
            ),
          ),
    );

    switch (choice) {
      case _ExitAction.minimizeKeepAlive:
        // just background → Bluetooth stays connected
        await _channel.invokeMethod('minimizeApp');
        break;
      case _ExitAction.minimizeCloseBT:
        await _channel.invokeMethod('minimizeAppNoBT');
        break;
      case _ExitAction.exit:
        await _channel.invokeMethod('exitApp');
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
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
