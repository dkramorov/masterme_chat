import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/models/companies/phones.dart';
import 'package:masterme_chat/screens/companies/company_wizard_screen.dart';
import 'package:masterme_chat/widgets/companies/company_logo.dart';
import 'package:masterme_chat/widgets/companies/phone_row.dart';
import 'package:masterme_chat/widgets/companies/star_rating_widget.dart';

class CompanyRow extends StatelessWidget {
  final Orgs company;
  CompanyRow(this.company);

  Column buildPhonesRows() {
    List<Widget> result = [];
    if (company != null && company.phonesArr != null) {
      for (Phones phone in company.phonesArr) {
        result.add(PhoneRow(phone));
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
      onTap: () {
        Navigator.pushNamed(context, CompanyWizardScreen.id, arguments: {
          'curCompany': company,
        });
      },
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: CompanyLogoWidget(company),
              title: Text(
                company.name,
              ),
              subtitle: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (company.resume != null && company.resume != '')
                      ? Text(company.resume)
                      : Container(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Телефонов: ${company.phones}',
                      ),
                      Text(
                        'Адресов: ${company.branches}',
                      ),
                    ],
                  ),
                  StarRatingWidget(company.rating == null ? 0 : company.rating),
                ],
              ),
              trailing: Icon(
                Icons.chevron_right,
              ),
            ),
            buildPhonesRows(),
          ],
        ),
      ),
    );
  }
}
