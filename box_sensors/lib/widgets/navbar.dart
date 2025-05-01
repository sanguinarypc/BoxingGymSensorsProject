import 'package:box_sensors/widgets/exit_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:box_sensors/widgets/about_dialog_animation.dart';
import 'package:box_sensors/widgets/about_dialog_app.dart';
import 'package:box_sensors/Themes/theme_selection.dart';
// import 'package:flutter/services.dart';

/// A simple widget that merges two icons into one.
class MergedIcon extends StatelessWidget {
  const MergedIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.sports_kabaddi,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          Positioned(
            top: 0,
            left: -10,
            child: Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

/// A navigation drawer widget that displays a menu with multiple options.
class NavBar extends StatelessWidget {
  final Function(int) onTabTapped;

  const NavBar({super.key, required this.onTabTapped});



  // A helper method to safely perform an action.
  void _safeAction(BuildContext context, VoidCallback action) {
    try {
      action();
    } catch (e) {
      debugPrint("Error performing navigation action: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      width: 260,
      backgroundColor:
          theme.brightness == Brightness.dark
              ? theme.colorScheme.surface
              : theme.colorScheme.inversePrimary,
      child: Column(
        children: [
          Container(
            height: 66,
            width: double.infinity,
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Row(
              children: [
                Icon(
                  Icons.sports_mma,
                  color: theme.colorScheme.onPrimary,
                  size: 40,
                ),
                const SizedBox(width: 10),
                Text(
                  'Box Sensors',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const ThemeSelection(),
          const Divider(),

          // ↓ wrap all the ListTiles below inside an Expanded→ListView
          Expanded(
            child: ListTileTheme(
              dense: true,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    //visualDensity: VisualDensity(vertical: -2),
                    // visualDensity: VisualDensity(horizontal: -1, vertical: -2),
                    leading: Icon(
                      Icons.bluetooth,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Connect',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        onTabTapped(0);
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.sports_kabaddi,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Games',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        onTabTapped(1);
                      });
                    },
                  ),
                  ListTile(
                    leading: const MergedIcon(),
                    title: Text(
                      'Add Game',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        onTabTapped(2);
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Settings',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        onTabTapped(3);
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info, color: theme.colorScheme.primary),
                    title: Text(
                      'About',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        AboutDialogApp.show(context);
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.animation, color: theme.colorScheme.primary),
                    title: Text(
                      'Animation',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        showAboutDialogAnimation(context);
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.exit_to_app,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Exit',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        ExitConfirmation.show(context);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience method to show the [AboutDialogAnimation].
void showAboutDialogAnimation(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const AboutDialogAnimation(),
  );
}




// import 'package:box_sensors/widgets/about_dialog_animation.dart';
// import 'package:flutter/material.dart';
// import 'package:box_sensors/widgets/about_dialog_app.dart';
// import 'package:box_sensors/Themes/theme_selection.dart';

// class MergedIcon extends StatelessWidget {
//   const MergedIcon({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return SizedBox(
//       width: 24,
//       height: 24,
//       child: Stack(
//         clipBehavior: Clip.none,
//         alignment: Alignment.center,
//         children: [
//           Icon(
//             Icons.sports_kabaddi,
//             size: 24,
//             color: theme.colorScheme.primary,
//           ),
//           Positioned(
//             top: 0,
//             left: -10,
//             child: Icon(
//               Icons.add,
//               size: 18,
//               color: theme.colorScheme.primary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class NavBar extends StatelessWidget {
//   final Stream<List<DataRow>> dataTableStream;
//   final Function(int) onTabTapped;

//   const NavBar({
//     super.key,
//     required this.dataTableStream,
//     required this.onTabTapped,
//   });

//   /// A helper method to safely perform an action.
//   /// Even though this is a stateless widget, wrapping actions in a try/catch
//   /// block can help catch unexpected errors during navigation.
//   void _safeAction(BuildContext context, VoidCallback action) {
//     try {
//       action();
//     } catch (e) {
//       debugPrint("Error performing navigation action: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Drawer(
//       width: 260,
//       backgroundColor: theme.brightness == Brightness.dark
//           ? theme.colorScheme.surface
//           : theme.colorScheme.inversePrimary,
//       child: Column(
//         children: [
//           Container(
//             height: 66,
//             width: double.infinity,
//             alignment: Alignment.bottomLeft,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.primary,
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.sports_mma,
//                   color: theme.colorScheme.onPrimary,
//                   size: 40,
//                 ),
//                 const SizedBox(width: 10),
//                 Text(
//                   'Box Sensors',
//                   style: TextStyle(
//                     color: theme.colorScheme.onPrimary,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const ThemeSelection(),
//           const Divider(),
//           ListTile(
//             leading: Icon(Icons.bluetooth, color: theme.colorScheme.primary),
//             title: Text(
//               'Connect',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 onTabTapped(0);
//               });
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.sports_kabaddi, color: theme.colorScheme.primary),
//             title: Text(
//               'Games',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 onTabTapped(1);
//               });
//             },
//           ),
//           ListTile(
//             leading: const MergedIcon(),
//             title: Text(
//               'Add Game',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 onTabTapped(2);
//               });
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.settings, color: theme.colorScheme.primary),
//             title: Text(
//               'Settings',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 onTabTapped(3);
//               });
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.info, color: theme.colorScheme.primary),
//             title: Text(
//               'About',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 AboutDialogApp.show(context);
//               });
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.info, color: theme.colorScheme.primary),
//             title: Text(
//               'Animation',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 AboutDialogAnimation.show(context);
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }












// import 'package:box_sensors/widgets/about_dialog_animation.dart'; 
// import 'package:flutter/material.dart';
// import 'package:box_sensors/widgets/about_dialog_app.dart';
// import 'package:box_sensors/Themes/theme_selection.dart';

// class NavBar extends StatelessWidget {
//   final Stream<List<DataRow>> dataTableStream;
//   final Function(int) onTabTapped; 

//   const NavBar({
//     super.key,
//     required this.dataTableStream,
//     required this.onTabTapped,
//   });

//   /// A helper method to safely perform an action.
//   /// Although this widget is stateless, wrapping actions in try/catch
//   /// can help catch unexpected errors during navigation.
//   void _safeAction(BuildContext context, VoidCallback action) {
//     try {
//       action();
//     } catch (e) {
//       debugPrint("Error performing navigation action: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Drawer(
//       width: 260,
//       backgroundColor: theme.brightness == Brightness.dark
//           ? theme.colorScheme.surface
//           : theme.colorScheme.inversePrimary,
//       child: Column(
//         children: [
//           Container(
//             height: 66,
//             width: double.infinity,
//             alignment: Alignment.bottomLeft,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.primary,
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.sports_mma,
//                   color: theme.colorScheme.onPrimary,
//                   size: 40,
//                 ),
//                 const SizedBox(width: 10),
//                 Text(
//                   'Box Sensors',
//                   style: TextStyle(
//                     color: theme.colorScheme.onPrimary,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const ThemeSelection(),
//           const Divider(),
//           ListTile(
//             leading: Icon(Icons.bluetooth, color: theme.colorScheme.primary),
//             title: Text(
//               'Connect',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 onTabTapped(0);
//               });
//             },
//           ),
//           ListTile(
//             leading: Icon(
//               Icons.sports_kabaddi,
//               color: theme.colorScheme.primary,
//             ),
//             title: Text(
//               'Games',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 onTabTapped(1);
//               });
//             },
//           ),
//           ListTile(
//             leading: Icon(
//               Icons.fitness_center,
//               color: theme.colorScheme.primary,
//             ),
//             title: Text(
//               'Add Game',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 onTabTapped(2);
//               });
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.settings, color: theme.colorScheme.primary),
//             title: Text(
//               'Settings',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 onTabTapped(3);
//               });
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.info, color: theme.colorScheme.primary),
//             title: Text(
//               'About',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 AboutDialogApp.show(context);
//               });
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.info, color: theme.colorScheme.primary),
//             title: Text(
//               'Animation',
//               style: TextStyle(color: theme.colorScheme.onSurface),
//             ),
//             onTap: () {
//               _safeAction(context, () {
//                 Navigator.pop(context);
//                 AboutDialogAnimation.show(context);
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }





















// // import 'package:box_sensors/widgets/about_dialog_animation.dart';
// // import 'package:flutter/material.dart';
// // import 'package:box_sensors/widgets/about_dialog_app.dart';
// // import 'package:box_sensors/Themes/theme_selection.dart';

// // class NavBar extends StatelessWidget {
// //   final Stream<List<DataRow>> dataTableStream;
// //   final Function(int) onTabTapped; 

// //   const NavBar({
// //     super.key,
// //     required this.dataTableStream,
// //     required this.onTabTapped,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     final theme = Theme.of(context);

// //     return Drawer(
// //       width: 260,
// //       backgroundColor: theme.brightness == Brightness.dark
// //           ? theme.colorScheme.surface
// //           : theme.colorScheme.inversePrimary,
// //       child: Column(
// //         children: [
// //           Container(
// //             height: 66,
// //             width: double.infinity,
// //             alignment: Alignment.bottomLeft,
// //             padding: const EdgeInsets.symmetric(horizontal: 16),
// //             decoration: BoxDecoration(
// //               color: theme.colorScheme.primary,
// //             ),
// //             child: Row(
// //               children: [
// //                 Icon(
// //                   Icons.sports_mma,
// //                   color: theme.colorScheme.onPrimary,
// //                   size: 40,
// //                 ),
// //                 const SizedBox(width: 10),
// //                 Text(
// //                   'Box Sensors',
// //                   style: TextStyle(
// //                     color: theme.colorScheme.onPrimary,
// //                     fontSize: 20,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           const ThemeSelection(),// Insert the new ThemeToggle widget here
// //           const Divider(),
// //           ListTile(
// //             leading: Icon(Icons.bluetooth, color: theme.colorScheme.primary),
// //             title: Text(
// //               'Connect',
// //               style: TextStyle(color: theme.colorScheme.onSurface),
// //             ),
// //             onTap: () {
// //               Navigator.pop(context);
// //               onTabTapped(0);
// //             },
// //           ),
// //           ListTile(
// //             leading: Icon(
// //               Icons.sports_kabaddi,
// //               color: theme.colorScheme.primary,
// //             ),
// //             title: Text(
// //               'Games',
// //               style: TextStyle(color: theme.colorScheme.onSurface),
// //             ),
// //             onTap: () {
// //               Navigator.pop(context);
// //               onTabTapped(1);
// //             },
// //           ),
// //           ListTile(
// //             leading: Icon(
// //               Icons.fitness_center,
// //               color: theme.colorScheme.primary,
// //             ),
// //             title: Text(
// //               'Add Game',
// //               style: TextStyle(color: theme.colorScheme.onSurface),
// //             ),
// //             onTap: () {
// //               Navigator.pop(context);
// //               onTabTapped(2);
// //             },
// //           ),
// //           ListTile(
// //             leading: Icon(Icons.settings, color: theme.colorScheme.primary),
// //             title: Text(
// //               'Settings',
// //               style: TextStyle(color: theme.colorScheme.onSurface),
// //             ),
// //             onTap: () {
// //               Navigator.pop(context);
// //               onTabTapped(3);
// //             },
// //           ),
// //           ListTile(
// //             leading: Icon(Icons.info, color: theme.colorScheme.primary),
// //             title: Text(
// //               'About',
// //               style: TextStyle(color: theme.colorScheme.onSurface),
// //             ),
// //             onTap: () {
// //               Navigator.pop(context);
// //               AboutDialogApp.show(context);
// //             },
// //           ),
// //           ListTile(
// //             leading: Icon(Icons.info, color: theme.colorScheme.primary),
// //             title: Text(
// //               'Animation',
// //               style: TextStyle(color: theme.colorScheme.onSurface),
// //             ),
// //             onTap: () {
// //               Navigator.pop(context);
// //               AboutDialogAnimation.show(context);
// //             },
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
