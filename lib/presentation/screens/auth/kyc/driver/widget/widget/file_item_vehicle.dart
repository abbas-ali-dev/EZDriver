import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/utils/my_strings.dart';
import 'package:ezdriver/data/controller/vehicle_verification/vehicle_verification_controller.dart';
import 'package:ezdriver/data/model/global/formdata/global_keyc_formData.dart';
import 'package:ezdriver/presentation/screens/auth/kyc/driver/widget/widget/choose_file_list_item.dart';

class FileItemForVehicle extends StatefulWidget {
  final int index;

  const FileItemForVehicle({super.key, required this.index});

  @override
  State<FileItemForVehicle> createState() => _FileItemForVehicleState();
}

class _FileItemForVehicleState extends State<FileItemForVehicle> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<VehicleVerificationController>(builder: (controller) {
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
