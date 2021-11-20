import 'package:flutter/material.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/models/companies/phones.dart';
import 'package:masterme_chat/screens/companies/call2company_screen.dart';

class PhoneRow extends StatelessWidget {

  final Phones phone;
  final Orgs company;

  PhoneRow(this.phone, {this.company});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: UniqueKey(),
      onTap: () {
        Navigator.pushNamed(context, Call2CompanyScreen.id, arguments: {
          'curPhone': phone,
          'curCompany': company,
        });
      },
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.phone_sharp),
              title: Text(
                phone.formattedPhone,
              ),
              subtitle: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Text('${phone.getWhataDisplay(phone.whata)}. ${phone.comment}'),
                  ),
                ],
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
