import 'package:flutter/material.dart';

import '../constants.dart';

class RoundedInputText extends StatelessWidget {

  final String text;
  final Function onChanged;

  RoundedInputText({this.text, this.onChanged});

  InputBorder get_input_border() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(32.0),
      ),
      borderSide: BorderSide(
        color: Colors.blueAccent,
        width: 2.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      textAlign: TextAlign.center,
      onChanged: this.onChanged,
      decoration: INPUT_DECORATION.copyWith(
        hintText: this.text,
      ),
      // Для паролей надо в подсказке иметь "пароль"
      obscureText: this.text.indexOf('пароль') >= 0 ? true : false,
      keyboardType: this.text.indexOf('Email') >= 0 ? TextInputType.emailAddress : TextInputType.text,
    );
  }
}
