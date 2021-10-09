import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/models/companies/branches.dart';
import 'package:masterme_chat/models/companies/phones.dart';
import 'package:masterme_chat/widgets/companies/phone_row.dart';

class BranchRow extends StatelessWidget {
  final Branches branch;
  final List<Phones> phones;

  BranchRow(this.branch, {this.phones});

  Column buildPhonesRows() {
    List<Widget> result = [];
    if (phones != null) {
      for (Phones phone in phones) {
        if (phone.branch == branch.id) {
          result.add(PhoneRow(phone));
        }
      }
    }
    return Column(
      children: result,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: UniqueKey(),
      onTap: () {},
      child: Card(
        color: kOutSideDateColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.home_work_outlined),
              title: Text(
                branch.name,
              ),
              subtitle: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  branch.mapAddress != null
                      ? Text(branch.mapAddress.toString())
                      : Container(),
                ],
              ),
              /*
                  trailing: Icon(
                    Icons.chevron_right,
                  ),
                  */
            ),
            buildPhonesRows(),
          ],
        ),
      ),
    );
  }
}
