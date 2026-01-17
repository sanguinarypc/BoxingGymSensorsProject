import 'package:box_sensors/widgets/exit_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:box_sensors/services/riverpod_imports.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/screens_widgets/connect_home_screen_widgets.dart';
import 'package:box_sensors/screens/matches_screen.dart';
import 'package:box_sensors/screens/add_match_screen.dart';
import 'package:box_sensors/widgets/settings.dart';
import 'package:box_sensors/widgets/header.dart';
import 'package:box_sensors/widgets/navbar.dart';
import 'package:box_sensors/widgets/footer.dart';
import 'package:box_sensors/widgets/status_bar_indicator.dart';
import 'package:box_sensors/widgets/adaptive_safe_bottom.dart'; // ⬅️ ΝΕΟ import
import 'package:box_sensors/utils/device_config.dart';

class ConnectHomeScreen extends ConsumerStatefulWidget {
  const ConnectHomeScreen({super.key});
  @override
  ConsumerState<ConnectHomeScreen> createState() => _ConnectHomeState();
}

class _ConnectHomeState extends ConsumerState<ConnectHomeScreen> {
  final List<String> deviceOptions = DeviceConfig.allDevices;
  int _currentIndex = 0;

  // navigator keys
  final _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  // now use the public mixin interfaces, not private State types:
  final _addMatchKey = GlobalKey<AddMatchResettable>();
  final _matchesKey = GlobalKey<MatchesReloadable>();
  final _settingsKey = GlobalKey<SettingsReloadable>();

  void _updateTabIndex(int index) {
    if (index == 4) {
      ExitConfirmation.show(context);
      return;
    }

    // ❶ Pop any nested routes in that tab’s navigator back to its root:
    _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);

    // // if re‐select “Games” tab
    if (index == 1) {
      (_matchesKey.currentState)?.reloadMatches();
    }

    // if re‐select “Add Match” tab
    if (index == 2) {
      (_addMatchKey.currentState)?.resetForm();
    }

    // if re‐select “Settings” tab
    if (index == 3) {
      (_settingsKey.currentState)?.reloadSettings();
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext c) {
    final timerState = ref.watch(timerStateProvider);
    final bt = ref.watch(bluetoothManagerProvider);

    return Scaffold(
      drawer: IgnorePointer(
        ignoring: timerState.isStartButtonDisabled,
        child: NavBar(onTabTapped: _updateTabIndex),
      ),
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
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) =>
                  ConnectHomeScreenWidgets(deviceOptions: deviceOptions),
            ),
          ),

          // Tab 1: Matches
          Navigator(
            key: _navigatorKeys[1],
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) =>
                  MatchesScreen(key: _matchesKey, onTabChange: _updateTabIndex),
            ),
          ),

          // Tab 2: Add Match
          Navigator(
            key: _navigatorKeys[2],
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => AddMatchScreen(
                key: _addMatchKey,
                onTabChange: _updateTabIndex,
                useSafeArea: false,
              ),
            ),
          ),

          // Tab 3: Settings
          Navigator(
            key: _navigatorKeys[3],
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => SettingsScreen(
                key: _settingsKey,
                onTabChange: _updateTabIndex,
              ),
            ),
          ),
        ],
      ),

      // ⬇️ ΜΟΝΗ αλλαγή: τυλίγουμε τις 2 μπάρες με AdaptiveSafeBottom
      bottomNavigationBar: IgnorePointer(
        ignoring: timerState.isStartButtonDisabled,
        child: AdaptiveSafeBottom(
          minBottom: 0, // δεν θέλουμε διπλό bottom padding
          horizontal: 0, // τα widgets έχουν ήδη δικά τους paddings
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1) Κάτω tabs (Connect | Games | Add Game | Settings | Exit)
              Footer(
                onTabTapped: (idx) {
                  _updateTabIndex(idx);
                },
                currentIndex: _currentIndex,
              ),

              // 2) Η μπάρα “connected devices”
              StatusBarIndicator(
                isConnectedDevice1: bt.isDeviceConnected(
                  DeviceConfig.blueBoxer,
                ),
                isConnectedDevice2: bt.isDeviceConnected(DeviceConfig.redBoxer),
                isConnectedDevice3: bt.isDeviceConnected(
                  DeviceConfig.boxerServer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
