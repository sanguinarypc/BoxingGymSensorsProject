// lib/screens/match_info_card.dart
import 'package:flutter/material.dart';
import 'package:box_sensors2/widgets/custom_text_form_field.dart';

class MatchInfoCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController dateCtrl;
  final VoidCallback onDateTap;
  final TextEditingController roundsCtrl;
  final String? Function(String?)? nameValidator;
  final String? Function(String?)? dateValidator;
  final String? Function(String?)? roundsValidator;

  const MatchInfoCard({
    super.key,
    required this.nameCtrl,
    required this.dateCtrl,
    required this.onDateTap,
    required this.roundsCtrl,
    this.nameValidator,
    this.dateValidator,
    this.roundsValidator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Info', // style: theme.textTheme.titleMedium,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextFormField(
              controller: nameCtrl,
              label: 'Match Name',
              validator: nameValidator,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onDateTap,
              child: AbsorbPointer(
                child: CustomTextFormField(
                  controller: dateCtrl,
                  label: 'Match Date',
                  suffixIcon: Icons.calendar_today,
                  validator: dateValidator,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextFormField(
              controller: roundsCtrl,
              label: 'Rounds (1 to 15)',
              keyboardType: TextInputType.number,
              validator: roundsValidator,
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:box_sensors2/widgets/custom_text_form_field.dart';

// class MatchInfoCard extends StatelessWidget {
//   final TextEditingController nameCtrl;
//   final TextEditingController dateCtrl;
//   final VoidCallback onDateTap;

//   const MatchInfoCard({
//     super.key,
//     required this.nameCtrl,
//     required this.dateCtrl,
//     required this.onDateTap,
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
//             Text('Match Info', style: theme.textTheme.titleMedium),
//             const SizedBox(height: 8),
//             CustomTextFormField(
//               controller: nameCtrl,
//               label: 'Match Name',
//               validator: (v) => (v==null||v.isEmpty)? 'Enter a name' : null,
//             ),
//             const SizedBox(height: 16),
//             GestureDetector(
//               onTap: onDateTap,
//               child: AbsorbPointer(
//                 child: CustomTextFormField(
//                   controller: dateCtrl,
//                   label: 'Match Date',
//                   suffixIcon: Icons.calendar_today,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
