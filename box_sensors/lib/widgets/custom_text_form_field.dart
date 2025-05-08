import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? suffixIcon;  // <-- add this field

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,           // <-- make it optional
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: theme.colorScheme.surface,
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8, horizontal: 10,
        ),

        // only show an icon if one was passed in
        suffixIcon: suffixIcon != null 
            ? Icon(suffixIcon, color: theme.iconTheme.color) 
            : null,
      ),
    );
  }
}
