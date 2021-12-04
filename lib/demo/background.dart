import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => new Scaffold(
    appBar: new AppBar(
      title: new Text('Grey Example'),
    ),
    body: new Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        new Card(
          child: new Container(
            child: new Text(
                'Hello world',
                style: Theme.of(context).textTheme.display4
            ),
            decoration: new BoxDecoration(
              color: const Color(0xff7c94b6),
              image: new DecorationImage(
                fit: BoxFit.cover,
                colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.dstATop),
                image: new NetworkImage(
                  'http://www.allwhitebackground.com/images/2/2582-190x190.jpg',
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}