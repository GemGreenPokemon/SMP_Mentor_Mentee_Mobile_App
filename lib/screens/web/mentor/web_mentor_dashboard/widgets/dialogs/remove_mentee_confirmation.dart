import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../utils/dashboard_constants.dart';
import '../../utils/dashboard_helpers.dart';

class RemoveMenteeConfirmation extends StatelessWidget {
  final Mentee mentee;
  final VoidCallback onConfirm;

  const RemoveMenteeConfirmation({
    super.key,
    required this.mentee,
    required this.onConfirm,
  });

  static void show(BuildContext context, Mentee mentee, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => RemoveMenteeConfirmation(
        mentee: mentee,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(DashboardStrings.removeMentee),
      content: Text('Are you sure you want to remove ${mentee.name} from your mentee list?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(DashboardStrings.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
            DashboardHelpers.showWarningSnackBar(
              context,
              '${mentee.name} has been removed',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DashboardColors.statusRed,
            foregroundColor: Colors.white,
          ),
          child: const Text(DashboardStrings.remove),
        ),
      ],
    );
  }
}