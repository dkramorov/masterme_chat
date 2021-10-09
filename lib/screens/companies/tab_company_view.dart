import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/models/companies/branches.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/widgets/companies/branch_row.dart';
import 'package:masterme_chat/widgets/companies/catalogue_in_update.dart';
import 'package:masterme_chat/widgets/companies/company_logo.dart';
import 'package:masterme_chat/widgets/companies/star_rating_widget.dart';

class TabCompanyView extends StatefulWidget {
  final Function setStateCallback;
  final PageController pageController;
  final Orgs company;

  TabCompanyView({this.pageController, this.setStateCallback, this.company});

  @override
  _TabCompanyViewState createState() => _TabCompanyViewState();
}

class _TabCompanyViewState extends State<TabCompanyView> {
  static const TAG = 'TabCompanyView';

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

  StarRatingWidget buildRating() {
    int stars = 0;
    if (widget.company != null && widget.company.rating != null) {
      stars = widget.company.rating;
    }
    return StarRatingWidget(stars);
  }

  Column buildBranchesRows() {
    List<Widget> result = [];
    if (widget.company != null && widget.company.branchesArr != null) {
      for (Branches branch in widget.company.branchesArr) {
        result.add(Divider());
        // Филиал с телефонами
        result.add(BranchRow(branch, phones: widget.company.phonesArr));
      }
    }
    return Column(
      children: result,
    );
  }

  Widget buildCompanyView() {
    return SingleChildScrollView(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              leading: CompanyLogoWidget(widget.company),
              title: Text(
                widget.company.name,
                style: TextStyle(fontSize: 24.0),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: widget.company.resume != null,
                    child: Text(
                      widget.company.resume != null ? widget.company.resume : '',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Телефонов: ${widget.company.phones}',
                      ),
                      Text(
                        'Адресов: ${widget.company.branches}',
                      ),
                    ],
                  ),
                  buildRating(),
                ],
              ),
            ),
            buildBranchesRows(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Пожалуйста, оцените компанию, если вы покупатель товаров/услуг этой компании',
                style: TextStyle(color: Colors.black),
              ),
            ),
            RatingBar.builder(
              initialRating: 3,
              minRating: 0,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                print(rating);
              },
            ),
            /*
            ButtonBar(
              alignment: MainAxisAlignment.start,
              children: [
              ],
            ),
            */
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: PAD_SYM_V20,
      padding: PAD_SYM_H10,
      child: widget.company != null ? buildCompanyView() : CatalogueInUpdate(),
    );
  }
}
