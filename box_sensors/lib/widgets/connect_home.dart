// connect_home.dart
import 'dart:async';
import 'package:box_sensors/widgets/exit_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:box_sensors/widgets/connect_home_widgets.dart';
import 'package:box_sensors/screens/add_match_screen.dart';
import 'package:box_sensors/screens/matches_screen.dart';
import 'package:box_sensors/widgets/header.dart';
import 'package:box_sensors/widgets/navbar.dart';
import 'package:box_sensors/widgets/settings.dart';
import 'package:box_sensors/widgets/footer.dart';
import 'package:box_sensors/widgets/status_bar_indicator.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ConnectHome extends ConsumerStatefulWidget {
  const ConnectHome({super.key});

  @override
  ConsumerState<ConnectHome> createState() => _ConnectHomeState();
}

class _ConnectHomeState extends ConsumerState<ConnectHome> {
  final List<String> deviceOptions = ['BlueBoxer', 'RedBoxer', 'BoxerServer'];
  String? selectedDevice;

  final List<DataRow> rows = [];
  final Set<String> uniqueMessages = {};
  final StreamController<List<DataRow>> dataTableController =
      StreamController<List<DataRow>>.broadcast();

  // DatabaseHelper is used later in connected widgets.
  // final DatabaseHelper dbHelper = DatabaseHelper();

  int _currentIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  bool _disposed = false; // Flag to guard setState calls

  late final StreamSubscription<String?> _disconnectionSub;

  /// Helper to safely update state.
  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen for Bluetooth disconnections.
    final bluetoothManager = ref.read(bluetoothManagerProvider);
    _disconnectionSub = bluetoothManager.disconnectionStream.listen((
      String? deviceName,
    ) {
      if (deviceName != null && deviceName == selectedDevice) {
        _safeSetState(() {
          selectedDevice = null; // Reset DropdownButton to placeholder.
        });
      }
    });
  }

  @override
  void dispose() {
    _disconnectionSub.cancel();
    dataTableController.close();
    _disposed = true;
    super.dispose();
  }

  void _updateTabIndex(int index) {
    _safeSetState(() {
      _currentIndex = index;
    });
  }

  void onTabTapped(int index) {
    const exitIndex = 4; // ← position of your “Exit” tab

    // ① ExitConfirmation dialog
    if (index == exitIndex) {
      ExitConfirmation.show(context);
      return;
    }

    // ② Otherwise, proceed with your existing logic:
    final int previousIndex = _currentIndex;

    _safeSetState(() {
      _currentIndex = index;
    });

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = ConnectHomeWidgets(deviceOptions: deviceOptions);
        break;
      case 1:
        nextScreen = const MatchesScreen();
        break;
      case 2:
        nextScreen = const AddMatchScreen();
        break;
      case 3:
        nextScreen = SettingsScreen(onTabChange: _updateTabIndex);
        break;
      default:
        throw Exception("Invalid tab index: $index");
    }

    if (mounted && _navigatorKey.currentState != null) {
      try {
        _navigatorKey.currentState!
            .push<int>(MaterialPageRoute(builder: (context) => nextScreen))
            .then((returnedIndex) {
              _safeSetState(() {
                _currentIndex = returnedIndex ?? previousIndex;
              });
            });
      } catch (e, stackTrace) {
        debugPrint("Error pushing route: $e\n$stackTrace");
        Sentry.captureException(e, stackTrace: stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access TimerState and BluetoothManager via ref.watch.
    final timerState = ref.watch(timerStateProvider);
    final bluetoothManager = ref.watch(bluetoothManagerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
      },
      child: Scaffold(
        // Wrap NavBar in IgnorePointer based on timer state.
        drawer: IgnorePointer(
          ignoring: timerState.isStartButtonDisabled,
          child: NavBar(onTabTapped: onTabTapped),
        ),
        drawerEnableOpenDragGesture: !timerState.isStartButtonDisabled,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: IgnorePointer(
            ignoring: timerState.isStartButtonDisabled,
            child: Header(title: 'Box Sensors'),
          ),
        ),
        body: Navigator(
          key: _navigatorKey,
          onGenerateRoute:
              (_) => MaterialPageRoute(
                builder:
                    (context) =>
                        ConnectHomeWidgets(deviceOptions: deviceOptions),
              ),
        ),
        bottomNavigationBar: IgnorePointer(
          ignoring: timerState.isStartButtonDisabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Footer(onTabTapped: onTabTapped, currentIndex: _currentIndex),
              StatusBarIndicator(
                isConnectedDevice1: bluetoothManager.isDeviceConnected(
                  'BlueBoxer',
                ),
                isConnectedDevice2: bluetoothManager.isDeviceConnected(
                  'RedBoxer',
                ),
                isConnectedDevice3: bluetoothManager.isDeviceConnected(
                  'BoxerServer',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// // connect_home.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:box_sensors/widgets/connect_home_widgets.dart';
// import 'package:box_sensors/screens/add_match_screen.dart';
// import 'package:box_sensors/screens/matches_screen.dart';
// import 'package:box_sensors/widgets/header.dart';
// import 'package:box_sensors/widgets/navbar.dart';
// import 'package:box_sensors/widgets/settings.dart';
// import 'package:box_sensors/widgets/footer.dart';
// import 'package:box_sensors/widgets/status_bar_indicator.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

// class ConnectHome extends ConsumerStatefulWidget {
//   const ConnectHome({super.key});

//   @override
//   ConsumerState<ConnectHome> createState() => _ConnectHomeState();
// }

// class _ConnectHomeState extends ConsumerState<ConnectHome> {
//   final List<String> deviceOptions = ['BlueBoxer', 'RedBoxer', 'BoxerServer'];
//   String? selectedDevice;

//   final List<DataRow> rows = [];
//   final Set<String> uniqueMessages = {};
//   final StreamController<List<DataRow>> dataTableController =
//       StreamController<List<DataRow>>.broadcast();

//   // DatabaseHelper is used later in connected widgets.
//   // final DatabaseHelper dbHelper = DatabaseHelper();

//   int _currentIndex = 0;
//   final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

//   bool _disposed = false; // Flag to guard setState calls

//   late final StreamSubscription<String?> _disconnectionSub;

//   /// Helper to safely update state.
//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) {
//       setState(fn);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     // Listen for Bluetooth disconnections.
//     final bluetoothManager = ref.read(bluetoothManagerProvider);
//     _disconnectionSub = bluetoothManager.disconnectionStream.listen((String? deviceName) {
//       if (deviceName != null && deviceName == selectedDevice) {
//         _safeSetState(() {
//           selectedDevice = null; // Reset DropdownButton to placeholder.
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _disconnectionSub.cancel();
//     dataTableController.close();
//     _disposed = true;
//     super.dispose();
//   }

//   void _updateTabIndex(int index) {
//     _safeSetState(() {
//       _currentIndex = index;
//     });
//   }

//   void onTabTapped(int index) {
//     // Save the current tab index.
//     final int previousIndex = _currentIndex;

//     // Update _currentIndex for the visible tab.
//     _safeSetState(() {
//       _currentIndex = index;
//     });

//     Widget nextScreen;
//     switch (index) {
//       case 0:
//         nextScreen = ConnectHomeWidgets(
//           deviceOptions: deviceOptions,
//         );
//         break;
//       case 1:
//         nextScreen = const MatchesScreen();
//         break;
//       case 2:
//         nextScreen = const AddMatchScreen();
//         break;
//       case 3:
//         nextScreen = SettingsScreen(onTabChange: _updateTabIndex);
//         break;
//       default:
//         throw Exception("Invalid tab index: $index");
//     }

//     // Push the new route and, when it is popped, restore the previous index.
//     if (mounted && _navigatorKey.currentState != null) {
//       try {
//         _navigatorKey.currentState!
//             .push<int>(MaterialPageRoute(builder: (context) => nextScreen))
//             .then((returnedIndex) {
//           _safeSetState(() {
//             _currentIndex = returnedIndex ?? previousIndex;
//           });
//         });
//       } catch (e, stackTrace) {
//         debugPrint("Error pushing route: $e\n$stackTrace");
//         Sentry.captureException(e, stackTrace: stackTrace);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Access TimerState and BluetoothManager via ref.watch.
//     final timerState = ref.watch(timerStateProvider);
//     final bluetoothManager = ref.watch(bluetoothManagerProvider);

//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (bool didPop, dynamic result) {
//         if (didPop) return;
//       },
//       child: Scaffold(
//         // Wrap NavBar in IgnorePointer based on timer state.
//         drawer: IgnorePointer(
//           ignoring: timerState.isStartButtonDisabled,
//           child: NavBar(
//             dataTableStream: dataTableController.stream,
//             onTabTapped: onTabTapped,
//           ),
//         ),
//         drawerEnableOpenDragGesture: !timerState.isStartButtonDisabled,
//         appBar: PreferredSize(
//           preferredSize: const Size.fromHeight(40),
//           child: IgnorePointer(
//             ignoring: timerState.isStartButtonDisabled,
//             child: Header(title: 'Box Sensors'),
//           ),
//         ),
//         body: Navigator(
//           key: _navigatorKey,
//           onGenerateRoute: (_) => MaterialPageRoute(
//             builder: (context) => ConnectHomeWidgets(
//               deviceOptions: deviceOptions,
//             ),
//           ),
//         ),
//         bottomNavigationBar: IgnorePointer(
//           ignoring: timerState.isStartButtonDisabled,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Footer(onTabTapped: onTabTapped, currentIndex: _currentIndex),
//               StatusBarIndicator(
//                 isConnectedDevice1: bluetoothManager.isDeviceConnected('BlueBoxer'),
//                 isConnectedDevice2: bluetoothManager.isDeviceConnected('RedBoxer'),
//                 isConnectedDevice3: bluetoothManager.isDeviceConnected('BoxerServer'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
