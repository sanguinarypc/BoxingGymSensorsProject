// lib/screens_widgets/connect_home_screen_widgets.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:box_sensors/services/providers.dart';
import '../widgets/device_scanner_header.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/custom_search_card.dart';
import '../widgets/device_list_view.dart';
import '../widgets/action_buttons_column.dart';

class ConnectHomeScreenWidgets extends ConsumerStatefulWidget {
  final List<String> deviceOptions;
  const ConnectHomeScreenWidgets({super.key, required this.deviceOptions});

  @override
  ConsumerState<ConnectHomeScreenWidgets> createState() =>
      _ConnectHomeScreenWidgetsState();
}

class _ConnectHomeScreenWidgetsState extends ConsumerState<ConnectHomeScreenWidgets> {
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
