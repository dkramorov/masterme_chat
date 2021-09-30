import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';

class OnlineIndicator extends StatelessWidget {
  final double width;
  final double height;
  final isOnline;

  const OnlineIndicator({
    Key key,
    this.isOnline,
    this.width = 14.0,
    this.height = 14.0,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: kShadowColor,
            blurRadius: 2.0,
            spreadRadius: 0,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isOnline ? kBrightlyGreen : kDisabledButtonColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
