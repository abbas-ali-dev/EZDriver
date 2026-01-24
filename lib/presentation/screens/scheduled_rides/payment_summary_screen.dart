import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_controller.dart';
import 'package:ezdriver/data/model/scheduled_ride/scheduled_ride_model.dart';
import 'package:ezdriver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ezdriver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ezdriver/presentation/components/divider/custom_spacer.dart';
import 'package:ezdriver/presentation/components/text/header_text.dart';
import 'package:ezdriver/presentation/components/text-form-field/custom_text_field.dart';

class PaymentSummaryScreen extends StatefulWidget {
  final ScheduledRideModel ride;
  
  const PaymentSummaryScreen({
    super.key, 
    required this.ride,
  });

  @override
  State<PaymentSummaryScreen> createState() => _PaymentSummaryScreenState();
}

class _PaymentSummaryScreenState extends State<PaymentSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  PaymentSummary? paymentSummary;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure controller is instantiated
    Get.find<ScheduledRideController>();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    // Load payment summary
    _loadPaymentSummary();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentSummary() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final controller = Get.find<ScheduledRideController>();
      final summary = await controller.getPaymentSummary(widget.ride.id!);
      
      setState(() {
        paymentSummary = summary;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: 'Payment Summary',
        isShowBackBtn: true,
        bgColor: MyColor.primaryColor,
        elevation: 0,
      ),
      body: GetBuilder<ScheduledRideController>(
        builder: (controller) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: RefreshIndicator(
                onRefresh: _loadPaymentSummary,
                color: MyColor.primaryColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Dimensions.space15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ride Summary Card
                      _buildRideSummaryCard(controller),
                      spaceDown(Dimensions.space25),
                      
                      // Payment Summary Card
                      if (isLoading)
                        const Center(child: CustomLoader())
                      else if (paymentSummary != null)
                        _buildPaymentSummaryCard(controller)
                      else
                        _buildEmptyState(),
                      
                      spaceDown(Dimensions.space20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRideSummaryCard(ScheduledRideController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderText(
            text: 'Ride Summary',
            textStyle: boldLarge.copyWith(
              color: MyColor.getRideTitleColor(),
              fontWeight: FontWeight.w600,
              fontSize: Dimensions.fontOverLarge,
            ),
          ),
          spaceDown(Dimensions.space20),
          
          // Route Information
          _buildLocationRow(
            Icons.location_on,
            'Pickup',
            widget.ride.pickupLocation ?? 'Not specified',
            Colors.green,
          ),
          spaceDown(Dimensions.space15),
          _buildLocationRow(
            Icons.location_on_outlined,
            'Destination',
            widget.ride.destination ?? 'Not specified',
            Colors.red,
          ),
          
          spaceDown(Dimensions.space20),
          
          // Ride Details
          Container(
            padding: const EdgeInsets.all(Dimensions.space15),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Icons.schedule,
                    'Date & Time',
                    controller.formatDateTime(widget.ride.scheduledDateTime),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Icons.people,
                    'Passengers',
                    widget.ride.numberOfPassengers ?? '0',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(ScheduledRideController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderText(
            text: 'Payment Summary',
            textStyle: boldLarge.copyWith(
              color: MyColor.getRideTitleColor(),
              fontWeight: FontWeight.w600,
              fontSize: Dimensions.fontOverLarge,
            ),
          ),
          spaceDown(Dimensions.space20),
          
          // Passenger Statistics
          _buildStatisticsSection(),
          spaceDown(Dimensions.space25),
          
          // Earnings Summary
          _buildEarningsSection(),
          spaceDown(Dimensions.space25),
          
          // Passenger List
          _buildPassengerList(controller),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passenger Statistics',
            style: boldDefault.copyWith(
              color: Colors.blue[800],
              fontSize: Dimensions.fontLarge,
            ),
          ),
          spaceDown(Dimensions.space15),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  paymentSummary?.totalPassengers ?? '0',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Confirmed',
                  paymentSummary?.confirmedPassengers ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Completed',
                  paymentSummary?.completedPassengers ?? '0',
                  Icons.done_all,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Paid',
                  paymentSummary?.paidPassengers ?? '0',
                  Icons.payment,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSection() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Summary',
            style: boldDefault.copyWith(
              color: Colors.green[800],
              fontSize: Dimensions.fontLarge,
            ),
          ),
          spaceDown(Dimensions.space15),
          Row(
            children: [
              Expanded(
                child: _buildEarningItem(
                  'Total Earnings',
                  '\$${paymentSummary?.totalEarnings ?? '0'}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildEarningItem(
                  'Cash',
                  '\$${paymentSummary?.cashEarnings ?? '0'}',
                  Icons.money,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildEarningItem(
                  'Stripe',
                  '\$${paymentSummary?.stripeEarnings ?? '0'}',
                  Icons.credit_card,
                  Colors.blue,
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space15),
          Container(
            padding: const EdgeInsets.all(Dimensions.space12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.pending, color: Colors.red, size: 20),
                spaceSide(Dimensions.space8),
                Expanded(
                  child: Text(
                    'Pending Payments: \$${paymentSummary?.pendingPayments ?? '0'}',
                    style: regularDefault.copyWith(
                      color: Colors.red[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerList(ScheduledRideController controller) {
    if (paymentSummary?.passengers == null || paymentSummary!.passengers!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Dimensions.space20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 50, color: Colors.grey[400]),
              spaceDown(Dimensions.space10),
              Text(
                'No passengers found',
                style: regularDefault.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passenger Details',
          style: boldDefault.copyWith(
            color: MyColor.colorBlack,
            fontSize: Dimensions.fontLarge,
          ),
        ),
        spaceDown(Dimensions.space15),
        ...paymentSummary!.passengers!.map((passenger) => 
          _buildPassengerItem(controller, passenger),
        ),
      ],
    );
  }

  Widget _buildPassengerItem(ScheduledRideController controller, ScheduledRidePassenger passenger) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.space12),
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(
              passenger.user?.firstname?.substring(0, 1).toUpperCase() ?? 'P',
              style: regularDefault.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          spaceSide(Dimensions.space15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${passenger.user?.firstname ?? ''} ${passenger.user?.lastname ?? ''}',
                  style: regularDefault.copyWith(
                    color: MyColor.colorBlack,
                    fontWeight: FontWeight.w600,
                    fontSize: Dimensions.fontLarge,
                  ),
                ),
                spaceDown(Dimensions.space4),
                Text(
                  'Fare: \$${passenger.totalFare ?? '0'}',
                  style: regularDefault.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                spaceDown(Dimensions.space4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.space8,
                        vertical: Dimensions.space4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPaymentStatusColor(passenger.paymentStatus ?? '0').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                        border: Border.all(
                          color: _getPaymentStatusColor(passenger.paymentStatus ?? '0').withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getPaymentStatusColor(passenger.paymentStatus ?? '0'),
                              shape: BoxShape.circle,
                            ),
                          ),
                          spaceSide(Dimensions.space4),
                          Text(
                            _getPaymentStatusText(passenger.paymentStatus ?? '0'),
                            style: regularSmall.copyWith(
                              color: _getPaymentStatusColor(passenger.paymentStatus ?? '0'),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (passenger.paymentMethod != null) ...[
                      spaceSide(Dimensions.space8),
                      Text(
                        '(${passenger.paymentMethod})',
                        style: regularSmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Action buttons for unpaid passengers
          if (passenger.paymentStatus == '0')
            Column(
              children: [
                Container(
                  height: 35,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                  ),
                  child: TextButton.icon(
                    onPressed: controller.isReceivingPayment ? null : () {
                      _showReceivePaymentDialog(controller, passenger);
                    },
                    icon: controller.isReceivingPayment
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.payment, color: Colors.white, size: 16),
                    label: Text(
                      controller.isReceivingPayment ? 'Receiving...' : 'Receive',
                      style: regularSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showReceivePaymentDialog(ScheduledRideController controller, ScheduledRidePassenger passenger) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    
    // Set default amount
    amountController.text = passenger.totalFare ?? '0';
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.green, size: 24),
            spaceSide(Dimensions.space8),
            const Text('Receive Cash Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passenger: ${passenger.user?.firstname ?? ''} ${passenger.user?.lastname ?? ''}',
              style: regularDefault.copyWith(
                fontWeight: FontWeight.w600,
                color: MyColor.colorBlack,
              ),
            ),
            spaceDown(Dimensions.space15),
            CustomTextField(
              controller: amountController,
              labelText: 'Amount Received',
              hintText: 'Enter amount',
              onChanged: (value) {},
              prefixIcon: Icon(Icons.attach_money, color: MyColor.primaryColor),
            ),
            spaceDown(Dimensions.space15),
            CustomTextField(
              controller: noteController,
              labelText: 'Payment Note (Optional)',
              hintText: 'Add any notes...',
              maxLines: 2,
              onChanged: (value) {},
              prefixIcon: Icon(Icons.note, color: MyColor.primaryColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: regularDefault.copyWith(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: controller.isReceivingPayment ? null : () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) {
                Get.snackbar(
                  'Error',
                  'Please enter a valid amount',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              
              Get.back();
              controller.receiveCashPayment(
                widget.ride.id!,
                passenger.id!,
                amount,
                noteController.text.isNotEmpty ? noteController.text : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
            ),
            child: controller.isReceivingPayment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Receive Payment',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space30),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.payment_outlined, size: 80, color: Colors.grey[400]),
            spaceDown(Dimensions.space20),
            Text(
              'No Payment Data',
              style: boldLarge.copyWith(
                color: Colors.grey[600],
                fontSize: Dimensions.fontOverLarge,
              ),
            ),
            spaceDown(Dimensions.space10),
            Text(
              'Payment summary will appear here once passengers start making payments.',
              textAlign: TextAlign.center,
              style: regularDefault.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(Dimensions.space6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        spaceSide(Dimensions.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: regularSmall.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              spaceDown(Dimensions.space4),
              Text(
                address,
                style: regularDefault.copyWith(
                  color: MyColor.colorBlack,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        spaceDown(Dimensions.space8),
        Text(
          label,
          style: regularSmall.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        spaceDown(Dimensions.space4),
        Text(
          value,
          style: regularDefault.copyWith(
            color: MyColor.colorBlack,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        spaceDown(Dimensions.space8),
        Text(
          value,
          style: boldDefault.copyWith(
            color: color,
            fontSize: Dimensions.fontLarge,
          ),
        ),
        Text(
          label,
          style: regularSmall.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEarningItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        spaceDown(Dimensions.space8),
        Text(
          value,
          style: boldDefault.copyWith(
            color: color,
            fontSize: Dimensions.fontLarge,
          ),
        ),
        Text(
          label,
          style: regularSmall.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case '0':
        return Colors.orange;
      case '1':
        return Colors.green;
      case '2':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case '0':
        return 'Pending';
      case '1':
        return 'Paid';
      case '2':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }
}
