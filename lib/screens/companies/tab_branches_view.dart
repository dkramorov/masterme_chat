import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/widgets/companies/branch_row.dart';
import 'package:masterme_chat/widgets/companies/catalogue_in_update.dart';

class TabBranchesView extends StatefulWidget {
  final Function setStateCallback;
  final PageController pageController;
  final Orgs company;

  TabBranchesView({this.pageController, this.setStateCallback, this.company});

  @override
  _TabBranchesViewState createState() => _TabBranchesViewState();
}

class _TabBranchesViewState extends State<TabBranchesView> {
  static const TAG = 'TabBranchesView';

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

  Widget buildBranches() {
    if (widget.company == null || widget.company.branchesArr == null) {
      return CatalogueInUpdate();
    }

    return ListView.builder(
      itemCount: widget.company.branchesArr.length,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(
        vertical: 15,
      ),
      itemBuilder: (context, index) {
        final item = widget.company.branchesArr[index];
        return BranchRow(
          item,
          phones: widget.company.phonesArr,
          company: widget.company,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PAD_SYM_H10,
      child: buildBranches(),
    );
  }
}
