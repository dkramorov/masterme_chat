import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/services/jabber_connection.dart';
import 'package:masterme_chat/widgets/chat/avatar_widget.dart';

class MyUser extends StatelessWidget {
  final String label;
  final bool isReady;
  final String imgPath;
  final bool isOnline;
  final double labelWidth;

  MyUser({
    this.label,
    this.isReady = true,
    this.imgPath = DEFAULT_AVATAR,
    this.isOnline,
    this.labelWidth = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(
        right: 10.0,
        left: 10.0,
        top: 6.0,
      ),
      child: Column(
        children: <Widget>[
          Avatar(
            imgPath: imgPath,
            isOnline: isOnline,
          ),
          SizedBox(
            height: 4.0,
          ),
          Container(
            width: labelWidth,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: kPrimaryDarkenColor,
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
