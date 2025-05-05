// lib/widgets/connect_home_widgets.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:box_sensors/services/providers.dart';
import 'device_scanner_header.dart';
import 'filter_chips_row.dart';
import 'custom_search_card.dart';
import 'device_list_view.dart';
import 'action_buttons_column.dart';

class ConnectHomeWidgets extends ConsumerStatefulWidget {
  final List<String> deviceOptions;
  const ConnectHomeWidgets({super.key, required this.deviceOptions});

  @override
  ConsumerState<ConnectHomeWidgets> createState() =>
      _ConnectHomeWidgetsState();
}

class _ConnectHomeWidgetsState extends ConsumerState<ConnectHomeWidgets> {
  String filterKeyword = 'Boxer';
  final TextEditingController _filterController =
      TextEditingController(text: 'Boxer');
  Timer? _debounce;
  Timer? _periodicConnectedUpdateTimer;
  bool _disposed = false;
  bool _chipBusy = false;

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    final bluetoothManager = ref.read(bluetoothManagerProvider);
    _periodicConnectedUpdateTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      await bluetoothManager.updateRSSIForConnectedDevices();
    });
  }

  @override
  void dispose() {
    _periodicConnectedUpdateTimer?.cancel();
    _debounce?.cancel();
    _filterController.dispose();
    _disposed = true;
    super.dispose();
  }

  Future<void> _onFilterChip(String keyword) async {
    final bluetoothManager = ref.read(bluetoothManagerProvider);
    if (_chipBusy) return;
    _chipBusy = true;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (bluetoothManager.isScanning) {
      await FlutterBluePlus.stopScan();
    }
    if (filterKeyword != keyword) {
      _safeSetState(() {
        filterKeyword = keyword;
        _filterController.text = keyword == 'Boxer' ? 'Boxer' : '';
      });
    }
    if (!bluetoothManager.isScanning) {
      bluetoothManager.startScan(
        timeout: const Duration(seconds: 4),
        filterKeyword: keyword == 'Boxer' ? 'Boxer' : '',
      );
    }
    await Future.delayed(const Duration(milliseconds: 750));
    _chipBusy = false;
  }

  void _onSearchChanged(String value) {
    final bluetoothManager = ref.read(bluetoothManagerProvider);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _safeSetState(() {
          filterKeyword = value;
        });
      }
      if (!bluetoothManager.isScanning) {
        bluetoothManager.startScan(
          timeout: const Duration(seconds: 4),
          filterKeyword: value,
        );
      }
    });
  }

  Future<void> _onScanPressed() async {
    final bluetoothManager = ref.read(bluetoothManagerProvider);
    if (bluetoothManager.isScanning) {
      await FlutterBluePlus.stopScan();
    }
    final scanFilter = filterKeyword == 'NEARBY' ? '' : filterKeyword;
    if (!bluetoothManager.isScanning) {
      await bluetoothManager.startScan(
        timeout: const Duration(seconds: 4),
        filterKeyword: scanFilter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothManager = ref.watch(bluetoothManagerProvider);
    final mergedDevices = <String>[];

    for (final t in widget.deviceOptions) {
      if (bluetoothManager.availableDevices.contains(t) ||
          bluetoothManager.isDeviceConnected(t)) {
        mergedDevices.add(t);
      }
    }
    for (final d in bluetoothManager.availableDevices) {
      if (!mergedDevices.contains(d)) mergedDevices.add(d);
    }

    return Scaffold(
      body: Column(
        children: [
          DeviceScannerHeader(isScanning: bluetoothManager.isScanning),

          FilterChipsRow(
            filterKeyword: filterKeyword,
            chipBusy: _chipBusy,
            onSelectBoxer: () => _onFilterChip('Boxer'),
            onSelectNearby: () => _onFilterChip('NEARBY'),
          ),

          CustomSearchCard(
            controller: _filterController,
            onChanged: _onSearchChanged,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              mergedDevices.isEmpty
                  ? "No devices available. Tap 'Scan' to search again."
                  : "Found ${mergedDevices.length} device(s).",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          Expanded(
            child: Scrollbar(
              child: DeviceListView(
                devices: mergedDevices,
                rssiValues: bluetoothManager.rssiValues,
                calculateDistance: bluetoothManager.calculateDistance,
                getRSSIColor: bluetoothManager.getRSSIColor,
                onConnect: bluetoothManager.connectToDeviceByName,
                connectionNotifiers: bluetoothManager.deviceConnectionNotifiers,
                isDeviceConnected: bluetoothManager.isDeviceConnected,
                onDisconnect: bluetoothManager.handleDisconnectDevice,
              ),
            ),
          ),

          ActionButtonsColumn(
            isScanning: bluetoothManager.isScanning,
            onScan: _onScanPressed,
            connectedCountNotifier: bluetoothManager.connectedDevicesCount,
            maxCount: widget.deviceOptions.length,
            onConnectAll: bluetoothManager.connectAllBoxerDevices,
            onDisconnectAll: bluetoothManager.disconnectAllDevices,
          ),

          const Gap(0),
        ],
      ),
    );
  }
}















// // // lib/widgets/connect_home_widgets.dart
// import 'dart:async';
// // import 'dart:io';
// import 'package:box_sensors/widgets/animated_bluetooth_scan_indicator.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:gap/gap.dart';

// class ConnectHomeWidgets extends ConsumerStatefulWidget {
//   final List<String> deviceOptions;
//   const ConnectHomeWidgets({super.key, required this.deviceOptions});

//   @override
//   ConsumerState<ConnectHomeWidgets> createState() => _ConnectHomeWidgetsState();
// }

// class _ConnectHomeWidgetsState extends ConsumerState<ConnectHomeWidgets> {
//   // Default filter text is "Boxer"
//   String filterKeyword = 'Boxer';
//   final TextEditingController _filterController = TextEditingController(
//     text: 'Boxer',
//   );

//   Timer? _debounce;
//   Timer? _periodicConnectedUpdateTimer;
//   Timer? _periodicExtraScanTimer;
//   bool _disposed = false;

//   // To prevent rapid chip taps from triggering conflicting scans.
//   bool _chipBusy = false;

//   // A helper method to safely call setState.
//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) setState(fn);
//   }

//   @override
//   void initState() {
//     super.initState();
//     final bluetoothManager = ref.read(bluetoothManagerProvider);

//     // // For Android, ensure Bluetooth is enabled.
//     // if (Platform.isAndroid) FlutterBluePlus.turnOn();

//     // // Start an initial scan with the default filter.
//     // bluetoothManager.startScan(
//     //   timeout: const Duration(seconds: 4),
//     //   filterKeyword: filterKeyword,
//     // );

//     // Update RSSI for connected devices every 2 seconds.
//     _periodicConnectedUpdateTimer = Timer.periodic(const Duration(seconds: 2), (
//       timer,
//     ) async {
//       await bluetoothManager.updateRSSIForConnectedDevices();
//     });
//   }

//   @override
//   void dispose() {
//     _periodicConnectedUpdateTimer?.cancel();
//     _periodicExtraScanTimer?.cancel();
//     _debounce?.cancel();
//     _filterController.dispose();
//     _disposed = true;
//     super.dispose();
//   }

//   /// Updates or cancels the extra-scan timer based on the entered filter.
//   void _updateExtraScanTimer(String newFilter) {
//     if (newFilter.trim().isNotEmpty && _periodicExtraScanTimer != null) {
//       _periodicExtraScanTimer!.cancel();
//       _periodicExtraScanTimer = null;
//     }
//     if (newFilter.trim().isEmpty && _periodicExtraScanTimer == null) {
//       _periodicExtraScanTimer = Timer.periodic(const Duration(minutes: 5), (
//         timer,
//       ) async {
//         final bluetoothManager = ref.read(bluetoothManagerProvider);
//         await bluetoothManager.startScan(
//           timeout: const Duration(seconds: 2),
//           filterKeyword: '',
//         );
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final bluetoothManager = ref.watch(bluetoothManagerProvider);
//     final mergedDevices = <String>[];

//     // Merge target devices with discovered devices.
//     for (final target in widget.deviceOptions) {
//       if (bluetoothManager.availableDevices.contains(target) ||
//           bluetoothManager.isDeviceConnected(target)) {
//         mergedDevices.add(target);
//       }
//     }
//     for (final device in bluetoothManager.availableDevices) {
//       if (!mergedDevices.contains(device)) {
//         mergedDevices.add(device);
//       }
//     }

//     return Scaffold(
//       body: Column(
//         children: [
//           // Header row with title and animated scan indicator.
//           DisplayRow(
//             title: 'Device Scanner',
//             actions: [
//               // Place the scanning indicator with some right padding.
//               Padding(
//                 padding: const EdgeInsets.only(right: 8.0),
//                 child: AnimatedBluetoothScanIndicator(
//                   isScanning: bluetoothManager.isScanning,
//                   size: 20,
//                 ),
//               ),
//             ],
//           ),
//           // DEFAULT FILTER CHIPS ROW.
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4.0),
//             child: Row(
//               children: [
//                 // "Boxer Devices" Chip.
//                 SizedBox(
//                   width: 176,
//                   height: 40,
//                   child: ChoiceChip(
//                     label: FittedBox(
//                       fit: BoxFit.scaleDown,
//                       child: const Text(
//                         "Boxer Devices",
//                         style: TextStyle(fontSize: 14),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12.0,
//                       vertical: 8.0,
//                     ),
//                     visualDensity: VisualDensity.compact,
//                     materialTapTargetSize: MaterialTapTargetSize.padded,
//                     selected: filterKeyword == "Boxer",
//                     onSelected: (selected) async {
//                       if (_chipBusy) return;
//                       _chipBusy = true;
//                       if (_debounce?.isActive ?? false) _debounce!.cancel();
//                       if (bluetoothManager.isScanning) {
//                         await FlutterBluePlus.stopScan();
//                       }
//                       if (filterKeyword != "Boxer") {
//                         _safeSetState(() {
//                           filterKeyword = "Boxer";
//                           _filterController.text = "Boxer";
//                         });
//                       }

//                       if (!bluetoothManager.isScanning) {
//                         bluetoothManager.startScan(
//                           timeout: const Duration(seconds: 4),
//                           filterKeyword: "Boxer",
//                         );
//                       }

//                       // bluetoothManager.startScan(
//                       //   timeout: const Duration(seconds: 4),
//                       //   filterKeyword: "Boxer",
//                       // );

//                       await Future.delayed(const Duration(milliseconds: 750));
//                       _chipBusy = false;
//                     },
//                   ),
//                 ),
//                 // "Nearby Devices" Chip.
//                 SizedBox(
//                   width: 176,
//                   height: 40,
//                   child: ChoiceChip(
//                     label: FittedBox(
//                       fit: BoxFit.scaleDown,
//                       child: const Text(
//                         "Nearby Devices",
//                         style: TextStyle(fontSize: 14),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12.0,
//                       vertical: 8.0,
//                     ),
//                     visualDensity: VisualDensity.compact,
//                     materialTapTargetSize: MaterialTapTargetSize.padded,
//                     selected: filterKeyword == "NEARBY",
//                     onSelected: (selected) async {
//                       if (_chipBusy) return;
//                       _chipBusy = true;
//                       if (_debounce?.isActive ?? false) _debounce!.cancel();
//                       if (bluetoothManager.isScanning) {
//                         await FlutterBluePlus.stopScan();
//                       }
//                       if (filterKeyword != "NEARBY") {
//                         _safeSetState(() {
//                           filterKeyword = "NEARBY";
//                           _filterController.text = "";
//                         });
//                       }
//                       bluetoothManager.startScan(
//                         timeout: const Duration(seconds: 4),
//                         filterKeyword: "",
//                       );

//                       if (!bluetoothManager.isScanning) {
//                         bluetoothManager.startScan(
//                           timeout: const Duration(seconds: 4),
//                           filterKeyword: "",
//                         );
//                       }

//                       await Future.delayed(const Duration(milliseconds: 750));
//                       _chipBusy = false;
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Custom search TextField for additional filtering, wrapped in a Card.
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Card(
//               color: theme.cardColor,
//               elevation: 6,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12.0),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: SizedBox(
//                   height: 32,
//                   child: TextField(
//                     controller: _filterController,
//                     style: TextStyle(
//                       color: theme.colorScheme.primary,
//                       fontSize: 12,
//                     ),
//                     decoration: InputDecoration(
//                       isDense: true,
//                       isCollapsed: true,
//                       filled: true,
//                       fillColor: theme.cardColor,
//                       contentPadding: const EdgeInsets.symmetric(
//                         vertical: 4.0,
//                         horizontal: 0.0,
//                       ),
//                       hintText: 'Custom search',
//                       hintStyle: TextStyle(
//                         color: theme.colorScheme.primary.withValues(
//                           alpha: (0.6 * 255).toDouble(),
//                         ),
//                         fontSize: 12,
//                       ),
//                       border: const OutlineInputBorder(),
//                       prefixIcon: Icon(
//                         Icons.search,
//                         color: theme.colorScheme.primary,
//                         size: 16,
//                       ),
//                       prefixIconConstraints: const BoxConstraints(
//                         minWidth: 28,
//                         minHeight: 28,
//                       ),
//                     ),
//                     onChanged: (value) {
//                       if (_debounce?.isActive ?? false) _debounce!.cancel();
//                       _debounce = Timer(const Duration(milliseconds: 1500), () {
//                         if (mounted) {
//                           _safeSetState(() {
//                             filterKeyword = value;
//                             _updateExtraScanTimer(value);
//                           });
//                         }

//                         // bluetoothManager.startScan(
//                         //   timeout: const Duration(seconds: 4),
//                         //   filterKeyword: value,
//                         // );

//                         if (!bluetoothManager.isScanning) {
//                           bluetoothManager.startScan(
//                             timeout: const Duration(seconds: 4),
//                             filterKeyword: value,
//                           );
//                         }
//                       });
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Text(
//               "Tap a Device to connect",
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16.0,
//                 color: theme.colorScheme.primary,
//               ),
//             ),
//           ),
//           Center(
//             child: Text(
//               mergedDevices.isEmpty
//                   ? "No devices available. Tap 'Scan' to search again."
//                   : "Found ${mergedDevices.length} device(s).",
//               style: TextStyle(fontSize: 14, color: theme.colorScheme.primary),
//             ),
//           ),
//           Expanded(
//             child: CustomScrollView(
//               slivers: [
//                 SliverList(
//                   delegate: SliverChildBuilderDelegate((
//                     BuildContext context,
//                     int index,
//                   ) {
//                     final deviceName = mergedDevices[index];
//                     int rssi = bluetoothManager.rssiValues[deviceName] ?? -60;
//                     double distance = bluetoothManager.calculateDistance(rssi);
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                       child: Card(
//                         margin: const EdgeInsets.symmetric(vertical: 4.0),
//                         color: theme.cardColor,
//                         elevation: 6,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12.0),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Expanded(
//                                 child: InkWell(
//                                   onTap:
//                                       () => bluetoothManager
//                                           .connectToDeviceByName(deviceName),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Icon(
//                                             Icons.bluetooth,
//                                             color: theme.colorScheme.primary,
//                                           ),
//                                           const Gap(8.0),
//                                           Expanded(
//                                             child: Text(
//                                               deviceName,
//                                               style: theme.textTheme.bodyMedium
//                                                   ?.copyWith(
//                                                     color:
//                                                         deviceName == 'RedBoxer'
//                                                             ? Colors.red
//                                                             : deviceName ==
//                                                                 'BlueBoxer'
//                                                             ? Colors.blue
//                                                             : deviceName ==
//                                                                 'BoxerServer'
//                                                             ? Colors.green
//                                                             : theme
//                                                                 .textTheme
//                                                                 .bodyMedium
//                                                                 ?.color,
//                                                   ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const Gap(8.0),
//                                       Row(
//                                         children: [
//                                           CircleAvatar(
//                                             backgroundColor: bluetoothManager
//                                                 .getRSSIColor(rssi),
//                                             radius: 16,
//                                             child: Text(
//                                               '$rssi',
//                                               style: const TextStyle(
//                                                 fontSize: 10,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ),
//                                           const Gap(2.0),
//                                           Text.rich(
//                                             TextSpan(
//                                               text: 'dBm\nDistance:',
//                                               style: DefaultTextStyle.of(
//                                                 context,
//                                               ).style.copyWith(fontSize: 10),
//                                               children: [
//                                                 TextSpan(
//                                                   text:
//                                                       ' ${distance.toStringAsFixed(2)} meter(s)',
//                                                   style: DefaultTextStyle.of(
//                                                     context,
//                                                   ).style.copyWith(
//                                                     fontSize: 10,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   if (bluetoothManager.deviceConnectionNotifiers
//                                       .containsKey(deviceName))
//                                     ValueListenableBuilder<bool>(
//                                       valueListenable:
//                                           bluetoothManager
//                                               .deviceConnectionNotifiers[deviceName]!,
//                                       builder: (context, isConnected, child) {
//                                         bool confirmedConnected =
//                                             bluetoothManager.isDeviceConnected(
//                                               deviceName,
//                                             );
//                                         if (!isConnected ||
//                                             !confirmedConnected) {
//                                           return const SizedBox.shrink();
//                                         }
//                                         return ElevatedButton(
//                                           onPressed:
//                                               () => bluetoothManager
//                                                   .handleDisconnectDevice(
//                                                     deviceName,
//                                                   ),
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor:
//                                                 theme.colorScheme.primary,
//                                             foregroundColor:
//                                                 theme.colorScheme.onPrimary,
//                                             elevation: 6,
//                                             shadowColor: theme.shadowColor,
//                                             surfaceTintColor:
//                                                 theme
//                                                     .colorScheme
//                                                     .primaryContainer,
//                                             fixedSize: const Size(110, 48),
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 0,
//                                             ),
//                                           ),
//                                           child: Row(
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               Icon(
//                                                 Icons.bluetooth,
//                                                 color:
//                                                     theme.colorScheme.onPrimary,
//                                                 size: 20,
//                                               ),
//                                               const Gap(1),
//                                               Text(
//                                                 'Disconnect',
//                                                 maxLines: 1,
//                                                 overflow: TextOverflow.visible,
//                                                 style: TextStyle(
//                                                   color:
//                                                       theme
//                                                           .colorScheme
//                                                           .onPrimary,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         );
//                                       },
//                                     )
//                                   else
//                                     const SizedBox.shrink(),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   }, childCount: mergedDevices.length),
//                 ),
//               ],
//             ),
//           ),

//           // SCAN FOR DEVICES BUTTON.
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: () async {
//                   if (bluetoothManager.isScanning) {
//                     await FlutterBluePlus.stopScan();
//                   }
//                   final scanFilter =
//                       filterKeyword == "NEARBY" ? "" : filterKeyword;
//                   // await bluetoothManager.startScan(
//                   //   timeout: const Duration(seconds: 4),
//                   //   filterKeyword: scanFilter,
//                   // );

//                   if (!bluetoothManager.isScanning) {
//                     await bluetoothManager.startScan(
//                       timeout: const Duration(seconds: 4),
//                       filterKeyword: scanFilter,
//                     );
//                   }
//                 },
//                 icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
//                 label: const Text('Scan for Devices'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: theme.colorScheme.primary,
//                   foregroundColor: theme.colorScheme.onPrimary,
//                   elevation: 6,
//                   shadowColor: theme.shadowColor,
//                   surfaceTintColor: theme.colorScheme.primaryContainer,
//                   fixedSize: const Size(300, 40),
//                 ),
//               ),
//             ],
//           ),
//           const Gap(0.0),
//           // CONNECT and DISCONNECT BUTTONS.
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ValueListenableBuilder<int>(
//                 valueListenable: bluetoothManager.connectedDevicesCount,
//                 builder: (context, count, child) {
//                   return ElevatedButton.icon(
//                     onPressed:
//                         count < widget.deviceOptions.length
//                             ? () => bluetoothManager.connectAllBoxerDevices()
//                             : null,
//                     icon: SizedBox(
//                       width: 40,
//                       height: 40,
//                       child: Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           Icon(
//                             Icons.smartphone,
//                             size: 28,
//                             color: theme.colorScheme.onPrimary,
//                           ),
//                           Positioned(
//                             top: 2,
//                             right: -2,
//                             child: Icon(
//                               Icons.bluetooth_connected,
//                               size: 16,
//                               color: theme.colorScheme.onPrimary,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     label: const Text('Connect all Boxer Devices'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: theme.colorScheme.primary,
//                       foregroundColor: theme.colorScheme.onPrimary,
//                       elevation: 6,
//                       shadowColor: theme.shadowColor,
//                       surfaceTintColor: theme.colorScheme.primaryContainer,
//                       fixedSize: const Size(300, 40),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//           const Gap(0.0),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ValueListenableBuilder<int>(
//                 valueListenable: bluetoothManager.connectedDevicesCount,
//                 builder: (context, count, child) {
//                   return ElevatedButton.icon(
//                     onPressed:
//                         count > 0
//                             ? () => bluetoothManager.disconnectAllDevices()
//                             : null,
//                     icon: Icon(
//                       Icons.bluetooth_disabled,
//                       color: theme.colorScheme.onPrimary,
//                     ),
//                     label: const Text('Disconnect All Devices'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: theme.colorScheme.primary,
//                       foregroundColor: theme.colorScheme.onPrimary,
//                       elevation: 6,
//                       shadowColor: theme.shadowColor,
//                       surfaceTintColor: theme.colorScheme.primaryContainer,
//                       fixedSize: const Size(300, 40),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//           const Gap(0.0),
//         ],
//       ),
//     );
//   }
// }
