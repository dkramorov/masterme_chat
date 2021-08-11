import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';

class ChatHeaderWidget extends StatelessWidget {

  final String name;
  final String image;

  ChatHeaderWidget({this.name, this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 16),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_sharp,
              color: Colors.white,
            ),
          ),
          SizedBox(
            width: 2,
          ),
          CircleAvatar(
            backgroundColor: PRIMARY_BG_COLOR,
            backgroundImage: AssetImage(image),
            maxRadius: 20,
          ),
          SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  height: 6,
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.grey.shade200,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          /*
          Icon(
            Icons.settings,
            color: Colors.white,
          ),
           */
        ],
      ),
    );
  }
}
