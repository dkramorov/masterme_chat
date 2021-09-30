import 'dart:io';

import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/widgets/chat/online_indicator.dart';

class Avatar extends StatelessWidget {
  final double width;
  final double height;
  final String imgPath;
  final bool isOnline;

  const Avatar({
    Key key,
    this.width = 60.0,
    this.height = 60.0,
    this.imgPath,
    this.isOnline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var softShadows = [
      BoxShadow(
        color: kShadowColor,
        offset: Offset(2.0, 2.0),
        blurRadius: 2.0,
        spreadRadius: 1.0,
      ),
      BoxShadow(
        color: kBackgroundLightColor,
        offset: Offset(-2.0, -2.0),
        blurRadius: 2.0,
        spreadRadius: 1.0,
      ),
    ];
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: softShadows,
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: imgPath.startsWith('assets')
                    ? AssetImage(imgPath)
                    : FileImage(File(imgPath)),
              ),
            ),
          ),
          isOnline != null
              ? Positioned(
                  child: OnlineIndicator(
                    width: 0.26 * width,
                    height: 0.26 * height,
                    isOnline: isOnline,
                  ),
                  right: 2,
                  bottom: 2,
                )
              : SizedBox(),
        ],
      ),
    );
  }
}
