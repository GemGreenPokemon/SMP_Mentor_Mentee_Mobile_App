import 'package:flutter/material.dart';
import '../../utils/acknowledgment_constants.dart';

class SubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const SubmitButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AcknowledgmentSizes.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AcknowledgmentColors.primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AcknowledgmentColors.primaryDark.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AcknowledgmentSizes.borderRadiusSmall),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: AcknowledgmentSizes.spacingMedium),
                  Text(
                    'Submitting...',
                    style: AcknowledgmentTextStyles.button,
                  ),
                ],
              )
            : Text(
                AcknowledgmentStrings.submitButton,
                style: AcknowledgmentTextStyles.button,
              ),
      ),
    );
  }
}