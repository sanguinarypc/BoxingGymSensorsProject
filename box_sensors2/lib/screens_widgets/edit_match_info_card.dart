import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MatchDetailInfoCard extends StatelessWidget {
  final Map<String, dynamic> matchData;
  const MatchDetailInfoCard({super.key, required this.matchData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // parse date or fall back
    String date = matchData['matchDate'] ?? 'Unknown Date';
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(matchData['matchDate']);
      date = DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {}

    return Card(
      color: theme.cardColor,
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelValue('Match Name:', matchData['matchName'] ?? 'Unknown', theme),
            const SizedBox(height: 16),
            _labelValue('Match Date:', date, theme),
            const SizedBox(height: 8),
            _labelValue('Rounds:', '${matchData['rounds']}', theme),
            const SizedBox(height: 8),
            _labelValue(
              'Finished at Round:', '${matchData['finishedAtRound']}', theme),
            const SizedBox(height: 8),
            _labelValue('Total Time:', matchData['totalTime'] ?? 'Unknown', theme),
            const SizedBox(height: 8),
            _labelValue('Round Time:',
              '${matchData['roundTime']} minute(s)', theme),
            const SizedBox(height: 8),
            _labelValue('Break Time:',
              '${matchData['breakTime']} second(s)', theme),
          ],
        ),
      ),
    );
  }

  Widget _labelValue(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          )),
        const SizedBox(height: 2),
        Text(value,
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          )),
      ],
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:box_sensors2/widgets/custom_text_form_field.dart';

// class EditMatchInfoCard extends StatelessWidget {
//   final TextEditingController nameCtrl;
//   final TextEditingController dateCtrl;
//   final TextEditingController roundsCtrl;
//   final VoidCallback onDateTap;
//   final String? Function(String?) nameValidator;
//   final String? Function(String?) dateValidator;
//   final String? Function(String?) roundsValidator;

//   const EditMatchInfoCard({
//     super.key,
//     required this.nameCtrl,
//     required this.dateCtrl,
//     required this.roundsCtrl,
//     required this.onDateTap,
//     required this.nameValidator,
//     required this.dateValidator,
//     required this.roundsValidator,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       elevation: 6,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: theme.colorScheme.outline),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Match Info',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: theme.colorScheme.primary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             CustomTextFormField(
//               controller: nameCtrl,
//               label: 'Match Name',
//               validator: nameValidator,
//             ),
//             const SizedBox(height: 16),
//             GestureDetector(
//               onTap: onDateTap,
//               child: AbsorbPointer(
//                 child: CustomTextFormField(
//                   controller: dateCtrl,
//                   label: 'Match Date',
//                   suffixIcon: Icons.calendar_today,
//                   validator: dateValidator,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             CustomTextFormField(
//               controller: roundsCtrl,
//               label: 'Rounds',
//               keyboardType: TextInputType.number,
//               validator: roundsValidator,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:box_sensors2/widgets/custom_text_form_field.dart';

// class EditMatchInfoCard extends StatelessWidget {
//   final TextEditingController matchNameCtrl;
//   final TextEditingController matchDateCtrl;
//   final TextEditingController roundsCtrl;
//   final VoidCallback onDateTap;

//   const EditMatchInfoCard({
//     super.key,
//     required this.matchNameCtrl,
//     required this.matchDateCtrl,
//     required this.roundsCtrl,
//     required this.onDateTap,
//   });

//   String? _notEmpty(String? v) => (v==null||v.isEmpty) ? 'Required' : null;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Card(
//       color: theme.cardColor,
//       elevation: 6,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: theme.colorScheme.outline),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Match Info',
//               style: theme.textTheme.titleMedium,
//             ),
//             const SizedBox(height: 12),
//             CustomTextFormField(
//               controller: matchNameCtrl,
//               label: 'Match Name',
//               validator: _notEmpty,
//             ),
//             const SizedBox(height: 12),
//             GestureDetector(
//               onTap: onDateTap,
//               child: AbsorbPointer(
//                 child: CustomTextFormField(
//                   controller: matchDateCtrl,
//                   label: 'Match Date',
//                   suffixIcon: Icons.calendar_today,
//                   validator: _notEmpty,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             CustomTextFormField(
//               controller: roundsCtrl,
//               label: 'Rounds',
//               keyboardType: TextInputType.number,
//               validator: _notEmpty,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
