import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import the package

class AboutDialogApp {
  // Make the method async to await package info
  static Future<void> show(BuildContext context) async {
    // Retrieve package information asynchronously
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    // Extract the version from package info
    final String appVersion = packageInfo.version;
    // You can also get the build number if needed:
    // final String buildNumber = packageInfo.buildNumber;

    // Check if the context is still mounted BEFORE accessing it after the await
    if (!context.mounted) return;

    // Retrieve theme and color scheme for styling AFTER the mounted check.
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = TextStyle(
      color: colorScheme.onSurface,
    ); // Reusable text style

    // --- Use showDialog with AlertDialog for custom sizing ---
    showDialog(
      context: context, // It's safe to use context here now
      // Use barrierDismissible: false if you want users to explicitly close via buttons
      // barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Get screen width for proportional sizing
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        // Aim for dialog width to be 60% of screen width, adjust as needed
        final dialogWidth = screenWidth * 0.60;

        return AlertDialog(
          // Use scrollable if content might overflow vertically
          scrollable: true,
          // Set padding to control space around the content
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 24.0),
          // Set background color if needed, defaults usually work well
          // backgroundColor: colorScheme.surface,
          // Define the shape (rounded corners)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Adjust radius
          ),
          // Wrap the content in a SizedBox to constrain its width
          content: SizedBox(
            width: dialogWidth, // Apply desired width
            child: Column(
              mainAxisSize: MainAxisSize.min, // Take minimum vertical space
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Dialog Content ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Application Icon
                    CircleAvatar(
                      radius: 30, // Slightly smaller icon for dialog layout
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: Icon(
                          Icons.sports_mma,
                          color: colorScheme.primary,
                          size: 50, // Adjust size
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // App Name and Version
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            packageInfo.appName, // Use appName from packageInfo
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Version: $appVersion',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Legalese Text
                    Text('Developed by Nick Dimitrakarakos', style: textStyle),
                  ],
                ),
                const SizedBox(height: 20), // Increased spacing
                // Description Text
                Text(
                  'The Box App is designed to help athletes and trainers manage boxing matches. '
                  'It allows you to connect devices, track performance, and create matches efficiently.',
                  style: textStyle,
                  textAlign: TextAlign.justify, // Apply justification here
                ),
                const SizedBox(height: 16), // Increased spacing
                // User Info Card
                Card(
                  elevation: 0, // Remove shadow if inside AlertDialog
                  // color: colorScheme.surfaceContainerHighest.withAlpha(102),
                  //color: theme.cardColor,
                  // Use less padding inside the card if AlertDialog has padding
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0), // Adjust padding
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25, // Adjusted size for card
                          backgroundColor: Colors.transparent,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/profilepicture.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 30,
                                  color: colorScheme.onSurface,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12), // Adjust spacing
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Nick Dimitrakarakos',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 15, // Adjust font size
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'std083899@ac.eap.gr',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 13, // Adjust font size
                                ),
                              ),
                              // const SizedBox(height: 4),
                              // Text.rich(
                              //   TextSpan(
                              //     text:
                              //         'Bachelor thesis,\n'
                              //         'Hellenic Open University.\n'
                              //         'Supervisor: Professor\n'
                              //         'Dr. ',
                              //     style: TextStyle(
                              //       color: colorScheme.onSurface,
                              //       fontSize: 13,
                              //     ),
                              //     children: [
                              //       TextSpan(
                              //         text: 'Ioannis Kouretas',
                              //         style: TextStyle(
                              //           fontWeight: FontWeight.bold,
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // --- Dialog Actions ---
          actions: <Widget>[
            // Add View Licenses Button
            TextButton(
              child: const Text('View licenses'), // Standard text
              onPressed: () {
                // Use the dialogContext to show the license page
                // It's generally recommended to use the main context
                // if possible, but dialogContext works here.
                showLicensePage(
                  context: dialogContext, // Or use the original 'context'
                  applicationName: packageInfo.appName,
                  applicationVersion: appVersion,
                  // You can optionally add an icon here too
                  // applicationIcon: Icon(Icons.sports_mma, color: colorScheme.primary),
                );
              },
            ),
            // Close Button
            TextButton(
              child: const Text('Close'), // Standard text
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
