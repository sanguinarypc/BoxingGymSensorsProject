// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:android_intent_plus/android_intent.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:gap/gap.dart';

// class AndroidBatterySettingCard extends StatefulWidget {
//   const AndroidBatterySettingCard({super.key});

//   @override
//   State<AndroidBatterySettingCard> createState() =>
//       _AndroidBatterySettingCardState();
// }

// class _AndroidBatterySettingCardState
//     extends State<AndroidBatterySettingCard> {
//   final _deviceInfo = DeviceInfoPlugin();

//   Future<void> _openBatterySettings() async {
//     // 1) If not yet granted, *request* the exemption.
//     if (!await Permission.ignoreBatteryOptimizations.isGranted) {
//       final status = await Permission.ignoreBatteryOptimizations.request();
//       if (!status.isGranted) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context)
//             .showSnackBar(const SnackBar(content: Text('Permission denied')));
//         return;
//       }
//       if (mounted) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(const SnackBar(content: Text('Permission granted')));
//       }
//     }

//     // 2) We are now definitely exempt → open the *right* settings screen
//     final androidInfo = await _deviceInfo.androidInfo;
//     final man = androidInfo.manufacturer.toLowerCase();
//     AndroidIntent intent;

//     if (man.contains('huawei') || man.contains('honor')) {
//       // Huawei/Honor’s own “Protected apps” UI
//       intent = AndroidIntent(
//         action: 'android.intent.action.VIEW',
//         package: 'com.huawei.systemmanager',
//         // full component name: <package>/<fully-qualified-Activity>
//         componentName:
//             'com.huawei.systemmanager/com.huawei.systemmanager.optimize.process.ProtectActivity',
//       );
//     } else {
//       // Stock Android’s “Ignore battery optimization” list
//       intent = AndroidIntent(
//         action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
//         package: 'com.android.settings',
//       );
//     }

//     try {
//       await intent.launch();
//     } catch (_) {
//       // Fallback: open *your* App Info page
//       final pkg = await PackageInfo.fromPlatform();
//       await AndroidIntent(
//         action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
//         package: 'com.android.settings',
//         data: 'package:${pkg.packageName}',
//       ).launch();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Card(
//       color: theme.cardColor,
//       elevation: 6,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: theme.colorScheme.outline, width: 1),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(8),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(
//               'Android Battery Optimizations Setting',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: theme.colorScheme.primary,
//               ),
//             ),
//             const Gap(16),
//             ElevatedButton(
//               onPressed: _openBatterySettings,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: theme.colorScheme.primary,
//                 foregroundColor: theme.colorScheme.onPrimary,
//                 elevation: 6,
//                 shadowColor: theme.shadowColor,
//                 surfaceTintColor: theme.colorScheme.primaryContainer,
//                 fixedSize: const Size.fromHeight(40),
//               ),
//               child: const Text(
//                 'Battery Optimizations Setting',
//                 style: TextStyle(fontSize: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:android_intent_plus/android_intent.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:gap/gap.dart';

// class AndroidBatterySettingCard extends StatefulWidget {
//   const AndroidBatterySettingCard({super.key});

//   @override
//   State<AndroidBatterySettingCard> createState() =>
//       _AndroidBatterySettingCardState();
// }

// class _AndroidBatterySettingCardState
//     extends State<AndroidBatterySettingCard> {
//   final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

//   Future<void> _openBatterySettings() async {
//     // 1) Request the ignore-battery-optimizations permission if needed
//     if (!await Permission.ignoreBatteryOptimizations.isGranted) {
//       final status = await Permission.ignoreBatteryOptimizations.request();
//       if (!status.isGranted) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Permission denied')),
//         );
//         return;
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Permission granted')),
//           );
//         }
//       }
//     }

//     // 2) Now that it's definitely granted, open the proper settings screen
//     final androidInfo = await _deviceInfo.androidInfo;
//     final manufacturer = androidInfo.manufacturer.toLowerCase();

//     AndroidIntent intent;
//     if (manufacturer.contains('huawei') || manufacturer.contains('honor')) {
//       // Huawei/Honor proprietary UI
//       intent = AndroidIntent(
//         action: 'android.intent.action.VIEW',
//         componentName:
//             'com.huawei.systemmanager/.optimize.process.ProtectActivity',
//       );
//     } else {
//       // Stock “Ignore battery optimization” list
//       intent = AndroidIntent(
//         action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
//       );
//     }

//     try {
//       await intent.launch();
//     } catch (_) {
//       // Fallback → your app’s App Info page
//       final pkg = await PackageInfo.fromPlatform();
//       await AndroidIntent(
//         action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
//         data: 'package:${pkg.packageName}',
//       ).launch();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Card(
//       color: theme.cardColor,
//       elevation: 6,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: theme.colorScheme.outline, width: 1),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(8),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(
//               'Android Battery Optimizations Setting',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: theme.colorScheme.primary,
//               ),
//             ),
//             const Gap(16),
//             ElevatedButton(
//               onPressed: _openBatterySettings,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: theme.colorScheme.primary,
//                 foregroundColor: theme.colorScheme.onPrimary,
//                 elevation: 6,
//                 shadowColor: theme.shadowColor,
//                 surfaceTintColor: theme.colorScheme.primaryContainer,
//                 fixedSize: const Size.fromHeight(40),
//               ),
//               child: const Text(
//                 'Battery Optimizations Setting',
//                 style: TextStyle(fontSize: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gap/gap.dart';

class AndroidBatterySettingCard extends StatefulWidget {
  const AndroidBatterySettingCard({super.key});

  @override
  State<AndroidBatterySettingCard> createState() =>
      _AndroidBatterySettingCardState();
}

class _AndroidBatterySettingCardState extends State<AndroidBatterySettingCard> {
  /// Requests the “Ignore Battery Optimizations” permission once.
  Future<void> requestAllPermissionsOnce() async {
    await [Permission.ignoreBatteryOptimizations].request();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Android Battery Optimizations Setting',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'The dialogue appears only if the option "allow" (Recommended for better battery life) is selected.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Gap(8),
            ElevatedButton(
              onPressed: () async {
                await requestAllPermissionsOnce();

                // guard the *local* BuildContext after the async gap
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Requested battery-optimization exemption permission.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 6,
                shadowColor: theme.shadowColor,
                surfaceTintColor: theme.colorScheme.primaryContainer,
                fixedSize: const Size.fromHeight(40),
              ),
              child: const Text(
                'Battery Optimizations Setting',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:gap/gap.dart';

// class AndroidBatterySettingCard extends StatefulWidget {
//   const AndroidBatterySettingCard({super.key});

//   @override
//   State<AndroidBatterySettingCard> createState() =>
//       _AndroidBatterySettingCardState();
// }

// class _AndroidBatterySettingCardState
//     extends State<AndroidBatterySettingCard> {
//   /// Requests the “Ignore Battery Optimizations” permission once.
//   Future<void> requestPermission() async {
//     await [Permission.ignoreBatteryOptimizations].request();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Card(
//       color: theme.cardColor,
//       elevation: 6,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(
//           color: theme.colorScheme.outline,
//           width: 1,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(
//               'Android Battery Optimizations Setting',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: theme.colorScheme.primary,
//               ),
//             ),
//             const Gap(16),
//             ElevatedButton(
//               onPressed: () async {
//                 await requestPermission();

//                 // guard the *local* BuildContext after the async gap
//                 // if (!context.mounted) return;

//                 // ScaffoldMessenger.of(context).showSnackBar(
//                 //   const SnackBar(
//                 //     content: Text(
//                 //       'Requested battery-optimization exemption permission.',
//                 //     ),
//                 //   ),
//                 // );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: theme.colorScheme.primary,
//                 foregroundColor: theme.colorScheme.onPrimary,
//                 elevation: 6,
//                 shadowColor: theme.shadowColor,
//                 surfaceTintColor: theme.colorScheme.primaryContainer,
//                 fixedSize: const Size.fromHeight(40),
//               ),
//               child: const Text(
//                 'Battery Optimizations Setting',
//                 style: TextStyle(fontSize: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


