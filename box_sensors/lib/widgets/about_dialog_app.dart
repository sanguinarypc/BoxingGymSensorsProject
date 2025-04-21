import 'package:flutter/material.dart';

class AboutDialogApp {
  static void show(BuildContext context) {
    // Retrieve theme and color scheme for styling.
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Display the About dialog using showAboutDialog.
    showAboutDialog(
      context: context,
      applicationName: 'Box Sensors',
      applicationVersion: '1.0.0',
      applicationIcon: CircleAvatar(
        radius: 42,
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: Icon(
            Icons.sports_mma,
            color: colorScheme.primary,
            size: 80,
          ),
        ),
      ),
      applicationLegalese: 'Developed by Nick Dimitrakarakos',
      children: [
        const SizedBox(height: 16),
        Text(
          'The Box App is designed to help athletes and trainers manage boxing matches. '
          'It allows you to connect devices, track performance, and create matches efficiently.',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // Although UserAccountsDrawerHeader is typically used in drawers,
        // here it's used for a user info display.
        UserAccountsDrawerHeader(
          accountName: Text(
            'Nick Dimitrakarakos',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          accountEmail: Text(
            'std083899@ac.eap.gr',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          currentAccountPicture: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: Image.asset(
                'assets/images/profilepicture.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(102),
          ),
        ),
      ],
    );
  }
}



















// import 'package:flutter/material.dart';

// class AboutDialogApp {
//   static void show(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     showAboutDialog(
//       context: context,
//       applicationName: 'Box Sensors',
//       applicationVersion: '1.0.0',
//       applicationIcon: CircleAvatar(
//         radius: 42,
//         backgroundColor: Colors.transparent,
//         child: ClipOval(
//           child: Icon(
//             Icons.sports_mma,
//             color: colorScheme.primary,
//             size: 80,
//           ),
//         ),
//       ),
//       applicationLegalese: 'Developed by Nick Dimitrakarakos',
//       children: [
//         const SizedBox(height: 16),
//         Text(
//           'The Box App is designed to help athletes and trainers manage boxing matches. '
//           'It allows you to connect devices, track performance, and create matches efficiently.',
//           style: TextStyle(
//             color: colorScheme.onSurface,
//           ),
//         ),
//         UserAccountsDrawerHeader(
//           accountName: Text(
//             'Nick Dimitrakarakos',
//             style: TextStyle(
//               color: colorScheme.onSurface,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           accountEmail: Text(
//             'std083899@ac.eap.gr',
//             style: TextStyle(
//               color: colorScheme.onSurface,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           currentAccountPicture: CircleAvatar(
//             radius: 40,
//             backgroundColor: Colors.transparent,
//             child: ClipOval(
//               child: Image.asset(
//                 'assets/images/profilepicture.jpg',
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           decoration: BoxDecoration(
//             color: colorScheme.surfaceContainerHighest.withAlpha(102),
//           ),
//         ),
//       ],
//     );
//   }
// }
