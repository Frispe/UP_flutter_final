import 'package:flutter/material.dart';

class FormInput extends StatelessWidget {
  const FormInput({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.fieldError,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? fieldError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: (value) => validator(value) ?? fieldError,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorMaxLines: 3,
      ),
    );
  }
}
