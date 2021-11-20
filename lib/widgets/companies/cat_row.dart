import 'dart:math';
import 'package:flutter/material.dart';
import 'package:masterme_chat/fonts/funtya.dart';
import 'package:masterme_chat/models/companies/catalogue.dart';
import 'package:masterme_chat/screens/companies/companies_listing_screen.dart';

class CatRow extends StatelessWidget {
  final Catalogue cat;
  CatRow(this.cat);

  Widget buildAvatar() {
    if (cat.name == null) {
      return Icon(Icons.home_work_outlined);
    }
    if (cat.icon != null && cat.icon != '') {
      return Icon(
        Funtya.getIcon(cat.icon),
        size: 32.0,
        color: cat.color,
      );
    }
    return CircleAvatar(
      backgroundColor: cat.color,
      child: Text('${cat.name}'[0]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: UniqueKey(),
      onTap: () {
        Navigator.pushNamed(context, CompaniesListingScreen.id, arguments: {
          'curCat': cat,
        });
      },
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: buildAvatar(),
              title: Text(
                cat.name,
              ),
              subtitle: Text(
                'Компаний: ${cat.count}',
              ),
              trailing: Icon(
                Icons.chevron_right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
