import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/widgets/companies/catalogue_in_update.dart';
import 'package:masterme_chat/widgets/companies/phone_row.dart';

class TabPhonesView extends StatefulWidget {
  final Function setStateCallback;
  final PageController pageController;
  final Orgs company;

  TabPhonesView({this.pageController, this.setStateCallback, this.company});

  @override
  _TabPhonesViewState createState() => _TabPhonesViewState();
}

class _TabPhonesViewState extends State<TabPhonesView> {
  static const TAG = 'TabPhonesView';

  @override
  void initState() {
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildPhones() {
    if (widget.company == null || widget.company.phonesArr == null) {
      return CatalogueInUpdate();
    }

    return ListView.builder(
      itemCount: widget.company.phonesArr.length,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(
        vertical: 15,
      ),
      itemBuilder: (context, index) {
        final item = widget.company.phonesArr[index];
        return PhoneRow(item);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PAD_SYM_H10,
      child: buildPhones(),
    );
  }
}
