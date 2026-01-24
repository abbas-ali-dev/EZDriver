import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/my_strings.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/controller/ride/accepted_ride/accepted_ride_controller.dart';
import 'package:ezdriver/data/model/global/ride/ride_model.dart';
import 'package:ezdriver/presentation/components/bottom-sheet/bottom_sheet_header_row.dart';
import 'package:ezdriver/presentation/components/buttons/rounded_button.dart';
import 'package:ezdriver/presentation/components/text-form-field/custom_text_field.dart';

class CancelBottomSheet extends StatelessWidget {
  final RideModel ride;
  final void Function()? press;
  const CancelBottomSheet({super.key, required this.ride, this.press});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AcceptedRideController>(builder: (controller) {
      return Column(
        children: [
          const BottomSheetHeaderRow(),
          const SizedBox(height: Dimensions.space10),
          CustomTextField(
            labelTextStyle: boldDefault.copyWith(),
            animatedLabel: false,
            needOutlineBorder: true,
            fillColor: MyColor.colorGrey.withValues(alpha: 0.1),
            labelText: MyStrings.cancelReason.tr,
            hintText: MyStrings.rideCancelledTitle,
            maxLines: 6,
            controller: controller.cancelReasonController,
            onChanged: (c) {},
          ),
          const SizedBox(height: Dimensions.space20),
          RoundedButton(
              text: MyStrings.cancel.tr,
              color: MyColor.redCancelTextColor,
              isLoading: controller.isCancelLoading,
              press: () {
                if (press != null) {
                  press!();
                } else {
                  if (controller.cancelReasonController.text.isNotEmpty) {
                    controller.cancelRide(ride.id ?? '-1');
                  }
                }
              }),
          const SizedBox(height: Dimensions.space10),
        ],
      );
    });
  }
}
