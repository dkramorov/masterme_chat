
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:masterme_chat/models/companies/orgs.dart';

class CompanyLogoWidget extends StatelessWidget {
  final Orgs company;
  static const logoWidth = 80.0;
  static const defaultIcon = Icon(
    Icons.image_outlined,
    size: 45.0,
  );

  CompanyLogoWidget(this.company);

  @override
  Widget build(BuildContext context) {
/*
    if (company == null || company.logo == '' || company.logo == null || company.logo.endsWith('svg')) {
      return Container(
        child: defaultIcon,
        width: logoWidth,
      );
    }
*/
    if (company == null || company.logo == '' || company.logo == null || company.logo.endsWith('svg')) {
      return CircleAvatar(
        backgroundColor: company.color,
        child: Text('${company.name}'[0]),
      );
    }

    return CachedNetworkImage(
      width: logoWidth,
      imageUrl: company.getLogoPath(),
      placeholder: (context, url) => defaultIcon,
      errorWidget: (context, url, error) => defaultIcon,
    );
  }
}
