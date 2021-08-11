import 'package:flutter/material.dart';

Future<String> openInfoDialog(
    BuildContext context,
    Function callback,
    String title,
    String text,
    String okText) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context, 'Cancel');
            if (callback != null) {
              callback();
            }
          },
          child: Text(okText),
        ),
      ],
    ),
  );
}