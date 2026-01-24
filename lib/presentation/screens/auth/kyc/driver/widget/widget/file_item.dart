import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/utils/my_strings.dart';
import 'package:ezdriver/data/controller/driver_kyc_controller/driver_kyc_controller.dart';
import 'package:ezdriver/data/model/global/formdata/global_keyc_formData.dart';
import 'package:ezdriver/presentation/screens/auth/kyc/driver/widget/widget/choose_file_list_item.dart';

class ConfirmWithdrawFileItem extends StatefulWidget {
  final int index;

  const ConfirmWithdrawFileItem({super.key, required this.index});

  @override
  State<ConfirmWithdrawFileItem> createState() =>
      _ConfirmWithdrawFileItemState();
}

class _ConfirmWithdrawFileItemState extends State<ConfirmWithdrawFileItem> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<DriverKycController>(builder: (controller) {
      GlobalFormModel? model = controller.formList[widget.index];
      return GestureDetector(
          onTap: () {
            controller.pickFile(widget.index);
          },
          child: ChooseFileItem(
              fileName: model.selectedValue ?? MyStrings.chooseFile));
    });
  }
}
