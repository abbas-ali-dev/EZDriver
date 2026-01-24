import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/utils/my_strings.dart';
import 'package:ezdriver/data/controller/withdraw/withdraw_confirm_controller.dart';
import 'package:ezdriver/data/model/global/formdata/global_keyc_formData.dart';
import 'package:ezdriver/presentation/screens/auth/kyc/driver/widget/widget/choose_file_list_item.dart';

class WithdrawFileItem extends StatefulWidget {
  final int index;

  const WithdrawFileItem({super.key, required this.index});

  @override
  State<WithdrawFileItem> createState() => _WithdrawFileItemState();
}

class _WithdrawFileItemState extends State<WithdrawFileItem> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<WithdrawConfirmController>(builder: (controller) {
      GlobalFormModel? model = controller.formList[widget.index];
      return InkWell(
          onTap: () {
            controller.pickFile(widget.index);
          },
          child: ChooseFileItem(
              fileName: model.selectedValue ?? MyStrings.chooseFile));
    });
  }
}
