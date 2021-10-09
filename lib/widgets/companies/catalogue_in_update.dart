import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';

class CatalogueInUpdate extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SIZED_BOX_H45,
          const ListTile(
            leading: Icon(Icons.disc_full),
            title: Text(
              CATALOGUE_IN_UPDATE,
              style: TextStyle(fontSize: 20),
            ),
            subtitle: Text(PLEASE_WAIT),
          ),
        ],
      ),
    );
  }
}
