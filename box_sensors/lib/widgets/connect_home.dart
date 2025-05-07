import 'package:box_sensors/widgets/exit_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/widgets/connect_home_widgets.dart';
import 'package:box_sensors/screens/matches_screen.dart';
import 'package:box_sensors/screens/add_match_screen.dart';
import 'package:box_sensors/widgets/settings.dart';
import 'package:box_sensors/widgets/header.dart';
import 'package:box_sensors/widgets/navbar.dart';
import 'package:box_sensors/widgets/footer.dart';
import 'package:box_sensors/widgets/status_bar_indicator.dart';

class ConnectHome extends ConsumerStatefulWidget {
  const ConnectHome({super.key});
  @override
  ConsumerState<ConnectHome> createState() => _ConnectHomeState();
}

class _ConnectHomeState extends ConsumerState<ConnectHome> {
  final List<String> deviceOptions = ['BlueBoxer', 'RedBoxer', 'BoxerServer'];
  int _currentIndex = 0;

  // Four Navigator keys: one for each real tab (Connect, Games, Add, Settings)
  final _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  // void _updateTabIndex(int index) {
  //   if (index == 4) {
  //     // Fifth destination is “Exit”
  //     ExitConfirmation.show(context);
  //     return;
  //   }
  //   setState(() => _currentIndex = index);
  // }

  void _updateTabIndex(int index) {
    if (index == 4) {
      // Exit
      ExitConfirmation.show(context);
      return;
    }

    setState(() => _currentIndex = index);

    if (index == 1) {
      final nav = _navigatorKeys[1].currentState;
      if (nav != null) {
        // 1) pop back to the root of that tab’s stack
        nav.popUntil((r) => r.isFirst);
        // 2) replace it with a fresh MatchesScreen form state)
        nav.pushReplacement(
          MaterialPageRoute(
            builder: (_) => MatchesScreen( onTabChange: _updateTabIndex),
          ),
        );
      }
    }
    
    // If they just tapped the "Add Game" tab
    if (index == 2) {
      final nav = _navigatorKeys[2].currentState;
      if (nav != null) {
        // 1) pop back to the root of that tab’s stack
        nav.popUntil((r) => r.isFirst);
        // 2) replace it with a fresh AddMatchScreen (clears all form state)
        nav.pushReplacement(
          MaterialPageRoute(
            builder: (_) => AddMatchScreen(onTabChange: _updateTabIndex),
          ),
        );
      }
    }

    if (index == 3){
      final nav = _navigatorKeys[3].currentState;
      if (nav != null) {
        // 1) pop back to the root of that tab’s stack
        nav.popUntil((r) => r.isFirst);
        // 2) replace it with a fresh AddMatchScreen (clears all form state)
        nav.pushReplacement(
          MaterialPageRoute(
            builder: (_) => SettingsScreen(onTabChange: _updateTabIndex),
          ),
        );
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerStateProvider);
    final bluetoothManager = ref.watch(bluetoothManagerProvider);

    return Scaffold(
      drawer: IgnorePointer(
        ignoring: timerState.isStartButtonDisabled,
        child: NavBar(onTabTapped: _updateTabIndex),
      ),
      drawerEnableOpenDragGesture: !timerState.isStartButtonDisabled,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: IgnorePointer(
          ignoring: timerState.isStartButtonDisabled,
          child: Header(title: 'Box Sensors'),
        ),
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Connect
          Navigator(
            key: _navigatorKeys[0],
            onGenerateRoute:
                (_) => MaterialPageRoute(
                  builder:
                      (_) => ConnectHomeWidgets(deviceOptions: deviceOptions),
                ),
          ),

          // Tab 1: Matches
          Navigator(
            key: _navigatorKeys[1],
            onGenerateRoute:
                (_) => MaterialPageRoute(
                  builder: (_) => MatchesScreen(onTabChange: _updateTabIndex),
                ),
          ),

          // Tab 2: Add Match
          // Navigator(
          //   key: _navigatorKeys[2],
          //   onGenerateRoute: (_) => MaterialPageRoute(
          //     builder: (_) => AddMatchScreen(onTabChange: _updateTabIndex),
          //   ),
          // ),

          // Tab 2: Add Match
          Navigator(
            key: _navigatorKeys[2],
            onGenerateRoute:
                (_) => MaterialPageRoute(
                  builder: (_) => AddMatchScreen(onTabChange: _updateTabIndex),
                ),
          ),

          // Tab 3: Settings
          Navigator(
            key: _navigatorKeys[3],
            onGenerateRoute:
                (_) => MaterialPageRoute(
                  builder: (_) => SettingsScreen(onTabChange: _updateTabIndex),
                ),
          ),
        ],
      ),

      bottomNavigationBar: IgnorePointer(
        ignoring: timerState.isStartButtonDisabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Footer(onTabTapped: _updateTabIndex, currentIndex: _currentIndex),
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
    );
  }
}

// import 'package:box_sensors/widgets/exit_confirmation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:box_sensors/widgets/connect_home_widgets.dart';
// import 'package:box_sensors/screens/matches_screen.dart';
// import 'package:box_sensors/screens/add_match_screen.dart';
// import 'package:box_sensors/widgets/settings.dart';
// import 'package:box_sensors/widgets/header.dart';
// import 'package:box_sensors/widgets/navbar.dart';
// import 'package:box_sensors/widgets/footer.dart';
// import 'package:box_sensors/widgets/status_bar_indicator.dart';

// class ConnectHome extends ConsumerStatefulWidget {
//   const ConnectHome({super.key});
//   @override
//   ConsumerState<ConnectHome> createState() => _ConnectHomeState();
// }

// class _ConnectHomeState extends ConsumerState<ConnectHome> {
//   final List<String> deviceOptions = ['BlueBoxer', 'RedBoxer', 'BoxerServer'];
//   int _currentIndex = 0;

//   // at the top of your _ConnectHomeState
//   final _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

//   /// This is now both your tab‐tap handler _and_ exit logic.
//   void _updateTabIndex(int index) {
//     if (index == 4) {
//       // If you ever have a fifth “Exit” tab at position 4
//       ExitConfirmation.show(context);
//       return;
//     }
//     setState(() {
//       _currentIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final timerState = ref.watch(timerStateProvider);
//     final bluetoothManager = ref.watch(bluetoothManagerProvider);

//     // Build your four screens once
//     final pages = <Widget>[
//       ConnectHomeWidgets(deviceOptions: deviceOptions),
//       MatchesScreen(onTabChange: _updateTabIndex),
//       AddMatchScreen(onTabChange: _updateTabIndex),
//       SettingsScreen(onTabChange: _updateTabIndex),
//     ];

//     return Scaffold(
//       // Drawer + Header unchanged, just pass the same handler:
//       drawer: IgnorePointer(
//         ignoring: timerState.isStartButtonDisabled,
//         child: NavBar(onTabTapped: _updateTabIndex),
//       ),
//       drawerEnableOpenDragGesture: !timerState.isStartButtonDisabled,
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(40),
//         child: IgnorePointer(
//           ignoring: timerState.isStartButtonDisabled,
//           child: Header(title: 'Box Sensors'),
//         ),
//       ),

//       // **Key part**: swap children with IndexedStack
//       // body: IndexedStack(
//       //   index: _currentIndex,
//       //   children: pages,
//       // ),
//       body: IndexedStack(
//         index: _currentIndex,
//         children: [
//           Navigator(
//             key: _navigatorKeys[0],
//             onGenerateRoute:
//                 (_) => MaterialPageRoute(
//                   builder:
//                       (_) => ConnectHomeWidgets(deviceOptions: deviceOptions),
//                 ),
//           ),
//           Navigator(
//             key: _navigatorKeys[1],
//             onGenerateRoute:
//                 (_) => MaterialPageRoute(
//                   builder: (_) => MatchesScreen(onTabChange: _updateTabIndex),
//                 ),
//           ),
//           Navigator(
//             key: _navigatorKeys[2],
//             onGenerateRoute:
//                 (_) => MaterialPageRoute(
//                   builder: (_) => AddMatchScreen(onTabChange: _updateTabIndex),
//                 ),
//           ),
//           Navigator(
//             key: _navigatorKeys[3],
//             onGenerateRoute:
//                 (_) => MaterialPageRoute(
//                   builder: (_) => SettingsScreen(onTabChange: _updateTabIndex),
//                 ),
//           ),
//         ],
//       ),

//       bottomNavigationBar: IgnorePointer(
//         ignoring: timerState.isStartButtonDisabled,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Pass the same handler here too:
//             Footer(onTabTapped: _updateTabIndex, currentIndex: _currentIndex),
//             StatusBarIndicator(
//               isConnectedDevice1: bluetoothManager.isDeviceConnected(
//                 'BlueBoxer',
//               ),
//               isConnectedDevice2: bluetoothManager.isDeviceConnected(
//                 'RedBoxer',
//               ),
//               isConnectedDevice3: bluetoothManager.isDeviceConnected(
//                 'BoxerServer',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // connect_home.dart
// import 'dart:async';
// import 'package:box_sensors/widgets/exit_confirmation.dart';
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
//     _disconnectionSub = bluetoothManager.disconnectionStream.listen((
//       String? deviceName,
//     ) {
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
//     const exitIndex = 4; // ← position of your “Exit” tab

//     // ① ExitConfirmation dialog
//     if (index == exitIndex) {
//       ExitConfirmation.show(context);
//       return;
//     }

//     // ② Otherwise, proceed with your existing logic:
//     // final int previousIndex = _currentIndex;

//     _safeSetState(() {
//       _currentIndex = index;
//     });

//     Widget nextScreen;
//     switch (index) {
//       case 0:
//         nextScreen = ConnectHomeWidgets(deviceOptions: deviceOptions);
//         break;
//       case 1:
//         nextScreen = MatchesScreen(onTabChange: _updateTabIndex);
//         break;
//       case 2:
//         nextScreen = AddMatchScreen(onTabChange: _updateTabIndex);
//         break;
//       case 3:
//         nextScreen = SettingsScreen(onTabChange: _updateTabIndex);
//         break;
//       default:
//         throw Exception("Invalid tab index: $index");
//     }

//     if (mounted && _navigatorKey.currentState != null) {
//       try {
//         // _navigatorKey.currentState!
//         //     .push<int>(MaterialPageRoute(builder: (context) => nextScreen))
//         //     .then((returnedIndex) {
//         //       _safeSetState(() {
//         //         _currentIndex = returnedIndex ?? previousIndex;
//         //       });
//         //     });
//         _navigatorKey.currentState!.push(
//           MaterialPageRoute(builder: (_) => nextScreen),
//         );
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
//         // await ExitConfirmation.show(context); // show your 3-button dialog
//       },
//       child: Scaffold(
//         // Wrap NavBar in IgnorePointer based on timer state.
//         drawer: IgnorePointer(
//           ignoring: timerState.isStartButtonDisabled,
//           child: NavBar(onTabTapped: onTabTapped),
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
//           onGenerateRoute:
//               (_) => MaterialPageRoute(
//                 builder:
//                     (context) =>
//                         ConnectHomeWidgets(deviceOptions: deviceOptions),
//               ),
//         ),
//         bottomNavigationBar: IgnorePointer(
//           ignoring: timerState.isStartButtonDisabled,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Footer(onTabTapped: onTabTapped, currentIndex: _currentIndex),
//               StatusBarIndicator(
//                 isConnectedDevice1: bluetoothManager.isDeviceConnected(
//                   'BlueBoxer',
//                 ),
//                 isConnectedDevice2: bluetoothManager.isDeviceConnected(
//                   'RedBoxer',
//                 ),
//                 isConnectedDevice3: bluetoothManager.isDeviceConnected(
//                   'BoxerServer',
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

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
