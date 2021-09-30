import 'dart:io';
import 'package:flutter/material.dart';

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
            backgroundColor: Colors.transparent,
            backgroundImage: image.startsWith('assets/')
                ? AssetImage(image)
                : FileImage(File(image)),
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
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
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
                  'Чат с пользователем',
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
