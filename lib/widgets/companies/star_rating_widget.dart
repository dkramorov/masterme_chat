import 'package:flutter/material.dart';
import 'package:masterme_chat/constants.dart';

class StarRatingWidget extends StatelessWidget {
  final int stars;

  StarRatingWidget(this.stars);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.star_border,
          color: stars > 0 ? kIconStarColor : kGrey,
        ),
        Icon(
          Icons.star_border,
          color: stars > 1 ? kIconStarColor : kGrey,
        ),
        Icon(
          Icons.star_border,
          color: stars > 2 ? kIconStarColor : kGrey,
        ),
        Icon(
          Icons.star_border,
          color: stars > 3 ? kIconStarColor : kGrey,
        ),
        Icon(
          Icons.star_border,
          color: stars > 4 ? kIconStarColor : kGrey,
        ),
      ],
    );
  }
}
