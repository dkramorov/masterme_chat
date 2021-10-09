import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:masterme_chat/models/companies/orgs.dart';

class CompanyLogoWidget extends StatelessWidget {
  final Orgs company;

  CompanyLogoWidget(this.company);

  @override
  Widget build(BuildContext context) {
    const defaultIcon = Icon(
      Icons.image_outlined,
      size: 45.0,
    );
    const logoWidth = 80.0;

    if (company == null || company.logo == '' || company.logo == null) {
      return Container(
        child: defaultIcon,
        width: logoWidth,
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
