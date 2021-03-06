import 'package:flutter/material.dart';

class RoundedButtonWidget extends StatelessWidget {
  final Function onPressed;
  final Color color;
  final Text text;
  final double height;
  final double borderRadius;

  RoundedButtonWidget({
    this.text,
    this.color,
    this.onPressed,
    this.height = 42.0,
    this.borderRadius = 25.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5.0,
      color: this.color,
      borderRadius: BorderRadius.circular(this.borderRadius),
      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0),),
      child: MaterialButton(
        padding: EdgeInsets.all(0),
        height: this.height,
        onPressed: this.onPressed,
        minWidth: 120.0,
        child: this.text,
      ),
    );
  }
}
