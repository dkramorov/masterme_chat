import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';
import 'package:masterme_chat/helpers/phone_mask.dart';
import 'package:masterme_chat/models/companies/branches.dart';
import 'package:masterme_chat/models/companies/catalogue.dart';
import 'package:masterme_chat/models/companies/orgs.dart';
import 'package:masterme_chat/widgets/companies/branch_row.dart';
import 'package:masterme_chat/widgets/companies/catalogue_in_update.dart';
import 'package:masterme_chat/widgets/companies/company_logo.dart';
import 'package:masterme_chat/widgets/companies/star_rating_widget.dart';
import 'package:masterme_chat/widgets/rounded_button_widget.dart';

import 'call2company_screen.dart';

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
  static const companyCardBackgroudColor = Colors.green;
  static const addressIconColor = Color(0xFF961616);
  final int maxRubrics = 3;

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
        result.add(BranchRow(
          branch,
          phones: widget.company.phonesArr,
          company: widget.company,
        ));
      }
    }
    return Column(
      children: result,
    );
  }

  Widget buildFirstPhone() {
    if (widget.company == null ||
        widget.company.phonesArr == null ||
        widget.company.phonesArr.length < 1) {
      return Row();
    }
    final phone = widget.company.phonesArr[0];
    return Container(
      margin: EdgeInsets.all(10.0),
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300],
            offset: Offset(-2, 0),
            blurRadius: 7,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            phoneMaskHelper(phone.digits),
            style: TextStyle(
              fontSize: 22.0,
            ),
          ),
          RoundedButtonWidget(
            text: Text(
              'ПОЗВОНИТЬ',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            borderRadius: 8.0,
            color: companyCardBackgroudColor,
            onPressed: () {
              Navigator.pushNamed(context, Call2CompanyScreen.id, arguments: {
                'curPhone': phone,
                'curCompany': widget.company,
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildFirstAddress() {
    if (widget.company == null ||
        widget.company.branchesArr == null ||
        widget.company.branchesArr.length < 1) {
      return Column();
    }
    final branch = widget.company.branchesArr[0];
    return GestureDetector(
      onTap: () {
        widget.setStateCallback({'setPageview': 1});
      },
      child: Container(
        margin: EdgeInsets.all(10.0),
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300],
              offset: Offset(-2, 0),
              blurRadius: 7,
            ),
          ],
        ),
        child: Column(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.domain,
                    size: 40.0,
                    color: addressIconColor,
                  ),
                  title: branch.mapAddress != null
                      ? Text(branch.mapAddress.toString())
                      : Text(''),
                  subtitle: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SIZED_BOX_H12,
                      widget.company.branchesArr.length > 1
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ещё ${widget.company.branchesArr.length - 1}',
                                  style: TextStyle(fontSize: 17.0),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'показать все',
                                      style: TextStyle(fontSize: 17.0),
                                    ),
                                    Icon(Icons.arrow_forward_ios),
                                  ],
                                ),
                              ],
                            )
                          : Container(),
                    ],
                  ),
                  /*
                    trailing: Icon(
                      Icons.chevron_right,
                    ),
                    */
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Column buildRubrics() {
    List<Widget> result = [];
    int rcount = 0;
    for (Catalogue rubric in widget.company.rubricsArr) {
      rcount += 1;
      if (rcount > maxRubrics) {
        break;
      }
      result.add(SIZED_BOX_H06);
      result.add(Text(
        rubric.name,
        style: TextStyle(
          fontSize: 16.0,
          color: Colors.white,
        ),
      ));
    }
    result.add(SIZED_BOX_H12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: result,
    );
  }

  BoxDecoration buildCompanyHeader() {
    bool withBackgroundImage = widget.company != null && widget.company.getImagePath() != null;
    return BoxDecoration(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(32.0),
        bottomRight: Radius.circular(32.0),
      ),
      color: companyCardBackgroudColor,
      image: withBackgroundImage ? DecorationImage(
        image: CachedNetworkImageProvider(widget.company.getImagePath()),
        colorFilter: new ColorFilter.mode(
          Colors.black.withOpacity(0.2),
          BlendMode.dstATop,
        ),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ) : null,
    );
  }

  Widget buildCompanyCard() {
    return Column(
      children: [
        Container(
          decoration: buildCompanyHeader(),
          child: ListTile(
            minVerticalPadding: 20.0,
            leading: CompanyLogoWidget(widget.company),
            title: Text(
              widget.company.name,
              style: TextStyle(
                fontSize: 24.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildRubrics(),
                /*
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Телефонов: ${widget.company.phones}',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Адресов: ${widget.company.branches}',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                */
                SIZED_BOX_H12,
                buildRating(),
              ],
            ),
          ),
        ),
        SIZED_BOX_H06,
        buildFirstPhone(),
        buildFirstAddress(),
        //buildBranchesRows(),
        /*
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
        */
        /*
      ButtonBar(
        alignment: MainAxisAlignment.start,
        children: [
        ],
      ),
      */
      ],
    );
  }

  Widget buildResume() {
    if (widget.company.resume != null) {
      return Text(widget.company.resume);
    }
    return Container();
  }

  Widget buildCompanyView() {
    return SingleChildScrollView(
      child: buildCompanyCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.company != null ? buildCompanyView() : CatalogueInUpdate(),
    );
  }
}
