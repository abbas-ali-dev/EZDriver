import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/presentation/components/column_widget/card_column.dart';

class RideCardDetails extends StatelessWidget {
  final String title;
  final String description;
  const RideCardDetails({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return CardColumn(
      header: title.tr,
      body: description.tr,
      headerTextStyle: boldMediumLarge.copyWith(color: MyColor.primaryColor),
      bodyTextStyle: regularMediumLarge.copyWith(color: MyColor.bodyText),
      alignmentCenter: true,
    );
  }
}
