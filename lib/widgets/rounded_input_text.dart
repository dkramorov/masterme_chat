import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';

class RoundedInputText extends StatelessWidget {
  final String hint;
  final Function onChanged;
  final Function validator;
  final String defaultValue;
  final Icon prefixIcon;
  final TextEditingController controller;
  final List<TextInputFormatter> formatters;
  final TextInputType keyboardType;
  final bool showCursor;
  final bool readOnly;
  final TextAlign textAlign;

  RoundedInputText({
    this.hint,
    this.onChanged,
    this.validator,
    this.defaultValue,
    this.prefixIcon,
    this.controller,
    this.formatters,
    this.keyboardType,
    this.showCursor,
    this.readOnly,
    this.textAlign,
  });

  TextInputType getKeyboardType() {
    if (keyboardType != null) {
      return keyboardType;
    }
    return this.hint.indexOf('Email') >= 0
        ? TextInputType.emailAddress
        : TextInputType.text;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      inputFormatters: this.formatters != null ? this.formatters : null,
      textAlign: this.textAlign == null ? TextAlign.center : this.textAlign,
      onSaved: this.onChanged,
      decoration: INPUT_DECORATION.copyWith(
        hintText: this.hint,
        prefixIcon: this.prefixIcon,
      ),
      // Для паролей надо в подсказке иметь "пароль"
      obscureText: this.hint.indexOf('пароль') >= 0 ? true : false,
      keyboardType: getKeyboardType(),
      validator: validator,
      initialValue: controller == null ? defaultValue : null,
      autovalidateMode: validator == null
          ? AutovalidateMode.disabled
          : AutovalidateMode.onUserInteraction,
      showCursor: showCursor != null ? showCursor : true,
      readOnly: readOnly != null ? readOnly : false,
    );
  }
}
