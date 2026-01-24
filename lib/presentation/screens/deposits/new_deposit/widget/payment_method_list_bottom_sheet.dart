import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/my_strings.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/core/utils/url_container.dart';
import 'package:ezdriver/data/controller/deposit/add_new_deposit_controller.dart';
import 'package:ezdriver/presentation/components/bottom-sheet/bottom_sheet_header_row.dart';
import 'package:ezdriver/presentation/components/text/header_text.dart';
import 'package:ezdriver/presentation/screens/deposits/new_deposit/widget/payment_method_card.dart';

class PaymentMethodListBottomSheet extends StatelessWidget {
  const PaymentMethodListBottomSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddNewDepositController>(builder: (controller) {
      return Container(
        height: context.height / 1.6,
        color: MyColor.colorWhite,
        child: Column(
          children: [
            const BottomSheetHeaderRow(),
            HeaderText(
                text: MyStrings.paymentMethod.tr,
                textStyle: mediumOverLarge.copyWith(
                    fontSize: Dimensions.fontOverLarge,
                    fontWeight: FontWeight.normal,
                    color: MyColor.colorBlack)),
            const SizedBox(height: Dimensions.space15),
            Flexible(
              child: ListView.builder(
                itemCount: controller.methodList.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return PaymentMethodCard(
                    paymentMethod: controller.methodList[index],
                    assetPath:
                        "${UrlContainer.domainUrl}/${controller.imagePath}",
                    selected: controller.methodList[index].id.toString() ==
                        controller.paymentMethod?.id.toString(),
                    press: () {
                      controller.setPaymentMethod(controller.methodList[index]);
                      Get.back();
                    },
                  );
                },
              ),
            )
          ],
        ),
      );
    });
  }
}
