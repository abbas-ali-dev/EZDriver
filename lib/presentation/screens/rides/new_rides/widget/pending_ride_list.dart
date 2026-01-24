import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_strings.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/controller/dashboard/dashboard_controller.dart';
import 'package:ezdriver/presentation/screens/ride_history/accepted_ride_section/accepted_ride_card.dart';
import 'package:ezdriver/presentation/screens/rides/new_rides/widget/running_ride_warning_section.dart';

class PendingRideList extends StatelessWidget {
  final DashBoardController controller;
  const PendingRideList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        controller.hasRunningRides
            ? const RunningRideWarning()
            : const SizedBox.shrink(),
        if (controller.pendingRidesList.isNotEmpty) ...[
          Text(MyStrings.pendingRides.tr, style: boldLarge.copyWith()),
          const SizedBox(height: Dimensions.space10),
          Column(
            children: List.generate(
              controller.pendingRidesList.length,
              (index) {
                return AcceptedRideCard(
                  isActive: true,
                  ride: controller.pendingRidesList[index],
                  currency: controller.currencySym,
                  imageUrl: '',
                  cancelCallback: () {},
                );
              },
            ),
          )
        ],
      ],
    );
  }
}
