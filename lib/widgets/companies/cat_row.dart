import 'package:flutter/material.dart';
import 'package:masterme_chat/models/companies/catalogue.dart';
import 'package:masterme_chat/screens/companies/companies_listing_screen.dart';

class CatRow extends StatelessWidget {
  final Catalogue cat;
  CatRow(this.cat);

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
              leading: Icon(Icons.home_work_outlined),
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
