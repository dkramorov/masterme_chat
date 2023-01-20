import 'package:flutter/material.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/models/companies/phones.dart';
import 'package:masterme_chat/screens/call.dart';

class PhoneRow extends StatelessWidget {
  final Phones phone;
  final Orgs company;

  PhoneRow(this.phone, {this.company});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: UniqueKey(),
      onTap: () {
        Navigator.pushNamed(context, CallScreen.id, arguments: {
          'curPhone': phone,
          'curCompany': company,
          'startCall': true,
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
                    child: Text(
                        '${phone.getWhataDisplay(phone.whata)}. ${phone.comment != null ? phone.comment : ""}'),
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
