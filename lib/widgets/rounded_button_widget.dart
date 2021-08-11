import 'package:flutter/material.dart';

class RoundedButtonWidget extends StatelessWidget {
  final Function onPressed;
  final Color color;
  final Text text;

  RoundedButtonWidget({this.text, this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5.0,
      color: this.color,
      borderRadius: BorderRadius.circular(25.0),
      child: MaterialButton(
        onPressed: this.onPressed,
        minWidth: 120.0,
        height: 42.0,
        child: this.text,
      ),
    );
  }
}
